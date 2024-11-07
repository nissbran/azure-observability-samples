param location string
param nameSuffix string

resource amw_workspace 'Microsoft.Monitor/accounts@2023-04-03' = {
  name: 'amw-${nameSuffix}'
  location: location 
}

output amwWorkspaceId string = amw_workspace.id
output amwWorkspaceName string = amw_workspace.name
