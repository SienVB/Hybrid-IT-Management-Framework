// RGs: rg_Network, rg_DC, rg_Bastion, rg_Security, rg_Management
// 1 vNET: NetworkingVNET (in rg_Network)
// Subnets: DC-Subnet, Management-Subnet, Gateway-Subnet, Bastion-Subnet (all in rg_Network)
// vNET peering to On-PremVNET
// vNET peering to SpokesVNET
// NSG : DC-NSG, Management-NSG, Bastion-NSG
// 2 windows servers virtual machines (one in rg_Management (2 if HA cluster), one in rg_DC)
// NICs for servers
// Log analytics workspace 
// Logic apps for Sentinel playbooks
// Vault for backups
// Backup configurations VMs

# Create rg_Network
resource "azurerm_resource_group" "rg_Network" {
  name     = "rg_Network"
  location = "West Europe"
}

# Create rg_DC
resource "azurerm_resource_group" "rg_DC" {
  name     = "rg_DC"
  location = "West Europe"
}

# Create rg_Bastion
resource "azurerm_resource_group" "rg_Bastion" {
  name     = "rg_Bastion"
  location = "West Europe"
}

# Create rg_Security
resource "azurerm_resource_group" "rg_Security" {
  name     = "rg_Security"
  location = "West Europe"
}

# Create rg_Management
resource "azurerm_resource_group" "rg_Management" {
  name     = "rg_Management"
  location = "West Europe"
}

# Create NetworkingVNET within rg_Network
resource "azurerm_virtual_network" "NetworkingVNET" {
  name                = "NetworkingVNET"
  resource_group_name = azurerm_resource_group.rg_Network.name
  location            = azurerm_resource_group.rg_Network.location
  address_space       = ["10.1.0.0/16"]
  dns_servers         = [ azurerm_network_interface.On-Prem-DC-NIC.private_ip_address ]
}

# Subnet 10.1.1.0/24 - DC-Subnet
resource "azurerm_subnet" "DC-Subnet" {
  name                 = "DC-Subnet"
  resource_group_name  = azurerm_resource_group.rg_Network.name
  virtual_network_name = azurerm_virtual_network.NetworkingVNET.name
  address_prefixes     = ["10.1.1.0/24"]
}

# Subnet 10.1.2.0/24 - Management-Subnet
resource "azurerm_subnet" "Management-Subnet" {
  name                 = "Management-Subnet"
  resource_group_name  = azurerm_resource_group.rg_Network.name
  virtual_network_name = azurerm_virtual_network.NetworkingVNET.name
  address_prefixes     = ["10.1.2.0/24"]
}

# Subnet 10.1.3.0/24 - Bastion-Subnet
resource "azurerm_subnet" "AzureBastionSubnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg_Network.name
  virtual_network_name = azurerm_virtual_network.NetworkingVNET.name
  address_prefixes     = ["10.1.3.0/24"]
}

# Subnet 10.1.4.0/24 - Gateway-Subnet
resource "azurerm_subnet" "Gateway-Subnet" {
  name                 = "Gateway-Subnet"
  resource_group_name  = azurerm_resource_group.rg_Network.name
  virtual_network_name = azurerm_virtual_network.NetworkingVNET.name
  address_prefixes     = ["10.1.4.0/24"]
}

#resource "azurerm_availability_set" "Bastion-Availability" {
#  name                = "Bastion-Availability"
#  location            = azurerm_resource_group.rg_Bastion.location
#  resource_group_name = azurerm_resource_group.rg_Bastion.name
#  platform_fault_domain_count  = 2
#  platform_update_domain_count = 2
#}


#resource "azurerm_availability_set" "Management-Availability" {
#  name                = "Management-Availability"
#  location            = azurerm_resource_group.rg_Management.location
#  resource_group_name = azurerm_resource_group.rg_Management.name
#  platform_fault_domain_count  = 2
#  platform_update_domain_count = 2
#}

# NSG DC-NSG
# Still needs to be coupled with the NIC on the VM
# More rules can be added later on
resource "azurerm_network_security_group" "DC-NSG" {
  name                = "DC-NSG"
  location            = azurerm_resource_group.rg_Network.location
  resource_group_name = azurerm_resource_group.rg_Network.name 
}

