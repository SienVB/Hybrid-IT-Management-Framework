// RGs: rg_On-Prem-Networking, rg_On-Prem-DC, rg_On-Prem-Clients
// 1 vNET: On-PremVNET (in rg_On-Prem-Networking)
// Subnets: On-Prem-DC-Subnet, On-Prem-Clients-Subnet, On-Prem-Gateway-Subnet (all in rg_On-Prem-Networking)
// vNET peering to NetworkingVNET
// NSG : On-Prem-DC-NSG, On-Prem-Clients-NSG
// 2 windows servers virtual machines (in rg_On-Prem-DC), 1 windows client (in rg_On-Prem-Clients)
// NICs for servers


# Create rg_On-Prem-Networking
resource "azurerm_resource_group" "rg_On-Prem-Networking" {
  name     = "rg_On-Prem-Networking"
  location = "West Europe"
}

# Create rg_On-Prem-DC
resource "azurerm_resource_group" "rg_On-Prem-DC" {
  name     = "rg_On-Prem-DC"
  location = "West Europe"
}

# Create rg_On-Prem-Clients
resource "azurerm_resource_group" "rg_On-Prem-Clients" {
  name     = "rg_On-Prem-Clients"
  location = "West Europe"
}

# Create On-PremVNET within rg_On-Prem-Networking
resource "azurerm_virtual_network" "On-PremVNET" {
  name                = "On-PremVNET"
  resource_group_name = azurerm_resource_group.rg_On-Prem-Networking.name
  location            = azurerm_resource_group.rg_On-Prem-Networking.location
  address_space       = ["10.0.0.0/16"]
  dns_servers         = [ "10.0.1.5" ]
}

