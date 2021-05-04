# Hybrid IT Management Framework code repository

Welcome to the code repository of the Hybrid IT Management Framework project. 

In this repository you will find the following files:

* **on-prem-env.tf**: Terraform file to create resources to simulate an on-premises environment
* **shared-env.tf**: Terraform file to create resources for an Azure shared virtual environment
* **spokes-env.tf**: Terraform file to create resources for Azure spoke environmen
* **providers.tf**: Terraform file to declare the providers to be used
* files/
    * **winrm[*].ps1**: Initial configurations that will be deployed to machines
    * **FirstLogonCommands.xml**: File that deploys initial configurations to machines
* additional-confis/
    * **Configure.ps1**: Additional configurations in the form of PowerShell scripts
    * **CSR.ps1**: PowerShell script to request SSL certificates
    * **WAC.ps1**: PowerShell script to deploy Windows Admin Center in high availability mode on a clustered set
