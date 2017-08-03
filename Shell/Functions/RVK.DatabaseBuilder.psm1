function Install-DatabaseObject
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [String] $ServerInstance 
    ,   
        [Parameter(Mandatory=$true)]
        [String] $Database
    ,   
        [Parameter(Mandatory=$true)]
        [String] $ObjectTypeName
    ,   
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [String] $Path
    )

    Begin 
    {
        Set-StrictMode -Version Latest
        Write-Verbose "Install-DatabaseObject -ServerInstance $ServerInstance -Database $Database -ObjectTypeName $ObjectTypeName"
        $FailedPaths = [string[]] @()
        $NumSucceeded = 0
        $NumFailed = 0
        try 
        {
            $InstanceValid = Test-SQLServerInstance -ServerInstance $ServerInstance
            if(-not $InstanceValid)
            {
                throw "'$ServerInstance' is not a valid SQL Server Instance"
            }

            $DatabaseValid = Test-SQLServerDatabase -ServerInstance $ServerInstance -Database $Database
            if(-not $DatabaseValid)
            {
                throw "'$Database' is not a valid database on '$ServerInstance'"
            }
        }
        catch
        {
            Write-Error $_.Exception
            break
        }
    }
    Process 
    {
        try
        {
            Write-Verbose "Creating $ObjectTypeName by running script $Path"
            # Invoke-Sqlcmd2 cannot process GOs and TSQL requires DROP statements to be executed in separate batches from CREATEs
            # So we need to split the file into sections separated by GOs
            $Queries = [regex]::Split((Get-Content $Path -Raw), "(?m)^\s*GO\s*$") | Where-Object {$_ -ne ""}
                # Regex pattern explanation: 
                # (?m) changes the meaning of ^ and $ so that they make the pattern match at the beginning and end of each line in the string, not the beginning and end of the whole string
                # ^ makes the pattern match only GOs at the beginning of the line
                # $ makes the pattern match only GOs at the end of the line
                # ^GO$ then matches only GOs which are on their own line. This is necessary if we want to avoid splitting on words like 'algorithm' which contain the substring 'go' 
            foreach($Query in $Queries)
            {
                Invoke-Sqlcmd2 -ServerInstance $ServerInstance -Database $Database -Query $Query -ErrorAction Stop 
            }
            $NumSucceeded++
        }
        catch
        {
            Write-Error -Message $_.Exception.Message
            $FailedPaths += $Path
            $NumFailed++
        }
    }
    End
    {
        if($NumFailed -eq 0)
        {
            Write-Verbose "Install-DatabaseObject succeeded on all $NumSucceeded paths"
        }
        else
        {
            Write-Verbose "Install-DatabaseObject succeeded on $NumSucceeded paths, but failed on $NumFailed paths."
            Write-Verbose "The failed paths are as follows:`n$($FailedPaths -join "`n")"
        }
    }
}

function New-Database
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [String] $ServerInstance 
    ,   
        [Parameter(Mandatory=$true)]
        [String] $Database

    ,   [Switch] $AppendGuid
    )

    try 
    {
        Write-Verbose "New-Database -ServerInstance $ServerInstance -Database $Database -AppendGuid=$($AppendGuid.IsPresent)"
        if($AppendGuid)
        {
            $guid = (New-Guid |
                    Select-Object -ExpandProperty guid) -replace "-",  ""
            Write-Verbose "Appending GUID to database name" 
            $Database = ($Database + "_" + (guid -NoDash))
            Write-Verbose "New database name: $Database"
        }
        
        Write-Verbose "Creating database $Database on SQL Server instance $ServerInstance..."
        Invoke-Sqlcmd2 -ServerInstance $ServerInstance -Database master -Query "CREATE DATABASE $Database;" -ErrorAction Stop
        
        Write-Verbose "New-Database succeeded"

        Write-Output $Database
    }
    catch 
    {
        Write-Verbose "New-Database failed."
        throw $_.Exception.Message 
    }
}

function Remove-Database 
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [String] $ServerInstance
    ,
        [Parameter(Mandatory=$true)]
        [String] $Database
    )

    $ConnectionParams = @{
        ServerInstance=$ServerInstance;
        Database=$Database; 
    }

    try
    {
        Write-Verbose "Remove-Database -ServerInstance $ServerInstance -Database $Database"

        if($Database -in @("tempdb", "msdb", "model", "master"))
        {
            throw "System database '$Database' cannot be removed."
        }
    
        Write-Verbose "Testing whether database is valid"
        if(-not (Test-SQLServerDatabase @ConnectionParams))
        {
            throw "Database '$Database' does not exist on SQL Server Instance '$ServerInstance'"
        }
    
        Write-Verbose "Attempting to drop database"
        [String] $Query = "
                            BEGIN
                                ALTER DATABASE [$Database]
                                SET SINGLE_USER
                                WITH ROLLBACK IMMEDIATE;

                                DROP DATABASE [$Database];
                            END;
                          "

        Invoke-Sqlcmd2 -ServerInstance $ServerInstance -Database master -Query $Query -ErrorAction Stop | Out-Null
        Write-Verbose "Remove-Database succeeded"
    }
    catch
    {
        Write-Verbose "Remove-Database failed."
        throw $_.Exception.Message 
    }
    
    Write-Verbose "Exiting Remove-Database"
}

