# 1) Connect-AzAccount
# 2) Set-AzContext -Subscription <subscription-id-here>
param(
[Parameter(Mandatory = $true)]
[string]
$LAresourceGroups,
[string]
$CONresourceGroup,
[string]
$CONlocation,
[string]
$tenantId
)

$connections = Get-AzResource -ResourceGroupName $CONresourceGroup -ResourceType Microsoft.Web/connections
$logic=$null
foreach($resourceGroup in  $LAresourceGroups.Split(","))
{
$logic+=Get-AzResource -ResourceGroupName $resourceGroup -ResourceType Microsoft.Web/sites
}

$logic.Name

foreach ($la in $($logic | where {$_.Kind -eq "functionapp,workflowapp"}))
{
    $objectid=$null
    write-host 'processing ' $la.name
    $objectid = (Get-AzResource -Name $la.Name).Identity.PrincipalId;




    foreach ($con in $connections)
    {
        write-host 'adding ' $con.name 'connection to '$la.name
            $name = $null
            $name = $con.name + '/' +$objectid
            $Properties  = @{
            principal = @{
                type = "ActiveDirectory"
                identity = @{
                    tenantId = $tenantId
                    objectId = $objectid
                    }
                }
            }

        New-AzResource -Location $CONlocation -ResourceGroup $CONresourceGroup -ResourceType "Microsoft.Web/connections/accessPolicies" -ResourceName $Name -Properties $Properties -force

    }
}

