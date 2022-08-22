param projectName string
param location string = resourceGroup().location

var suffix = uniqueString(resourceGroup().id)
var workspaceName = '${projectName}-ws-${suffix}'
var appInsightsName = '${projectName}-ai-${suffix}'
var storageAccountName = toLower('${replace(projectName, '-', '')}${suffix}')
var appSvcPlanName = '${projectName}-plan-${suffix}'
var webAppName = '${projectName}-web-${suffix}'

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appSvcPlanName
  location: location
  kind: 'linux'
  sku: {
    name: 'B1'
    capacity: 1
  }
  properties: {
    reserved: true
  }
}

resource appService 'Microsoft.Web/sites@2022-03-01' = {
  name: webAppName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      minTlsVersion: '1.2'
      appSettings: [
        { name: 'APPINSIGHTS_INSTRUMENTATIONKEY', value: applicationInsights.properties.InstrumentationKey }
      ]
      connectionStrings: [
        {
          type: 'Custom'
          name: 'Storage'
          connectionString: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'
        }
      ]
    }
  }
}

output websiteUrl string = 'https://${appService.properties.defaultHostName}/'
