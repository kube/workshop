terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-backend"
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

data "azurerm_key_vault" "example" {
  name                = "kv-terraform-kubekhrm"
  resource_group_name = "rg-terraform-backend"
}

data "azurerm_key_vault_secret" "docker_username" {
  name         = "docker-user"
  key_vault_id = data.azurerm_key_vault.example.id
}

data "azurerm_key_vault_secret" "docker_password" {
  name         = "docker-password"
  key_vault_id = data.azurerm_key_vault.example.id
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

resource "azurerm_container_group" "aci" {
  name                = "kubeworkshop-cg-frontend-prod-weu"
  resource_group_name = azurerm_resource_group.app.name
  location            = azurerm_resource_group.app.location
  os_type             = "Linux"

  ip_address_type = "Public"
  dns_name_label  = "kubeworkshop-frontend-prod-weu"

  container {
    name   = "caddy-reverse-proxy"
    image  = "ghcr.io/kube/workshop:caddy"
    cpu    = "0.5"
    memory = "1.0"

    ports {
      port     = 80
      protocol = "TCP"
    }
    ports {
      port     = 443
      protocol = "TCP"
    }
  }

  container {
    # TODO: Use variable interpolation for environment
    name   = "kubeworkshop-frontend-prod-weu"
    image  = "ghcr.io/kube/workshop:latest"
    cpu    = "0.5"
    memory = "1.0"
  }

  image_registry_credential {
    server   = "index.docker.io"
    username = data.azurerm_key_vault_secret.docker_username.value
    password = data.azurerm_key_vault_secret.docker_password.value
  }
}
