@description('Name for the container group')
param name string

@description('prefix of the container group\'s fully qualified domain name for the container group')
param dnsNameLabel string

@description('Name of the container registry')
param mvcRegistryName string

@description('MVC application image URI. Images from private registries require additional registry credentials.')
param mvcImage string

@description('sa account password for SQL Server. This needs to be provided when creating container from SQL Server image')
@secure()
param sqlServerSAPassword string

@description('connection string that MVC app will use to access the SQL Server in other container')
@secure()
param sqlServerConnectionString string

@description('Port to open on the container and the public IP address.')
param port int

@description('The behavior of Azure runtime if container has stopped.')
@allowed([
  'Always'
  'Never'
  'OnFailure'
])
param restartPolicy string = 'Always'

@description('Location for all resources.')
param location string = resourceGroup().location

resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2021-09-01' = {
  name: name
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    containers: [
      {
        name: 'sqlserver'
        properties: {
          image: 'mcr.microsoft.com/mssql/server:2019-latest'

          environmentVariables: [
            {
              name: 'ACCEPT_EULA'
              value: 'Y'
            }
            {
              name: 'SA_PASSWORD'
              secureValue: sqlServerSAPassword
            }
          ]

          resources: {
            requests: {
              cpu: 1
              memoryInGB: 4
            }
          }
        }
      }

      {
        name: 'mvc'
        properties: {
          image: mvcImage
          ports: [
            {
              port: port
              protocol: 'TCP'
            }
          ]
          environmentVariables: [
            {
              name: 'ConnectionStrings__ProductDB'
              secureValue: sqlServerConnectionString
            }
          ]
          resources: {
            requests: {
              cpu: 1
              memoryInGB: 4
            }
          }
        }
      }
    ]

    osType: 'Linux'
    restartPolicy: restartPolicy
    ipAddress: {
      type: 'Public'
      ports: [
        {
          port: port
          protocol: 'TCP'
        }
      ]
      dnsNameLabel: dnsNameLabel
    }
  }
}

// resource acrResource 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' = {
//   dependsOn: [ containerGroup ]
//   name: mvcRegistryName
//   location: location
//   sku: {
//     name: mvcRegistrySku
//   }

// }

resource mvcRegistry 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' existing = {
  name: mvcRegistryName
}

@description('This is the built-in acrpull role. Built-inroles are subscription scoped resources')
resource acrpullRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
}

resource mvcRegistryRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: mvcRegistry
  name: guid(mvcRegistry.id, containerGroup.id, acrpullRoleDefinition.id)
  properties: {
    roleDefinitionId: acrpullRoleDefinition.id
    principalId: containerGroup.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

output containerIPv4Address string = containerGroup.properties.ipAddress.ip
