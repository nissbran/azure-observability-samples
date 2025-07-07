locals {
  custom_tables = [
    {
      name = "ApplicationJsonLogs_CL",
      schema = {
        columns = [
          {
            name        = "TimeGenerated"
            type        = "datetime"
            displayName = "TimeGenerated"
            description = "Time when event was generated"
          },
          {
            name        = "Timestamp"
            type        = "datetime"
            displayName = "Timestamp"
            description = "Time when log written in the logs"
          },
          {
            name        = "Level"
            type        = "string"
            displayName = "Level"
            description = "Log level"
          },
          {
            name        = "Message"
            type        = "string"
            displayName = "Message"
            description = "Log message"
          },
          {
            name        = "Properties"
            type        = "dynamic"
            displayName = "Properties"
            description = "Log properties"
          }
        ]
        displayName = "ApplicationJsonLogs"
        description = "Application Json Logs"
        name        = "ApplicationJsonLogs_CL"
      },
      retention_in_days       = null,
      total_retention_in_days = 30
      plan                    = "Basic"
    }
  ]
}

resource "azurerm_resource_group" "log_analytics" {
  name     = "rg-log-analytics-demo"
  location = "swedencentral"
}

resource "azurerm_log_analytics_workspace" "log_analytics" {
  name                = "law-demo"
  location            = azurerm_resource_group.log_analytics.location
  resource_group_name = azurerm_resource_group.log_analytics.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azapi_resource" "application_logs" {
  name      = "ApplicationJsonLogs_CL"
  parent_id = azurerm_log_analytics_workspace.log_analytics.id
  type      = "Microsoft.OperationalInsights/workspaces/tables@2022-10-01"
  body = {
    properties = {
      schema = {
        columns = [
          {
            name        = "TimeGenerated"
            type        = "datetime"
            displayName = "TimeGenerated"
            description = "Time when event was generated"
          },
          {
            name        = "Timestamp"
            type        = "datetime"
            displayName = "Timestamp"
            description = "Time when log written in the logs"
          },
          {
            name        = "Level"
            type        = "string"
            displayName = "Level"
            description = "Log level"
          },
          {
            name        = "Message"
            type        = "string"
            displayName = "Message"
            description = "Log message"
          },
          {
            name        = "Properties"
            type        = "dynamic"
            displayName = "Properties"
            description = "Log properties"
          }
        ]
        displayName = "ApplicationJsonLogs"
        description = "Application Json Logs"
        name        = "ApplicationJsonLogs_CL"
      }
      retentionInDays      = null,
      totalRetentionInDays = 30
      plan                 = "Basic"
    }
  }
  lifecycle {
    ignore_changes = all
  }
}

resource "azapi_resource" "application_aux_logs" {
  name      = "ApplicationJsonLogsAux_CL"
  parent_id = azurerm_log_analytics_workspace.log_analytics.id
  type      = "Microsoft.OperationalInsights/workspaces/tables@2023-01-01-preview"
  body = {
    properties = {
      schema = {
        columns = [
          {
            name        = "TimeGenerated"
            type        = "datetime"
            displayName = "TimeGenerated"
            description = "Time when event was generated"
          },
          {
            name        = "Timestamp"
            type        = "datetime"
            displayName = "Timestamp"
            description = "Time when log written in the logs"
          },
          {
            name        = "Level"
            type        = "string"
            displayName = "Level"
            description = "Log level"
          },
          {
            name        = "Message"
            type        = "string"
            displayName = "Message"
            description = "Log message"
          }
        ]
        displayName = "ApplicationJsonLogsAux"
        description = "Application Json Logs"
        name        = "ApplicationJsonLogsAux_CL"
      }
      retentionInDays      = null,
      totalRetentionInDays = 30
      plan                 = "Auxiliary"
    }
  }
  lifecycle {
    ignore_changes = all
  }
  schema_validation_enabled = false
}

provider "azurerm" {
  features {}        
  subscription_id = "00000000-0000-0000-0000-000000000000" # Replace with your Azure subscription ID
}


# resource "azapi_resource" "custom_tables" {
#   for_each  = { for v in local.custom_tables : v.name => v }
#   name      = each.key
#   parent_id = azurerm_log_analytics_workspace.log_analytics.id
#   type      = "Microsoft.OperationalInsights/workspaces/tables@2022-10-01"
#   body = {
#     properties = {
#       schema               = each.value.schema
#       retentionInDays      = each.value.retention_in_days
#       totalRetentionInDays = each.value.total_retention_in_days
#       plan                 = each.value.plan
#     }
#   }
#   lifecycle {
#     ignore_changes = all
#   }
# }