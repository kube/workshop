terraform {
  backend "azurerm" {
    resource_group_name  = "example-resources"
    storage_account_name = "examplestorage0kubekhrm"
    container_name       = "mytfstate"
    key                  = "terraform.tfstate"
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.18.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "08d3d1e9-154b-4352-bb01-febf59622d0a"
}

resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "West Europe"
}

resource "azurerm_log_analytics_workspace" "example" {
  name                = "example-law"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "PerGB2018"
}

resource "azurerm_container_app_environment" "example" {
  name                = "example-aca-env"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_container_registry" "example" {
  name                = "exampleacr"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_container_app" "example" {
  name                         = "example-aca"
  container_app_environment_id = azurerm_container_app_environment.example.id
  resource_group_name          = azurerm_resource_group.example.name
  revision_mode                = "Single"

  template {
    container {
      name   = "workshop-container"
      image  = "ghcr.io/kube/workshop:latest"
      cpu    = "0.5"
      memory = "1.0Gi"
    }
  }
}
