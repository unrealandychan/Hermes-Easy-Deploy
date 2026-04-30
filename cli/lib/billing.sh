#!/usr/bin/env bash
# billing.sh — Cloud billing / cost query helpers for Hermes Agent Cloud
#
# Usage:  hermes-agent-cloud billing [--cloud aws|azure|gcp]
#
# AWS    — requires enable_billing=true in the permission profile, or
#          sufficient IAM perms (ce:Get*, budgets:ViewBudget)
# Azure  — requires az CLI + Billing Reader / Cost Management Reader role
# GCP    — requires gcloud + billing.viewer IAM role on the project

# ─── Entry point ─────────────────────────────────────────────────────────────
billing_cmd() {
  hermes_banner
  config_load

  [[ -z "$CLOUD" ]] && CLOUD="$(config_get "cloud" 2>/dev/null || echo "")"

  if [[ -z "$CLOUD" ]]; then
    local cloud_choice
    cloud_choice=$(choose_one "Select cloud provider to query billing" \
      "AWS    — Amazon Web Services" \
      "Azure  — Microsoft Azure" \
      "GCP    — Google Cloud Platform")
    CLOUD="$(echo "$cloud_choice" | awk '{print $1}' | tr '[:upper:]' '[:lower:]')"
  fi

  case "$CLOUD" in
    aws)   billing_aws   ;;
    azure) billing_azure ;;
    gcp)   billing_gcp   ;;
    *)     error "Unknown cloud: ${CLOUD}"; exit 1 ;;
  esac
}

