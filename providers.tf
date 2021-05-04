terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.52.0"
    }
  }
  backend "azurerm" {
  storage_account_name = "stagesientfstate"
  container_name = "tfstatedevops"
  key = "tf/terraform.tfstate"
  access_key = "XXXX"
  }
}


# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
  subscription_id = "XXXX"
}

