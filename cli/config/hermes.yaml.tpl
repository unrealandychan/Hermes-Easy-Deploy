# Hermes Agent configuration
# Managed by Hermes-Agent-Cloud

terminal:
  backend: docker          # Sandboxed Docker execution (recommended)
  container_cpu: 1
  container_memory: 5120   # 5 GB RAM
  container_disk: 51200    # 50 GB disk
  container_persistent: true

agent:
  max_turns: 90

compression:
  enabled: true
  threshold: 0.50

display:
  tool_progress: all
