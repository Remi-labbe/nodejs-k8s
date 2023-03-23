terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.48.0"
    }
  }
  backend "azurerm" {
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_postgresql_server" "pg-srv" {
  name                = "pg-srv-${var.project_name}${var.environment_suffix}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  sku_name = "B_Gen5_2"

  storage_mb                   = 5120
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled            = true

  administrator_login              = data.azurerm_key_vault_secret.pg-login.value
  administrator_login_password     = data.azurerm_key_vault_secret.pg-password.value
  version                          = "9.5"
  ssl_enforcement_enabled          = false
  ssl_minimal_tls_version_enforced = "TLSEnforcementDisabled"
}

resource "azurerm_postgresql_firewall_rule" "pg-firewall" {
  name                = "pg-firewall"
  resource_group_name = data.azurerm_resource_group.rg.name
  server_name         = azurerm_postgresql_server.pg-srv.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

resource "azurerm_postgresql_database" "pg-db" {
  name                = "pg-db"
  resource_group_name = data.azurerm_resource_group.rg.name
  server_name         = azurerm_postgresql_server.pg-srv.name
  charset             = "UTF8"
  collation           = "English_United States.1252"
}

resource "azurerm_service_plan" "sp" {
  name                = "sp-${var.project_name}${var.environment_suffix}"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "S1"
}

resource "azurerm_linux_web_app" "lwa" {
  name                = "lwa-${var.project_name}${var.environment_suffix}"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = azurerm_service_plan.sp.location
  service_plan_id     = azurerm_service_plan.sp.id

  site_config {
    application_stack {
      node_version = "16-lts"
    }
  }

  app_settings = {
    PORT                      = var.api_port
    DB_HOST                   = azurerm_postgresql_server.pg-srv.fqdn
    DB_USERNAME               = "${data.azurerm_key_vault_secret.pg-login.value}@${azurerm_postgresql_server.pg-srv.name}"
    DB_PASSWORD               = data.azurerm_key_vault_secret.pg-password.value
    DB_DATABASE               = azurerm_postgresql_database.pg-db.name
    DB_DAILECT                = "postgres"
    DB_PORT                   = 5432
    ACCESS_TOKEN_SECRET       = data.azurerm_key_vault_secret.access-token-secret.value
    REFRESH_TOKEN_SECRET      = data.azurerm_key_vault_secret.refresh-token-secret.value
    ACCESS_TOKEN_EXPIRY       = var.access_token_expiry
    REFRESH_TOKEN_EXPIRY      = var.refresh_token_expiry
    REFRESH_TOKEN_COOKIE_NAME = var.refresh_token_cookie_name
  }
}

resource "azurerm_container_group" "pgadmin" {
  name                = "aci-pgadmin-${var.project_name}${var.environment_suffix}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  ip_address_type     = "Public"
  dns_name_label      = "aci-pgadmin-${var.project_name}${var.environment_suffix}"
  os_type             = "Linux"

  container {
    name   = "pgadmin"
    image  = "dpage/pgadmin4"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 80
      protocol = "TCP"
    }

    environment_variables = {
      PGADMIN_DEFAULT_EMAIL    = data.azurerm_key_vault_secret.pgadmin-login.value
      PGADMIN_DEFAULT_PASSWORD = data.azurerm_key_vault_secret.pgadmin-password.value
    }
  }
}
