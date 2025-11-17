// This module creates an RBAC Role Assignment
// Grants permissions for identities to access resources
// Reference: https://learn.microsoft.com/en-us/azure/role-based-access-control/

@description('The principal ID to assign the role to')
param principalId string

@description('The ID of the role definition to assign (built-in role ID)')
@allowed([
  '7f951dda-4ed3-4680-a7ca-43fe172d538d' // AcrPull
  'b24988ac-6180-42a0-ab88-20f7382dd24c' // Contributor
  'acdd72a7-3385-48ef-bd42-f606fba81ae7' // Reader
])
param roleDefinitionId string

@description('Principal type of the principal ID')
@allowed([
  'ServicePrincipal'
  'User'
  'Group'
  'Device'
  'ForeignGroup'
])
param principalType string = 'ServicePrincipal'

@description('Scope for the role assignment (resource group or specific resource ID)')
param scope string = resourceGroup().id

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(scope, principalId, roleDefinitionId)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${roleDefinitionId}'
    principalId: principalId
    principalType: principalType
  }
}

@description('The resource ID of the role assignment')
output assignmentId string = roleAssignment.id

@description('AcrPull role ID (pull images from ACR)')
output acrPullRoleId string = '7f951dda-4ed3-4680-a7ca-43fe172d538d'

@description('Contributor role ID')
output contributorRoleId string = 'b24988ac-6180-42a0-ab88-20f7382dd24c'

@description('Reader role ID')
output readerRoleId string = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