# Subnet 10.0.1.0/24 - On-Prem-DC-Subnet
resource "azurerm_subnet" "On-Prem-DC-Subnet" {
  name                 = "On-Prem-DC-Subnet"
  resource_group_name  = azurerm_resource_group.rg_On-Prem-Networking.name
  virtual_network_name = azurerm_virtual_network.On-PremVNET.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Subnet 10.0.2.0/24 - On-Prem-Clients-Subnet
resource "azurerm_subnet" "On-Prem-Clients-Subnet" {
  name                 = "On-Prem-Clients-Subnet"
  resource_group_name  = azurerm_resource_group.rg_On-Prem-Networking.name
  virtual_network_name = azurerm_virtual_network.On-PremVNET.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Subnet 10.0.3.0/24 - On-Prem-Gateway-Subnet
resource "azurerm_subnet" "On-Prem-Gateway-Subnet" {
  name                 = "On-Prem-Gateway-Subnet"
  resource_group_name  = azurerm_resource_group.rg_On-Prem-Networking.name
  virtual_network_name = azurerm_virtual_network.On-PremVNET.name
  address_prefixes     = ["10.0.3.0/24"]
}

# NSG On-Prem-DC-NSG
# Still needs to be coupled with the NIC on the VMs
# More rules can be added later on
resource "azurerm_network_security_group" "On-Prem-DC-NSG" {
  name                = "On-Prem-DC-NSG"
  location            = azurerm_resource_group.rg_On-Prem-Networking.location
  resource_group_name = azurerm_resource_group.rg_On-Prem-Networking.name 
}

# NSG On-Prem-Clients-NSG
# Still needs to be coupled with the NIC on the VM
resource "azurerm_network_security_group" "On-Prem-Clients-NSG" {
  name                = "On-Prem-Clients-NSG"
  location            = azurerm_resource_group.rg_On-Prem-Networking.location
  resource_group_name = azurerm_resource_group.rg_On-Prem-Networking.name

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
    name                       = "RDP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
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


# Network interface for the DC
resource "azurerm_network_interface" "On-Prem-DC-NIC" {
  name                = "On-Prem-DC-NIC"
  location            = azurerm_resource_group.rg_On-Prem-Networking.location
  resource_group_name = azurerm_resource_group.rg_On-Prem-Networking.name
  ip_configuration {
    name                          = "On-Prem-DC-IP"
    subnet_id                     = azurerm_subnet.On-Prem-DC-Subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.5"
  }
}


# Network interface for the ADC
resource "azurerm_network_interface" "On-Prem-ADC-NIC" {
  name                = "On-Prem-ADC-NIC"
  location            = azurerm_resource_group.rg_On-Prem-Networking.location
  resource_group_name = azurerm_resource_group.rg_On-Prem-Networking.name
  ip_configuration {
    name                          = "On-Prem-ADC-IP"
    subnet_id                     = azurerm_subnet.On-Prem-DC-Subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}


# Network interface for the client
resource "azurerm_network_interface" "On-Prem-Client-NIC" {
  name                = "On-Prem-Client-NIC"
  location            = azurerm_resource_group.rg_On-Prem-Networking.location
  resource_group_name = azurerm_resource_group.rg_On-Prem-Networking.name
  ip_configuration {
    name                          = "On-Prem-Client-IP"
    subnet_id                     = azurerm_subnet.On-Prem-Clients-Subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Allocate NSG to NIC DC
resource "azurerm_subnet_network_security_group_association" "On-Prem-DC-NSG_to_DC-NIC" {
  subnet_id                 = azurerm_subnet.On-Prem-DC-Subnet.id
  network_security_group_id = azurerm_network_security_group.On-Prem-DC-NSG.id
}


# Allocate NSG to NIC Clients
resource "azurerm_subnet_network_security_group_association" "On-Prem-Clients-NSG_to_Client-NIC" {
  subnet_id                 = azurerm_subnet.On-Prem-Clients-Subnet.id
  network_security_group_id = azurerm_network_security_group.On-Prem-Clients-NSG.id
}


## create the DC VM
resource "azurerm_virtual_machine" "On-Prem-DC" {
  name                  = "On-Prem-DC"
  location              = azurerm_resource_group.rg_On-Prem-DC.location
  resource_group_name   = azurerm_resource_group.rg_On-Prem-DC.name
  network_interface_ids = [azurerm_network_interface.On-Prem-DC-NIC.id]
  # List of available sizes: https://docs.microsoft.com/en-us/azure/cloud-services/cloud-services-sizes-specs
  vm_size               = "Standard_B2s"

  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  # Base image
  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
  
  # Disk
  
  storage_os_disk {
    name              = "On-Prem-DC-os-disk"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "On-Prem-DC"
    # Note: you can't use admin or Administrator in here, Azure won't allow you to do so :-)
    admin_username = "sien"
    admin_password = "${data.azurerm_key_vault_secret.Secrets.value}"
    custom_data    = "${file("./files/winrm.ps1")}"
  }

  os_profile_windows_config {
    provision_vm_agent = "true"
    timezone           = "Central European Standard Time"
    winrm {
      protocol = "http"
    }
    # Auto-Login's required to configure WinRM
    additional_unattend_config {
      pass         = "oobeSystem"
      component    = "Microsoft-Windows-Shell-Setup"
      setting_name = "AutoLogon"
      content      = "<AutoLogon><Password><Value>${data.azurerm_key_vault_secret.Secrets.value}</Value></Password><Enabled>true</Enabled><LogonCount>1</LogonCount><Username>sien</Username></AutoLogon>"
    }
    additional_unattend_config {
      pass         = "oobeSystem"
      component    = "Microsoft-Windows-Shell-Setup"
      setting_name = "FirstLogonCommands"
      content      = "${file("./files/FirstLogonCommands.xml")}"
    }
  }
}

## create the AD Connect (ADC) VM
resource "azurerm_virtual_machine" "On-Prem-ADC" {
  depends_on            = [time_sleep.wait_for_15_minutes]
  name                  = "On-Prem-ADC"
  location              = azurerm_resource_group.rg_On-Prem-DC.location
  resource_group_name   = azurerm_resource_group.rg_On-Prem-DC.name
  network_interface_ids = [azurerm_network_interface.On-Prem-ADC-NIC.id]
  # List of available sizes: https://docs.microsoft.com/en-us/azure/cloud-services/cloud-services-sizes-specs
  vm_size               = "Standard_B2s"

  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  # Base image
  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
  
  # Disk
  
  storage_os_disk {
    name              = "On-Prem-ADC-os-disk"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "On-Prem-ADC"
    # Note: you can't use admin or Administrator in here, Azure won't allow you to do so :-)
    admin_username = "sien"
    admin_password = "${data.azurerm_key_vault_secret.Secrets.value}"
    custom_data    = "${file("./files/winrmADC.ps1")}"
  }

  os_profile_windows_config {
    provision_vm_agent = "true"
    timezone           = "Central European Standard Time"
    winrm {
      protocol = "http"
    }
    # Auto-Login's required to configure WinRM
    additional_unattend_config {
      pass         = "oobeSystem"
      component    = "Microsoft-Windows-Shell-Setup"
      setting_name = "AutoLogon"
      content      = "<AutoLogon><Password><Value>${data.azurerm_key_vault_secret.Secrets.value}</Value></Password><Enabled>true</Enabled><LogonCount>1</LogonCount><Username>sien</Username></AutoLogon>"
    }
    additional_unattend_config {
      pass         = "oobeSystem"
      component    = "Microsoft-Windows-Shell-Setup"
      setting_name = "FirstLogonCommands"
      content      = "${file("./files/FirstLogonCommands.xml")}"
    }
  }
}

## create the client VM
resource "azurerm_virtual_machine" "On-Prem-Client" {
  depends_on            = [time_sleep.wait_for_15_minutes]
  name                  = "On-Prem-Client"
  location              = azurerm_resource_group.rg_On-Prem-Clients.location
  resource_group_name   = azurerm_resource_group.rg_On-Prem-Clients.name
  network_interface_ids = [azurerm_network_interface.On-Prem-Client-NIC.id]
  # List of available sizes: https://docs.microsoft.com/en-us/azure/cloud-services/cloud-services-sizes-specs
  vm_size               = "Standard_B2s"

  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  # Base image
  storage_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "19h1-pro"	
    version   = "latest"
  }
  
  # Disk
  
  storage_os_disk {
    name              = "On-Prem-Client-os-disk"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "On-Prem-Client"
    # Note: you can't use admin or Administrator in here, Azure won't allow you to do so :-)
    admin_username = "sien"
    admin_password = "${data.azurerm_key_vault_secret.Secrets.value}"
    custom_data    = "${file("./files/winrmclient.ps1")}"
  }
  os_profile_windows_config {
    provision_vm_agent = "true"
    timezone           = "Central European Standard Time"
    winrm {
      protocol = "http"
    }
    # Auto-Login's required to configure WinRM
    additional_unattend_config {
      pass         = "oobeSystem"
      component    = "Microsoft-Windows-Shell-Setup"
      setting_name = "AutoLogon"
      content      = "<AutoLogon><Password><Value>${data.azurerm_key_vault_secret.Secrets.value}</Value></Password><Enabled>true</Enabled><LogonCount>1</LogonCount><Username>sien</Username></AutoLogon>"
    }
    additional_unattend_config {
      pass         = "oobeSystem"
      component    = "Microsoft-Windows-Shell-Setup"
      setting_name = "FirstLogonCommands"
      content      = "${file("./files/FirstLogonCommands.xml")}"
    }
  }
}

## Network peering On-PremVNET to NetworkingVNET
resource "azurerm_virtual_network_peering" "On-Prem-to-Shared" {
  name                      = "On-Prem-to-Shared"
  resource_group_name       = azurerm_resource_group.rg_On-Prem-Networking.name
  virtual_network_name      = azurerm_virtual_network.On-PremVNET.name
  remote_virtual_network_id = azurerm_virtual_network.NetworkingVNET.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}