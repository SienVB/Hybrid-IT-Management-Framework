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

  security_rule {
    name                       = "HTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }  
  security_rule {
    name                       = "SSH"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
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