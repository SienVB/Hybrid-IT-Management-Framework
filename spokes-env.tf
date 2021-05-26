// RG: rg_Services
// vNET: SpokesVNET
// Subnet: Services-Subnet
// NSG: Services-NSG
// NIC: Service-NIC
// vNET peering to NetworkingVNET: Spokes-to-Shared



# Create rg_Services
resource "azurerm_resource_group" "rg_Services" {
  name     = "rg_Services"
  location = "West Europe"
}


# Create SpokesVNET within rg_Network
resource "azurerm_virtual_network" "SpokesVNET" {
  name                = "SpokesVNET"
  resource_group_name = azurerm_resource_group.rg_Network.name
  location            = azurerm_resource_group.rg_Network.location
  address_space       = ["10.3.0.0/16"]
}

# Subnet 10.2.1.0/24 - Services-Subnet
resource "azurerm_subnet" "Services-Subnet" {
  name                 = "Services-Subnet"
  resource_group_name  = azurerm_resource_group.rg_Network.name
  virtual_network_name = azurerm_virtual_network.SpokesVNET.name
  address_prefixes     = ["10.3.1.0/24"]
}

# NSG Services-NSG
# Still needs to be coupled with the NIC on the VM
# More rules can be added later on
resource "azurerm_network_security_group" "Services-NSG" {
  name                = "Services-NSG"
  location            = azurerm_resource_group.rg_Network.location
  resource_group_name = azurerm_resource_group.rg_Network.name
  ## Inbound rules
  security_rule {
    name                       = "allow-RDPManagement"
    priority                   = 4092
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "10.1.2.0/24"
    destination_address_prefix = "10.3.1.0/24"
  }
  security_rule {
    name                       = "allow-WinRMManagement"
    priority                   = 4093
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5986"
    source_address_prefix      = "10.1.2.0/24"
    destination_address_prefix = "10.3.1.0/24"
  }
  security_rule {
    name                       = "allow-LocalSubnet"
    priority                   = 4094
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.3.1.0/24"
    destination_address_prefix = "10.3.1.0/24"
  } 
  security_rule {
    name                       = "AllowAzureLoadBalancer"
    priority                   = 4095
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "10.3.1.0/24"
  } 
  security_rule {
    name                       = "block-VirtualNetwork"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }
  ## Outbound rules
  security_rule {
    name                       = "allow-Outbound"
    priority                   = 4093
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.1.3.0/24"
    destination_address_prefix = "10.1.0.0/16"
  }
  security_rule {
    name                       = "allow-OnPremOutbound"
    priority                   = 4094
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.1.3.0/24"
    destination_address_prefix = "10.0.0.0/16"
  }
  security_rule {
    name                       = "allow-AzureCloud"
    priority                   = 4095
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "AzureCloud"
  }
  security_rule {
    name                       = "block-Internet"
    priority                   = 4096
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }
}

# Network interface for the Service
resource "azurerm_network_interface" "Service-NIC" {
  name                = "Service-NIC"
  location            = azurerm_resource_group.rg_Network.location
  resource_group_name = azurerm_resource_group.rg_Network.name
  ip_configuration {
    name                          = "Service-IP"
    subnet_id                     = azurerm_subnet.Services-Subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Allocate NSG to NIC Service
resource "azurerm_subnet_network_security_group_association" "Services-NSG_to_DC-Service" {
  subnet_id                 = azurerm_subnet.Services-Subnet.id
  network_security_group_id = azurerm_network_security_group.Services-NSG.id
}

## Network peering SpokesVNET to NetworkingVNET
resource "azurerm_virtual_network_peering" "Spokes-to-Shared" {
  name                      = "Spokes-to-Shared"
  resource_group_name       = azurerm_resource_group.rg_Network.name
  virtual_network_name      = azurerm_virtual_network.SpokesVNET.name
  remote_virtual_network_id = azurerm_virtual_network.NetworkingVNET.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}