# ─── AWS billing ─────────────────────────────────────────────────────────────
billing_aws() {
  local region
  region=$(config_get "region" 2>/dev/null || echo "us-east-1")

  gum style --foreground 212 --bold "  AWS Cost Summary"
  echo ""

  local period_choice
  period_choice=$(choose_one "Select billing period" \
    "This month      (month-to-date)" \
    "Last 30 days" \
    "Last 3 months   (quarterly trend)")

  local start_date end_date
  end_date=$(date -u +%Y-%m-%d)

  case "$period_choice" in
    "This month"*)
      start_date=$(date -u +%Y-%m-01)
      ;;
    "Last 30 days"*)
      start_date=$(date -u -d "30 days ago" +%Y-%m-%d 2>/dev/null \
                   || date -u -v-30d +%Y-%m-%d)
      ;;
    "Last 3 months"*)
      start_date=$(date -u -d "90 days ago" +%Y-%m-%d 2>/dev/null \
                   || date -u -v-90d +%Y-%m-%d)
      ;;
  esac

  echo ""
  gum style --foreground 245 "  Period: ${start_date} → ${end_date}"
  echo ""

  # Total cost
  local total_json
  total_json=$(aws ce get-cost-and-usage \
    --time-period "Start=${start_date},End=${end_date}" \
    --granularity MONTHLY \
    --metrics "BlendedCost" \
    --output json 2>&1) || {
      error "AWS Cost Explorer query failed. Check IAM permissions (ce:GetCostAndUsage)."
      echo "$total_json" >&2
      return 1
    }

  local total_amount currency
  total_amount=$(echo "$total_json" | \
    python3 -c "
import json,sys
data=json.load(sys.stdin)
results=data['ResultsByTime']
total=sum(float(r['Total']['BlendedCost']['Amount']) for r in results)
unit=results[0]['Total']['BlendedCost']['Unit'] if results else 'USD'
print(f'{total:.4f} {unit}')
" 2>/dev/null || echo "parse error")

  gum style \
    --border normal \
    --border-foreground 212 \
    --padding "0 2" \
    "$(gum style --foreground 245 --width 22 "Total Cost")$(gum style --foreground 255 --bold "$total_amount")"
  echo ""

  # Top services breakdown
  local svc_json
  svc_json=$(aws ce get-cost-and-usage \
    --time-period "Start=${start_date},End=${end_date}" \
    --granularity MONTHLY \
    --metrics "BlendedCost" \
    --group-by "Type=DIMENSION,Key=SERVICE" \
    --output json 2>/dev/null || echo "{}")

  echo ""
  gum style --foreground 212 --bold "  Top Services"
  echo ""

  echo "$svc_json" | python3 -c "
import json, sys
data=json.load(sys.stdin)
svc_totals={}
for r in data.get('ResultsByTime',[]):
  for g in r.get('Groups',[]):
    k=g['Keys'][0]
    v=float(g['Metrics']['BlendedCost']['Amount'])
    svc_totals[k]=svc_totals.get(k,0)+v
top=sorted(svc_totals.items(),key=lambda x:-x[1])[:8]
for name,cost in top:
  if cost > 0.001:
    print(f'  {name:<45}  \${cost:.4f}')
" 2>/dev/null || warn "Could not parse service breakdown."

  echo ""

  # Budget check (optional)
  local budgets_json
  budgets_json=$(aws budgets describe-budgets \
    --account-id "$(aws sts get-caller-identity --query Account --output text 2>/dev/null)" \
    --output json 2>/dev/null || echo "{}")

  local budget_count
  budget_count=$(echo "$budgets_json" | python3 -c "
import json,sys
print(len(json.load(sys.stdin).get('Budgets',[])))
" 2>/dev/null || echo "0")

  if [[ "$budget_count" -gt 0 ]]; then
    gum style --foreground 212 --bold "  Active Budgets"
    echo ""
    echo "$budgets_json" | python3 -c "
import json,sys
for b in json.load(sys.stdin).get('Budgets',[]):
  name=b['BudgetName']
  limit=b['BudgetLimit']['Amount']
  unit=b['BudgetLimit']['Unit']
  actual=b.get('CalculatedSpend',{}).get('ActualSpend',{}).get('Amount','?')
  print(f'  {name:<40}  {actual} / {limit} {unit}')
" 2>/dev/null
    echo ""
  fi
}

# ─── Azure billing ────────────────────────────────────────────────────────────
billing_azure() {
  local rg
  rg=$(config_get "resource_group" 2>/dev/null || echo "hermes-rg")

  gum style --foreground 212 --bold "  Azure Cost Summary"
  echo ""

  local sub_id sub_name
  sub_id=$(az account show --query id -o tsv 2>/dev/null || echo "")
  sub_name=$(az account show --query name -o tsv 2>/dev/null || echo "unknown")
  gum style --foreground 245 "  Subscription: ${sub_name}"
  echo ""

  local start_date end_date
  end_date=$(date -u +%Y-%m-%d)
  start_date=$(date -u +%Y-%m-01)

  # Query cost management
  local cost_json
  cost_json=$(az costmanagement query \
    --type "ActualCost" \
    --scope "subscriptions/${sub_id}" \
    --timeframe "MonthToDate" \
    --dataset-aggregation '{"totalCost":{"name":"PreTaxCost","function":"Sum"}}' \
    --dataset-grouping '[{"type":"Dimension","name":"ServiceName"}]' \
    -o json 2>&1) || {
      warn "Could not query Cost Management API."
      echo "  Check that Billing Reader / Cost Management Reader role is assigned."
      return 1
    }

  echo "$cost_json" | python3 -c "
import json,sys
data=json.load(sys.stdin)
rows=data.get('rows',[])
cols=[c['name'] for c in data.get('columns',[])]
cost_idx=next((i for i,c in enumerate(cols) if 'cost' in c.lower()),0)
name_idx=next((i for i,c in enumerate(cols) if 'service' in c.lower()),1)
svc_totals={}
for r in rows:
  k=r[name_idx] if len(r)>name_idx else 'Unknown'
  v=float(r[cost_idx]) if len(r)>cost_idx else 0
  svc_totals[k]=svc_totals.get(k,0)+v
top=sorted(svc_totals.items(),key=lambda x:-x[1])[:8]
total=sum(svc_totals.values())
print(f'  Total (MTD):  {total:.4f} USD\n')
print('  Top Services:')
for name,cost in top:
  if cost > 0.001:
    print(f'    {name:<44}  \${cost:.4f}')
" 2>/dev/null || warn "Could not parse Azure cost data."
  echo ""
}

# ─── GCP billing ─────────────────────────────────────────────────────────────
billing_gcp() {
  local project_id
  project_id=$(config_get "project_id" 2>/dev/null || \
               gcloud config get-value project 2>/dev/null || echo "")

  if [[ -z "$project_id" ]]; then
    error "GCP project ID not found. Run hermes-agent-cloud deploy first."
    exit 1
  fi

  gum style --foreground 212 --bold "  GCP Cost Summary"
  echo ""
  gum style --foreground 245 "  Project: ${project_id}"
  echo ""

  # Check billing account linkage
  local billing_account
  billing_account=$(gcloud billing projects describe "$project_id" \
    --format="value(billingAccountName)" 2>/dev/null | sed 's|billingAccounts/||' || echo "")

  if [[ -z "$billing_account" ]]; then
    warn "No billing account linked to project ${project_id}."
    return 1
  fi

  gum style --foreground 245 "  Billing Account: ${billing_account}"
  echo ""

  # SKU cost via gcloud billing (requires BigQuery export for detail)
  warn "GCP real-time cost breakdown requires BigQuery billing export."
  echo ""
  echo "  To enable detailed billing queries:"
  echo "  1. Enable billing export to BigQuery:"
  echo "     https://cloud.google.com/billing/docs/how-to/export-data-bigquery"
  echo "  2. Query with: bq query --use_legacy_sql=false \\"
  echo "       'SELECT service.description, SUM(cost) AS total"
  echo "        FROM \`PROJECT.DATASET.gcp_billing_export_*\`"
  echo "        WHERE DATE(_PARTITIONTIME) >= DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY)"
  echo "        GROUP BY 1 ORDER BY 2 DESC LIMIT 10'"
  echo ""

  # Show current month budget if any
  local budget_json
  budget_json=$(gcloud billing budgets list \
    --billing-account "$billing_account" \
    --format=json 2>/dev/null || echo "[]")

  local budget_count
  budget_count=$(echo "$budget_json" | python3 -c "import json,sys; print(len(json.load(sys.stdin)))" 2>/dev/null || echo 0)

  if [[ "$budget_count" -gt 0 ]]; then
    gum style --foreground 212 --bold "  Active Budgets"
    echo ""
    echo "$budget_json" | python3 -c "
import json,sys
for b in json.load(sys.stdin):
  name=b.get('displayName','(unnamed)')
  amt=b.get('amount',{}).get('specifiedAmount',{})
  units=amt.get('units','?')
  currency=amt.get('currencyCode','USD')
  print(f'  {name:<44}  {units} {currency}')
" 2>/dev/null
    echo ""
  fi
}
