metadata description = 'Creates an Azure SQL Server instance.'

param name string
param location string = resourceGroup().location
param tags object = {}
param databaseName string
param principalId string

param sqlAdmin string = 'SqlAdmin'
@secure()
param sqlAdminPassword string

param appUser string = 'AppUser' 
@secure()
param appUserPassword string

resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: name
  location: location
  tags: tags
  properties: {
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
    administratorLogin: sqlAdmin
    administratorLoginPassword: sqlAdminPassword
  }

  resource database 'databases' = {
    name: databaseName
    location: location
  }

  resource firewall 'firewallRules' = {
    name: 'Azure Services'
    properties: {
      // Allow all clients
      // Note: range [0.0.0.0-0.0.0.0] means "allow all Azure-hosted clients only".
      // This is not sufficient, because we also want to allow direct access from developer machine, for debugging purposes.
      startIpAddress: '0.0.0.0'
      endIpAddress: '0.0.0.0'
    }
  }

  resource symbolicname 'administrators@2022-05-01-preview' = {
    name: 'ActiveDirectory'
    properties: {
      administratorType: 'ActiveDirectory'
      login: 'EntraAdmin'
      sid: principalId
      tenantId: tenant().tenantId
    }
  }
}

resource createDBScript2 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: '${name}-createDB-script'
  location: location
  kind: 'AzurePowerShell'
  properties: {
    azPowerShellVersion: '10.0'
    retentionInterval: 'PT1H' // Retain the script resource for 1 hour after it ends running
    timeout: 'PT5M' // Five minutes
    cleanupPreference: 'OnSuccess'
    environmentVariables: [           
      {
        name: 'DBNAME'
        value: databaseName
      }
      {
        name: 'DBSERVER'
        value: sqlServer.properties.fullyQualifiedDomainName
      }
      {
        name: 'SQLCMDPASSWORD'
        secureValue: sqlAdminPassword
      }
      {
        name: 'SQLADMIN'
        value: sqlAdmin
      }
      {
        name: 'APP_USER_PASSWORD'
        secureValue: appUserPassword
      }
    ]
    scriptContent: loadTextContent('../../database/setup-database.ps1')  
  }
}

var connectionString = 'Server=${sqlServer.properties.fullyQualifiedDomainName};Database=${sqlServer::database.name};User=${appUser}'
output connectionString string = connectionString
output databaseName string = sqlServer::database.name
output name string = sqlServer.name
output id string = sqlServer.id
