resource "azurerm_virtual_network" "hermes" {
  name                = "hermes-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.hermes.location
  resource_group_name = azurerm_resource_group.hermes.name

  tags = {
    Project = "Hermes-Agent-Cloud"
  }
}

resource "azurerm_subnet" "hermes" {
  name                 = "hermes-subnet"
  resource_group_name  = azurerm_resource_group.hermes.name
  virtual_network_name = azurerm_virtual_network.hermes.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "hermes" {
  name                = "hermes-public-ip"
  location            = azurerm_resource_group.hermes.location
  resource_group_name = azurerm_resource_group.hermes.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Project = "Hermes-Agent-Cloud"
  }
}

resource "azurerm_network_security_group" "hermes" {
  name                = "hermes-nsg"
  location            = azurerm_resource_group.hermes.location
  resource_group_name = azurerm_resource_group.hermes.name

  security_rule {
    name                       = "allow-ssh"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.allowed_ssh_cidr
    destination_address_prefix = "*"
    description                = "SSH from deployer IP only"
  }

  security_rule {
    name                       = "allow-hermes-gateway"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = var.allowed_ssh_cidr
    destination_address_prefix = "*"
    description                = "Hermes gateway from deployer IP only"
  }

  tags = {
    Project = "Hermes-Agent-Cloud"
  }
}

resource "azurerm_network_interface" "hermes" {
  name                = "hermes-nic"
  location            = azurerm_resource_group.hermes.location
  resource_group_name = azurerm_resource_group.hermes.name

  ip_configuration {
    name                          = "hermes-nic-config"
    subnet_id                     = azurerm_subnet.hermes.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.hermes.id
  }

  tags = {
    Project = "Hermes-Agent-Cloud"
  }
}

resource "azurerm_network_interface_security_group_association" "hermes" {
  network_interface_id      = azurerm_network_interface.hermes.id
  network_security_group_id = azurerm_network_security_group.hermes.id
}
