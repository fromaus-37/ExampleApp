@description('Name for the container group')
param name string

@description('prefix of the container group\'s fully qualified domain name for the container group')
param dnsNameLabel string

@description('URL of the registry from which MVC app Docker image is to be pulled.')
param mvcRegistryServer string

@description('Full URI of the user-assigned  managed identity resource that has permissions to pull from the specified registry of the MVC app Docker image')
param managedIdentityForMvcRegistry string

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
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityForMvcRegistry}': {}
    }
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
    imageRegistryCredentials: [
      {
        server: mvcRegistryServer
        identity: managedIdentityForMvcRegistry
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

output containerIPv4Address string = containerGroup.properties.ipAddress.ip
