SUBSCRIPTION_ID="<replace-this>"

az ad sp create-for-rbac \
 --name sp-terraform \
 --role Contributor \
 --scopes /subscriptions/$SUBSCRIPTION_ID

TERRAFORM_SP_OBJECT_ID="<replace-this>" # use the values returned by previous command

az role assignment create 
 --role "Role Based Access Control Administrator" 
 --scope /subscriptions/$SUBSCRIPTION_ID
 --assignee-object-id $TERRAFORM_SP_OBJECT_ID 
 --assignee-principal-type ServicePrincipal
 --description "Role assignment for Terraform SP to assign ACR Pull to SPs"
 --condition "((!(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})) OR (@Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {7f951dda-4ed3-4680-a7ca-43fe172d538d} AND @Request[Microsoft.Authorization/roleAssignments:PrincipalType] ForAnyOfAnyValues:StringEqualsIgnoreCase {'ServicePrincipal'})) AND ((!(ActionMatches{'Microsoft.Authorization/roleAssignments/delete'})) OR (@Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {7f951dda-4ed3-4680-a7ca-43fe172d538d} AND @Resource[Microsoft.Authorization/roleAssignments:PrincipalType] ForAnyOfAnyValues:StringEqualsIgnoreCase {'ServicePrincipal'}))"
 --condition-version "2.0"