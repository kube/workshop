terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-backend"
    storage_account_name = "kubeworkshoptfstate"
    container_name       = "prod"
    key                  = "terraform.tfstate"
    use_oidc             = true
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
  use_oidc        = true
}

resource "azurerm_resource_group" "app" {
  # TODO: Use variable interpolation for environment
  name     = "rg-kubeworkshop-prod-weu"
  location = "West Europe"
}

resource "azurerm_container_app_environment" "app" {
  # TODO: Use variable interpolation for environment
  name                = "kubeworkshop-env-prod-weu"
  location            = azurerm_resource_group.app.location
  resource_group_name = azurerm_resource_group.app.name
}

resource "azurerm_container_app" "app" {
  # TODO: Use variable interpolation for environment
  name                         = "kubeworkshop-frontend-prod-weu"
  container_app_environment_id = azurerm_container_app_environment.app.id
  resource_group_name          = azurerm_resource_group.app.name
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