# NSG Management-NSG
# Still needs to be coupled with the NIC on the VM
# More rules can be added later on
resource "azurerm_network_security_group" "Management-NSG" {
  name                = "Management-NSG"
  location            = azurerm_resource_group.rg_Network.location
  resource_group_name = azurerm_resource_group.rg_Network.name 
}

# NSG Bastion-NSG
# Still needs to be coupled with the NIC on the VM
# More rules can be added later on
resource "azurerm_network_security_group" "Bastion-NSG" {
  name                = "Bastion-NSG"
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
    name                       = "communication"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }  
  security_rule {
    name                       = "communication2"
    priority                   = 108
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "5701"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }  
  security_rule {
    name                       = "SSH"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
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
    name                       = "SSH-out"
    priority                   = 103
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "22"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }  
  security_rule {
    name                       = "HTTPS-out"
    priority                   = 104
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "443"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*" 
    }
    security_rule {
    name                       = "HTTP-out"
    priority                   = 105
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "80"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    }
    security_rule {
    name                       = "communication-out"
    priority                   = 106
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "8080"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    }
    security_rule {
    name                       = "communication-out2"
    priority                   = 107
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "5701"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    }
}


# Network interface for the DC
resource "azurerm_network_interface" "DC-NIC" {
  name                = "DC-NIC"
  location            = azurerm_resource_group.rg_Network.location
  resource_group_name = azurerm_resource_group.rg_Network.name
  ip_configuration {
    name                          = "DC-IP"
    subnet_id                     = azurerm_subnet.DC-Subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}


# Network interface for the management server
resource "azurerm_network_interface" "Management-NIC" {
  #count               = 2
  #name                = "Management-NIC${count.index}"
  name                = "Management-NIC"
  location            = azurerm_resource_group.rg_Network.location
  resource_group_name = azurerm_resource_group.rg_Network.name
  ip_configuration {
    name                          = "Management-IP"
    subnet_id                     = azurerm_subnet.Management-Subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

## Create load balancer for management availability set
#resource "azurerm_lb" "Management-LB" {
# name                = "Management-LB"
# location            = azurerm_resource_group.rg_Management.location
# resource_group_name = azurerm_resource_group.rg_Management.name

 #frontend_ip_configuration {
  # name                 = "Management-PIP"
   #public_ip_address_id = azurerm_public_ip.Management-PIP.id
 #}
#}

#resource "azurerm_lb_backend_address_pool" "Management-LB-Backend" {
 #resource_group_name = azurerm_resource_group.rg_Management.name
 #loadbalancer_id     = azurerm_lb.Management-LB.id
 #name                = "Management-LB-Backend"
#}

// Public IP Bastion
#resource "azurerm_public_ip" "Bastion-PIP" {
#  name                = "Bastion-PIP"
#  location            = "West europe"
#  resource_group_name = azurerm_resource_group.rg_Network.name
#  allocation_method   = "Static"
#  sku                 = "Standard"
#}

# Network interface for the Bastion
#resource "azurerm_network_interface" "Bastion-NIC" {
#  count               = 2
#  name                = "Bastion-NIC${count.index}"
#  location            = azurerm_resource_group.rg_Network.location
#  resource_group_name = azurerm_resource_group.rg_Network.name
#  ip_configuration {
#    name                          = "Bastion-IP"
#    subnet_id                     = azurerm_subnet.Bastion-Subnet.id
#    private_ip_address_allocation = "Dynamic"
#  }
#}

## Create load balancer for bastion availability set
#resource "azurerm_lb" "Bastion-LB" {
# name                = "Bastion-LB"
# location            = azurerm_resource_group.rg_Bastion.location
# resource_group_name = azurerm_resource_group.rg_Bastion.name

# frontend_ip_configuration {
#   name                 = "Bastion-PIP"
#   public_ip_address_id = azurerm_public_ip.Bastion-PIP.id
# }
#}

#resource "azurerm_lb_backend_address_pool" "Bastion-LB-Backend" {
# resource_group_name = azurerm_resource_group.rg_Bastion.name
# loadbalancer_id     = azurerm_lb.Bastion-LB.id
# name                = "Bastion-LB-Backend"
#}


# Allocate NSG to NIC DC
resource "azurerm_subnet_network_security_group_association" "DC-NSG_to_DC-NIC" {
  subnet_id                 = azurerm_subnet.DC-Subnet.id
  network_security_group_id = azurerm_network_security_group.DC-NSG.id
}

# Allocate NSG to NIC Bastion
#resource "azurerm_subnet_network_security_group_association" "Bastion-NSG_to_Bastion-NIC" {
#  subnet_id                 = azurerm_subnet.AzureBastionSubnet.id
#  network_security_group_id = azurerm_network_security_group.Bastion-NSG.id
#}

# Allocate NSG to NIC Management
resource "azurerm_subnet_network_security_group_association" "Management-NSG_to_Management-NIC" {
  subnet_id                 = azurerm_subnet.Management-Subnet.id
  network_security_group_id = azurerm_network_security_group.Management-NSG.id
}

## Wait some time to make sure forest and first DC are configured before making new DC
resource "time_sleep" "wait_for_15_minutes" {
  depends_on = [azurerm_resource_group.rg_On-Prem-DC]

  create_duration = "15m"
}

## create the DC VM
resource "azurerm_virtual_machine" "DC" {
  depends_on            = [time_sleep.wait_for_15_minutes]
  name                  = "DC"
  location              = azurerm_resource_group.rg_DC.location
  resource_group_name   = azurerm_resource_group.rg_DC.name
  network_interface_ids = [azurerm_network_interface.DC-NIC.id]
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
    name              = "DC-os-disk"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "DC"
    # Note: you can't use admin or Administrator in here, Azure won't allow you to do so :-)
    admin_username = "sien"
    admin_password = "XXXX"
    custom_data    = "${file("./files/winrm2.ps1")}"
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
      content      = "<AutoLogon><Password><Value>XXXX</Value></Password><Enabled>true</Enabled><LogonCount>1</LogonCount><Username>sien</Username></AutoLogon>"
    }
    additional_unattend_config {
      pass         = "oobeSystem"
      component    = "Microsoft-Windows-Shell-Setup"
      setting_name = "FirstLogonCommands"
      content      = "${file("./files/FirstLogonCommands.xml")}"
    }
  }
}

## create  Management VMs
resource "azurerm_virtual_machine" "ManagementVM0" {
  #count             = 2
  depends_on            = [time_sleep.wait_for_15_minutes]
  #name                  = "ManagementVM${count.index}"
  name                  = "ManagementVM0"
  #availability_set_id   = azurerm_availability_set.Management-Availability.id
  location              = azurerm_resource_group.rg_Management.location
  resource_group_name   = azurerm_resource_group.rg_Management.name
  #network_interface_ids = [element(azurerm_network_interface.Management-NIC.*.id, count.index)]
  network_interface_ids = [azurerm_network_interface.Management-NIC.id]
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
    #name              = "Management-os-disk${count.index}"
    name              = "Management-os-disk0"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    #computer_name  = "ManagementVM${count.index}"
    computer_name  = "ManagementVM0"
    # Note: you can't use admin or Administrator in here, Azure won't allow you to do so :-)
    admin_username = "sien"
    admin_password = "XXXX"
    custom_data    = "${file("./files/winrmClient.ps1")}"
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
      content      = "<AutoLogon><Password><Value>XXXX</Value></Password><Enabled>true</Enabled><LogonCount>1</LogonCount><Username>sien</Username></AutoLogon>"
    }
    additional_unattend_config {
      pass         = "oobeSystem"
      component    = "Microsoft-Windows-Shell-Setup"
      setting_name = "FirstLogonCommands"
      content      = "${file("./files/FirstLogonCommands.xml")}"
    }
  }
}


