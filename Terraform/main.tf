terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "projectName" {
  type = string
}

variable "location" {
  type    = string
  default = "NorthEurope"
}

resource "random_string" "suffix" {
  length = 5
  special = false
}

locals {
  workspaceName      = "${var.projectName}-ws-${random_string.suffix.result}"
  appInsightsName    = "${var.projectName}-ai-${random_string.suffix.result}"
  storageAccountName = lower(replace("${var.projectName}${random_string.suffix.result}", "-", ""))
  appSvcPlanName     = "${var.projectName}-svc-plan-${random_string.suffix.result}"
  webAppName         = "${var.projectName}-web-${random_string.suffix.result}"
}

resource "azurerm_resource_group" "rg" {
  name     = var.projectName
  location = var.location
}

resource "azurerm_log_analytics_workspace" "laws" {
  name                = local.workspaceName
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
}

resource "azurerm_application_insights" "appInsights" {
  name                = local.appInsightsName
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.laws.id
}

resource "azurerm_storage_account" "storageAccount" {
  name                     = local.storageAccountName
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_service_plan" "appSvcPlan" {
  name                = local.appSvcPlanName
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "B1"
  worker_count        = 1
}

resource "azurerm_linux_web_app" "webApp" {
  name                = local.webAppName
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.appSvcPlan.id
  https_only          = true
  site_config {
    minimum_tls_version = "1.2"
  }
  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.appInsights.instrumentation_key
  }
  connection_string {
    type  = "Custom"
    name  = "Storage"
    value = azurerm_storage_account.storageAccount.primary_blob_connection_string
  }
}

output "website_url" {
  value = "https://${azurerm_linux_web_app.webApp.default_hostname}/"
}