targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

// Identity
@description('Id of the user or app to assign application roles')
param principalId string

// Azure SQL
@secure()
@description('SQL Server administrator password')
param sqlAdminPassword string
@secure()
@description('Application user password')
param appUserPassword string
@description('Database name')
param dbName string = 'sampledb'

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }
var rgName = 'rg-${environmentName}'

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgName
  location: location
  tags: tags
}

module database 'app/sqlserver.bicep' = {
  name: 'database'
  scope: rg
  params: {
    tags: tags
    location: location
    appUserPassword: appUserPassword
    sqlAdminPassword: sqlAdminPassword
    databaseName: dbName
    name: '${abbrs.sqlServers}catalog-${resourceToken}'
    principalId: principalId
  }
}

output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
