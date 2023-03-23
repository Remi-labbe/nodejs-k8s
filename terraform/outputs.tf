output "main-rg-name" {
  value = data.azurerm_resource_group.rg.name
}

output "main-rg-id" {
  value = azurerm_postgresql_server.pg-srv.fqdn
}
