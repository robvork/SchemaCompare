Import-Module RVK.SchemaCompare -Force 

[string] $ServerInstance = "ASPIRING\SQL16"
[string] $Database = "SchemaCompare"
[bool] $UseForce = $true

Install-SchemaCompare -ServerInstance $ServerInstance -Database $Database -Force:($UseForce) -Verbose

