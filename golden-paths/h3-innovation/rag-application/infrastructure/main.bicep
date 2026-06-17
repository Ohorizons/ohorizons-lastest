@description('Application name used for Azure resource naming.')
param appName string = '${{ values.appName }}'

@description('Azure location for RAG infrastructure.')
param location string = resourceGroup().location

@description('Azure AI Search SKU.')
@allowed([
  'basic'
  'standard'
  'standard2'
  'standard3'
])
param searchSku string = '${{ values.searchTier }}'

@description('Tags applied to all resources.')
param tags object = {
  project: appName
  component: 'rag-application'
  managedBy: 'open-horizons'
}

var normalizedName = toLower(replace(appName, '-', ''))
var storageName = take('${normalizedName}ragst', 24)
var searchName = take('${appName}-search', 60)
var appInsightsName = '${appName}-appi'

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

resource documentsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  name: '${storage.name}/default/documents'
  properties: {
    publicAccess: 'None'
  }
}

resource search 'Microsoft.Search/searchServices@2023-11-01' = {
  name: searchName
  location: location
  tags: tags
  sku: {
    name: searchSku
  }
  properties: {
    hostingMode: 'default'
    partitionCount: 1
    replicaCount: 1
    publicNetworkAccess: 'enabled'
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

output storageAccountName string = storage.name
output documentsContainerName string = documentsContainer.name
output searchServiceName string = search.name
output applicationInsightsName string = appInsights.name
