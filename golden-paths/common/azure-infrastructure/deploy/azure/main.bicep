@description('Application or component name.')
param name string = '${{ values.name }}'

@description('Deployment environment.')
@allowed([
  'dev'
  'staging'
  'prod'
])
param environment string = '${{ values.environment }}'

@description('Azure region for generated infrastructure.')
param location string = '${{ values.azureRegion }}'

@description('Workload classification used for tagging.')
param workloadType string = '${{ values.workloadType }}'

@description('Resource tags.')
param tags object = {
  project: name
  environment: environment
  owner: 'platform-engineering'
  managedBy: 'open-horizons-golden-path'
  workloadType: workloadType
}

var normalizedName = toLower(replace(replace(name, '-', ''), '_', ''))
var safeName = take(normalizedName, 18)
var storageName = take('st${safeName}${environment}', 24)
var appInsightsName = '${name}-${environment}-appi'
var logAnalyticsName = '${name}-${environment}-law'

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
  }
}

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
}

output applicationInsightsName string = appInsights.name
output logAnalyticsWorkspaceName string = logAnalytics.name
output storageAccountName string = storage.name