#resource "azurerm_bastion_host" "Bastion" {
#  name                = "Bastion"
#  location            = azurerm_resource_group.rg_Bastion.location
#  resource_group_name = azurerm_resource_group.rg_Bastion.name

#  ip_configuration {
#    name                 = "configuration"
#    subnet_id            = azurerm_subnet.AzureBastionSubnet.id
#    public_ip_address_id = azurerm_public_ip.Bastion-PIP.id
#  }
#}


## Network peering NetworkingVNET to On-PremVNET
resource "azurerm_virtual_network_peering" "Shared-to-On-Prem" {
  name                      = "Shared-to-On-Prem"
  resource_group_name       = azurerm_resource_group.rg_Network.name
  virtual_network_name      = azurerm_virtual_network.NetworkingVNET.name
  remote_virtual_network_id = azurerm_virtual_network.On-PremVNET.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

## Network peering NetworkingVNET to SpokesVNET
resource "azurerm_virtual_network_peering" "Shared-to-Spokes" {
  name                      = "Shared-to-Spokes"
  resource_group_name       = azurerm_resource_group.rg_Network.name
  virtual_network_name      = azurerm_virtual_network.NetworkingVNET.name
  remote_virtual_network_id = azurerm_virtual_network.SpokesVNET.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}


## Create a log analytics workspace
resource "azurerm_log_analytics_workspace" "MonitorWorkspace" {
  name                = "MonitorWorkspace"
  location            = azurerm_resource_group.rg_Security.location
  resource_group_name = azurerm_resource_group.rg_Security.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

## Logic apps for Sentinel workbooks

resource "azurerm_logic_app_workflow" "BreakGlassUser" {
  name                = "BreakGlassUser"
  location            = azurerm_resource_group.rg_Security.location
  resource_group_name = azurerm_resource_group.rg_Security.name
}

resource "azurerm_logic_app_workflow" "PrivilegedUser" {
  name                = "PrivilegedUser"
  location            = azurerm_resource_group.rg_Security.location
  resource_group_name = azurerm_resource_group.rg_Security.name
}

resource "azurerm_logic_app_workflow" "CriticalSystemDown" {
  name                = "CriticalSystemDown"
  location            = azurerm_resource_group.rg_Security.location
  resource_group_name = azurerm_resource_group.rg_Security.name
}

## Create a vault to save backups to
resource "azurerm_recovery_services_vault" "BackupVault" {
  name                = "BackupVault"
  location            = azurerm_resource_group.rg_Security.location
  resource_group_name = azurerm_resource_group.rg_Security.name
  sku                 = "Standard"
}

## Create a policy to backup systems daily at 11pm
resource "azurerm_backup_policy_vm" "BackupPolicy" {
  name                = "BackupPolicy"
  resource_group_name = azurerm_resource_group.rg_Security.name
  recovery_vault_name = azurerm_recovery_services_vault.r_Security.name

  timezone = "UTC"

  backup {
    frequency = "Daily"
    time      = "23:00"
  }
}

## The On-Prem machines are simulated for my lab, in reality on-premise systems cannot be configured like this, but will instead use the MARS agent.
resource "azurerm_backup_protected_vm" "On-Prem-DC" {
  resource_group_name = azurerm_resource_group.rg_Security.name
  recovery_vault_name = azurerm_recovery_services_vault.BackupVault.name
  source_vm_id        = azurerm_virtual_machine.On-Prem-DC.id
  backup_policy_id    = azurerm_backup_policy_vm.BackupPolicy.id
}

resource "azurerm_backup_protected_vm" "On-Prem-ADC" {
  resource_group_name = azurerm_resource_group.rg_Security.name
  recovery_vault_name = azurerm_recovery_services_vault.BackupVault.name
  source_vm_id        = azurerm_virtual_machine.On-Prem-ADC.id
  backup_policy_id    = azurerm_backup_policy_vm.BackupPolicy.id
}

resource "azurerm_backup_protected_vm" "DC" {
  resource_group_name = azurerm_resource_group.rg_Security.name
  recovery_vault_name = azurerm_recovery_services_vault.BackupVault.name
  source_vm_id        = azurerm_virtual_machine.DC.id
  backup_policy_id    = azurerm_backup_policy_vm.BackupPolicy.id
}

resource "azurerm_backup_protected_vm" "ManagementVM0" {
  resource_group_name = azurerm_resource_group.rg_Security.name
  recovery_vault_name = azurerm_recovery_services_vault.BackupVault.name
  source_vm_id        = azurerm_virtual_machine.ManagementVM0.id
  backup_policy_id    = azurerm_backup_policy_vm.BackupPolicy.id
}