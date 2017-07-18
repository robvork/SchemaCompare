function Initialize-SchemaCompareDB
{
    <#
        .SYNOPSIS
        Creates the SchemaCompare DB and initializes it with generic values

        .DESCRIPTION
        Creates the SchemaCompare DB on the specified SQL Server Instance with the specified name.
        Then creates the following in the order shown:
        1. Schemas
        2. Types
        3. Tables
        4. Foreign Keys
        5. Functions
        6. Procedures

        .PARAMETER ServerInstance
        The SQL Server Instance hosting Database

        .PARAMETER Database
        The SQL Server database of SchemaCompare
    #>
    [CmdletBinding()]
    param
    (
        [String] $ServerInstance
    ,   [String] $Database
    ,   [String[]] $CreateSchemaScripts
    ,   [String[]] $CreateUDDTScripts
    ,   [String[]] $CreateTableScripts
    ,   [String[]] $CreateForeignKeyScripts
    ,   [String[]] $CreateProcedureScripts
    ,   [String[]] $CreateFunctionScripts
    )

    try
    {
        # Store connection parameters for uniform and concise use across this function
        $ConnectionParams = @{
            ServerInstance = $ServerInstance;
            Database = $Database; 
        }

        # Create DB
        # TODO: Prompt user to confirm database drop if it exists
        $CreateDBSQL = "IF EXISTS(SELECT * FROM sys.databases WHERE [name] = '$Database')
                        BEGIN
                            ALTER DATABASE [$Database]
                            SET SINGLE_USER
                            WITH ROLLBACK IMMEDIATE;

                            DROP DATABASE [$Database];
                        END;
                        GO

                        CREATE DATABASE [$Database];"
                        
        Write-Verbose "Creating database '$Database' on SQL Server instance '$ServerInstance'"
        Invoke-Sqlcmd -ServerInstance $ServerInstance -Database master -Query $CreateDBSQL -ErrorAction Stop
        Write-Verbose "Database creation SUCCESS"

        # Create schemas
        Write-Verbose "Creating schemas"
        foreach($csScript in $CreateSchemaScripts)
        {
            Write-Verbose "Creating schema by running '$csScript'"
            Invoke-Sqlcmd @ConnectionParams -InputFile $csScript -ErrorAction Stop
            Write-Verbose "Schema created successfully"
        }
        Write-Verbose "Schema creation SUCCESS"

        #Create UDDTs
        Write-Verbose "Creating user-defined data types"
        foreach($cuddtScript in $CreateUDDTScripts)
        {
            Write-Verbose "Creating user-defined data type by running '$cuddtScript'"
            Invoke-Sqlcmd @ConnectionParams -InputFile $cuddtScript -ErrorAction Stop 
            Write-Verbose "User-defined data type created successfully"
        }
        Write-Verbose "User-defined data type creation SUCCESS"

        #Create tables
        Write-Verbose "Creating tables"
        foreach($ctScript in $CreateTableScripts)
        {
            Write-Verbose "Creating table by running '$ctScript'"
            Invoke-Sqlcmd @ConnectionParams -InputFile $ctScript -ErrorAction Stop 
            Write-Verbose "Table created successfully"
        }
        Write-Verbose "Table creation SUCCESS"

        #Create foreign keys
        Write-Verbose "Creating foreign keys"
        foreach($cfkScript in $CreateForeignKeyScripts)
        {
            Write-Verbose "Creating foreign key by running '$cfkScript'"
            Invoke-Sqlcmd @ConnectionParams -InputFile $cfkScript -ErrorAction Stop 
            Write-Verbose "Table created successfully"
        }
        Write-Verbose "Foreign key creation SUCCESS"

        #Create procedures
        Write-Verbose "Creating procedures"
        foreach($cpScript in $CreateProcedureScripts)
        {
            Write-Verbose "Creating procedure by running '$cpScript'"
            Invoke-Sqlcmd @ConnectionParams -InputFile $cpScript -ErrorAction Stop 
            Write-Verbose "Procedure created successfully"
        }
        Write-Verbose "Procedure creation SUCCESS"

        #Create functions
        Write-Verbose "Creating functions"
        foreach($cfScript in $CreateFunctionScripts)
        {
            Write-Verbose "Creating procedure by running '$cfScript'"
            Invoke-Sqlcmd @ConnectionParams -InputFile $cfScript -ErrorAction Stop 
            Write-Verbose "Function created successfully"
        }
        Write-Verbose "Function creation SUCCESS"

        #Initialize IDs
        Write-Verbose "Initializing IDs"
        Initialize-SchemaCompareIDGenerator @ConnectionParams
        Write-Verbose "ID initialization SUCCESS"

        #Initialize object classes
        Write-Verbose "Initializing object classes"
        Initialize-SchemaCompareObjectClass @ConnectionParams
        Write-Verbose "Object class initialization SUCCESS"

        #Initialize object to subobject mapping
        Write-Verbose "Initializing object to subobject mapping"
        Initialize-SchemaCompareObjectToSubobject @ConnectionParams
        Write-Verbose "Object to subobject initialization SUCCESS"

        #Initialize system types
        Write-Verbose "Initializing system types"
        Initialize-SchemaCompareSystemType @ConnectionParams
        Write-Verbose "System type initialization SUCCESS"

        #Initialize object class properties
        Write-Verbose "Initializing object class properties"
        Initialize-SchemaCompareSystemType @ConnectionParams
        Write-Verbose "Object class property initialization SUCCESS"
    }
    catch
    {
        throw $_.Exception 
    }
}

function Compare-Database
{
    <#
        .SYNOPSIS
        Compare all objects between two databases

        .DESCRIPTION
        For a given pair of databases, possibly on different SQL Server instances,
        compare the schema-level objects (tables, views, procedures, functions, types)
        and then the subobjects of these objects, and their subobjects, until 
        the objects no longer have any subobjects. 
        
        The comparison can be visualized as a tree where each node can have scalar values
        and/or vector-valued children. 

        .PARAMETER ServerInstance
        The SQL Server Instance hosting Database

        .PARAMETER Database
        The SQL Server database of SchemaCompare

        .PARAMETER ServerInstanceLeft
        The SQL Server Instance hosting DatabaseLeft

        .PARAMETER DatabaseLeft
        The SQL Server database used on the left side of the comparison

        .PARAMETER ServerInstanceRight
        The SQL Server Instance hosting DatabaseRight

        .PARAMETER DatabaseRight
        The SQL Server database used on the right side of the comparison
    #>
    [CmdletBinding()]
    param
    (
        [String] $ServerInstance
    ,   
        [String] $Database
    ,
        [String] $ServerInstanceLeft
    ,
        [String] $DatabaseLeft
    ,
        [String] $ServerInstanceRight
    ,
        [String] $DatabaseRight
    )
}

function Compare-Schema
{
    <#
        .SYNOPSIS
        Compare all objects between two database schemas

        .DESCRIPTION
        Perform the comparison of Compare-Database, but only compare two specified schemas,
        possibly with a different name between databases. See Compare-Database's help for details.

        .PARAMETER ServerInstance
        The SQL Server Instance hosting Database

        .PARAMETER Database
        The SQL Server database of SchemaCompare

        .PARAMETER ServerInstanceLeft
        The SQL Server Instance hosting DatabaseLeft

        .PARAMETER DatabaseLeft
        The SQL Server database used on the left side of the comparison

        .PARAMETER SchemaLeft
        The schema within Database on the left side of the comparison 

        .PARAMETER ServerInstanceRight
        The SQL Server Instance hosting DatabaseRight

        .PARAMETER DatabaseRight
        The SQL Server database used on the right side of the comparison    

        .PARAMETER SchemaRight
        The schema within Database on the right side of the comparison
    #>
    [CmdletBinding()]
    param
    (
        [String] $ServerInstance
    ,   
        [String] $Database
    ,
        [String] $ServerInstanceLeft
    ,
        [String] $DatabaseLeft
    ,
        [String] $SchemaLeft
    ,
        [String] $ServerInstanceRight
    ,
        [String] $DatabaseRight
    ,
        [String] $SchemaRight
    )
}

function Compare-Object
{
    <#
        .SYNOPSIS
        Compare all objects of a given object class between two database schemas

        .DESCRIPTION
        Perform the comparison of Compare-Schema except restrict the focus to only the 
        specified object class. Since Compare-Schema is logically performing Compare-Database
        but with a restricted schema, Compare-Object can be understood as performing Compare-Database
        but with a restricted schema AND restricted object class. 

        .PARAMETER ServerInstance
        The SQL Server Instance hosting Database

        .PARAMETER Database
        The SQL Server database of SchemaCompare

        .PARAMETER ServerInstanceLeft
        The SQL Server Instance hosting DatabaseLeft

        .PARAMETER DatabaseLeft
        The SQL Server database used on the left side of the comparison
        
        .PARAMETER SchemaLeft
        The schema within Database on the left side of the comparison 

        .PARAMETER ServerInstanceRight
        The SQL Server Instance hosting DatabaseRight

        .PARAMETER DatabaseRight
        The SQL Server database used on the right side of the comparison

        .PARAMETER SchemaRight
        The schema within Database on the right side of the comparison
    #>
    [CmdletBinding()]
    param
    (
        [String] $ServerInstance
    ,   
        [String] $Database
    ,
        [ValidateSet('Table'
                    , 'View'
                    , 'Type'
                    , 'Procedure'
                    , 'Function'
                    )
        ]
        [String] $ObjectClass
    ,
        [String] $ServerInstanceLeft
    ,
        [String] $DatabaseLeft
    ,
        [String] $SchemaLeft
    ,
        [Parameter(ParameterSetName="Single")]
        [String] $ObjectNameLeft
    ,
        [String] $ServerInstanceRight
    ,
        [String] $DatabaseRight
    ,
        [String] $SchemaRight
    ,
        [Parameter(ParameterSetName="Single")]
        [String] $ObjectNameRight

    ,   [Parameter(ParameterSetName="All")]
        [Switch] $All
    )
}

function Compare-SubObject
{
    <#
        .SYNOPSIS
        Compare all objects of a given object class and subobject class between two database schemas

        .DESCRIPTION
        Perform the comparison of Compare-Schema except restrict the focus to only the 
        specified object class and subclass. Since Compare-Schema is logically performing Compare-Database
        but with a restricted schema, Compare-Object can be understood as performing Compare-Database
        but with a restricted schema, object class, and subobject class. 

        .PARAMETER ServerInstance
        The SQL Server Instance hosting Database

        .PARAMETER Database
        The SQL Server database of SchemaCompare

        .PARAMETER ServerInstanceLeft
        The SQL Server Instance hosting DatabaseLeft

        .PARAMETER DatabaseLeft
        The SQL Server database used on the left side of the comparison

        .PARAMETER SchemaLeft
        The schema within Database on the left side of the comparison 

        .PARAMETER ServerInstanceRight
        The SQL Server Instance hosting DatabaseRight

        .PARAMETER DatabaseRight
        The SQL Server database used on the right side of the comparison

        .PARAMETER SchemaRight
        The schema within Database on the right side of the comparison
    #>
    [CmdletBinding()]
    param
    (
        [String] $ServerInstance
    ,   
        [String] $Database
    ,
        [ValidateSet('Table'
                    , 'View'
                    , 'Type'
                    , 'Procedure'
                    , 'Function'
                    )
        ]
        [String] $ObjectClass
    ,
        [String] $SubObjectClass
    ,
        [String] $ServerInstanceLeft
    ,
        [String] $DatabaseLeft
    ,
        [String] $SchemaLeft
    ,
        [String] $ObjectNameLeft
    ,
        [String] $SubObjectNameLeft
    ,
        [String] $ServerInstanceRight
    ,
        [String] $DatabaseRight
    ,
        [String] $SchemaRight
    ,
        [String] $ObjectNameRight
    ,
        [String] $SubObjectNameRight
    )
}

function Compare-Table
{
    <#
        .SYNOPSIS
        Convenience function for Compare-Object with -ObjectClass "Table"

        .DESCRIPTION
        Calls Compare-Object -ObjectClass "Table" @Params, where @Params contains
        the values of the remaining parameters passed into this function. 
        See Compare-Object for details

        .PARAMETER ServerInstance
        The SQL Server Instance hosting Database

        .PARAMETER Database
        The SQL Server database of SchemaCompare

        .PARAMETER ServerInstanceLeft
        The SQL Server Instance hosting DatabaseLeft

        .PARAMETER DatabaseLeft
        The SQL Server database used on the left side of the comparison
        
        .PARAMETER SchemaLeft
        The schema within Database on the left side of the comparison 

        .PARAMETER ServerInstanceRight
        The SQL Server Instance hosting DatabaseRight

        .PARAMETER DatabaseRight
        The SQL Server database used on the right side of the comparison

        .PARAMETER SchemaRight
        The schema within Database on the right side of the comparison
    #>
    [CmdletBinding()]
    param
    (
        [String] $ServerInstance
    ,   
        [String] $Database
    ,
        [String] $ServerInstanceLeft
    ,
        [String] $DatabaseLeft
    ,
        [String] $SchemaLeft
    ,
        [String] $ServerInstanceRight
    ,
        [String] $DatabaseRight
    ,
        [String] $SchemaRight
    )
}

function Compare-TableColumn
{
    <#
        .SYNOPSIS
        A convenience function for Compare-SubObject with -ObjectClass "Table" and -SubObjectClass "Column"

        .DESCRIPTION
        Calls Compare-SubObject -ObjectClass "Table" -SubObjectClass "Column" -ObjectNameLeft $TableLeft -SubObjectNameLeft $ColumnLeft -ObjectNameRight $TableRight -SubObjectNameRight $ColumnRight
    
        .PARAMETER ServerInstance
        The SQL Server Instance hosting Database

        .PARAMETER Database
        The SQL Server database of SchemaCompare

        .PARAMETER ServerInstanceLeft
        The SQL Server Instance hosting DatabaseLeft

        .PARAMETER DatabaseLeft
        The SQL Server database used on the left side of the comparison
        
        .PARAMETER SchemaLeft
        The schema within Database on the left side of the comparison 

        .PARAMETER ServerInstanceRight
        The SQL Server Instance hosting DatabaseRight

        .PARAMETER DatabaseRight
        The SQL Server database used on the right side of the comparison

        .PARAMETER SchemaRight
        The schema within Database on the right side of the comparison
    #>
    [CmdletBinding()]
    param
    (
        [String] $ServerInstance
    ,   
        [String] $Database
    ,
        [String] $ServerInstanceLeft
    ,
        [String] $DatabaseLeft
    ,
        [String] $SchemaLeft
    ,
        [String] $TableLeft
    ,
        [String] $ColumnLeft
    ,
        [String] $ServerInstanceRight
    ,
        [String] $DatabaseRight
    ,
        [String] $SchemaRight
    ,
        [String] $TableRight
    ,
        [String] $ColumnRight
    )
}

function Compare-View
{
    <#
        .SYNOPSIS
        Convenience function for Compare-Object with -ObjectClass "View"

        .DESCRIPTION
        Calls Compare-Object -ObjectClass "View" @Params, where @Params contains
        the values of the remaining parameters passed into this function. 
        See Compare-Object for details

        .PARAMETER ServerInstance
        The SQL Server Instance hosting Database

        .PARAMETER Database
        The SQL Server database of SchemaCompare

        .PARAMETER ServerInstanceLeft
        The SQL Server Instance hosting DatabaseLeft

        .PARAMETER DatabaseLeft
        The SQL Server database used on the left side of the comparison
        
        .PARAMETER SchemaLeft
        The schema within Database on the left side of the comparison 

        .PARAMETER ServerInstanceRight
        The SQL Server Instance hosting DatabaseRight

        .PARAMETER DatabaseRight
        The SQL Server database used on the right side of the comparison

        .PARAMETER SchemaRight
        The schema within Database on the right side of the comparison
    #>
    [CmdletBinding()]
    param
    (
        [String] $ServerInstance
    ,   
        [String] $Database
    ,
        [String] $ServerInstanceLeft
    ,
        [String] $DatabaseLeft
    ,
        [String] $SchemaLeft
    ,
        [String] $ServerInstanceRight
    ,
        [String] $DatabaseRight
    ,
        [String] $SchemaRight
    )
}

function Compare-ViewColumn
{
    <#
        .SYNOPSIS
        A convenience function for Compare-SubObject with -ObjectClass "View" and -SubObjectClass "Column"

        .DESCRIPTION
        Calls Compare-SubObject -ObjectClass "View" -SubObjectClass "Column" -ObjectNameLeft $ViewLeft -SubObjectNameLeft $ColumnLeft -ObjectNameRight $ViewRight -SubObjectNameRight $ColumnRight
    
        .PARAMETER ServerInstance
        The SQL Server Instance hosting Database

        .PARAMETER Database
        The SQL Server database of SchemaCompare

        .PARAMETER ServerInstanceLeft
        The SQL Server Instance hosting DatabaseLeft

        .PARAMETER DatabaseLeft
        The SQL Server database used on the left side of the comparison
        
        .PARAMETER SchemaLeft
        The schema within Database on the left side of the comparison 

        .PARAMETER ServerInstanceRight
        The SQL Server Instance hosting DatabaseRight

        .PARAMETER DatabaseRight
        The SQL Server database used on the right side of the comparison

        .PARAMETER SchemaRight
        The schema within Database on the right side of the comparison
    #>
    [CmdletBinding()]
    param
    (
        [String] $ServerInstance
    ,   
        [String] $Database
    ,
        [String] $ServerInstanceLeft
    ,
        [String] $DatabaseLeft
    ,
        [String] $SchemaLeft
    ,
        [String] $ViewLeft
    ,
        [String] $ServerInstanceRight
    ,
        [String] $DatabaseRight
    ,
        [String] $SchemaRight
    ,
        [String] $ViewRight
    )
}

function Compare-Procedure
{
    <#
        .SYNOPSIS
        Convenience function for Compare-Object with -ObjectClass "Procedure"

        .DESCRIPTION
        Calls Compare-Object -ObjectClass "Procedure" @Params, where @Params contains
        the values of the remaining parameters passed into this function. 
        See Compare-Object for details

        .PARAMETER ServerInstance
        The SQL Server Instance hosting Database

        .PARAMETER Database
        The SQL Server database of SchemaCompare

        .PARAMETER ServerInstanceLeft
        The SQL Server Instance hosting DatabaseLeft

        .PARAMETER DatabaseLeft
        The SQL Server database used on the left side of the comparison
        
        .PARAMETER SchemaLeft
        The schema within Database on the left side of the comparison 

        .PARAMETER ServerInstanceRight
        The SQL Server Instance hosting DatabaseRight

        .PARAMETER DatabaseRight
        The SQL Server database used on the right side of the comparison

        .PARAMETER SchemaRight
        The schema within Database on the right side of the comparison
    #>
    [CmdletBinding()]
    param
    (
        [String] $ServerInstance
    ,   
        [String] $Database
    ,
        [String] $ServerInstanceLeft
    ,
        [String] $DatabaseLeft
    ,
        [String] $SchemaLeft
    ,
        [String] $ServerInstanceRight
    ,
        [String] $DatabaseRight
    ,
        [String] $SchemaRight
    )
}

function Compare-ProcedureParameter
{
    <#
        .SYNOPSIS
        A convenience function for Compare-SubObject with -ObjectClass "Procedure" and -SubObjectClass "Parameter"

        .DESCRIPTION
        Calls Compare-SubObject -ObjectClass "Procedure" -SubObjectClass "Parameter" -ObjectNameLeft $ProcedureLeft -SubObjectNameLeft $ParameterLeft -ObjectNameRight $ProcedureRight -SubObjectNameRight $ParameterRight
    
        .PARAMETER ServerInstance
        The SQL Server Instance hosting Database

        .PARAMETER Database
        The SQL Server database of SchemaCompare

        .PARAMETER ServerInstanceLeft
        The SQL Server Instance hosting DatabaseLeft

        .PARAMETER DatabaseLeft
        The SQL Server database used on the left side of the comparison
        
        .PARAMETER SchemaLeft
        The schema within Database on the left side of the comparison 

        .PARAMETER ServerInstanceRight
        The SQL Server Instance hosting DatabaseRight

        .PARAMETER DatabaseRight
        The SQL Server database used on the right side of the comparison

        .PARAMETER SchemaRight
        The schema within Database on the right side of the comparison
    #>
    [CmdletBinding()]
    param
    (
        [String] $ServerInstance
    ,   
        [String] $Database
    ,
        [String] $ServerInstanceLeft
    ,
        [String] $DatabaseLeft
    ,
        [String] $SchemaLeft
    ,
        [String] $ProcedureLeft
    ,
        [String] $ParameterLeft
    ,
        [String] $ServerInstanceRight
    ,
        [String] $DatabaseRight
    ,
        [String] $SchemaRight
    ,
        [String] $ProcedureRight
    ,
        [String] $ParameterRight
    )
}

function Compare-Function
{
    <#
        .SYNOPSIS
        Convenience function for Compare-Object with -ObjectClass "Function"

        .DESCRIPTION
        Calls Compare-Object -ObjectClass "Function" @Params, where @Params contains
        the values of the remaining parameters passed into this function. 
        See Compare-Object for details

        .PARAMETER ServerInstance
        The SQL Server Instance hosting Database

        .PARAMETER Database
        The SQL Server database of SchemaCompare

        .PARAMETER ServerInstanceLeft
        The SQL Server Instance hosting DatabaseLeft

        .PARAMETER DatabaseLeft
        The SQL Server database used on the left side of the comparison
        
        .PARAMETER SchemaLeft
        The schema within Database on the left side of the comparison 

        .PARAMETER ServerInstanceRight
        The SQL Server Instance hosting DatabaseRight

        .PARAMETER DatabaseRight
        The SQL Server database used on the right side of the comparison

        .PARAMETER SchemaRight
        The schema within Database on the right side of the comparison
    #>
    [CmdletBinding()]
    param
    (
        [String] $ServerInstance
    ,   
        [String] $Database
    ,
        [String] $ServerInstanceLeft
    ,
        [String] $DatabaseLeft
    ,
        [String] $SchemaLeft
    ,
        [String] $ServerInstanceRight
    ,
        [String] $DatabaseRight
    ,
        [String] $SchemaRight
    )
}

function Compare-FunctionParameter
{
    <#
        .SYNOPSIS
        A convenience function for Compare-SubObject with -ObjectClass "Function" and -SubObjectClass "Parameter"

        .DESCRIPTION
        Calls Compare-SubObject -ObjectClass "Function" -SubObjectClass "Parameter" -ObjectNameLeft $FunctionLeft -SubObjectNameLeft $ParameterLeft -ObjectNameRight $FunctionRight -SubObjectNameRight $ParameterRight
    
        .PARAMETER ServerInstance
        The SQL Server Instance hosting Database

        .PARAMETER Database
        The SQL Server database of SchemaCompare

        .PARAMETER ServerInstanceLeft
        The SQL Server Instance hosting DatabaseLeft

        .PARAMETER DatabaseLeft
        The SQL Server database used on the left side of the comparison
        
        .PARAMETER SchemaLeft
        The schema within Database on the left side of the comparison 

        .PARAMETER ServerInstanceRight
        The SQL Server Instance hosting DatabaseRight

        .PARAMETER DatabaseRight
        The SQL Server database used on the right side of the comparison

        .PARAMETER SchemaRight
        The schema within Database on the right side of the comparison
    #>
    [CmdletBinding()]
    param
    (
        [String] $ServerInstance
    ,   
        [String] $Database
    ,
        [String] $ServerInstanceLeft
    ,
        [String] $DatabaseLeft
    ,
        [String] $SchemaLeft
    ,
        [String] $FunctionLeft
    ,
        [String] $ServerInstanceRight
    ,
        [String] $DatabaseRight
    ,
        [String] $SchemaRight
    ,
        [String] $FunctionRight
    )
}

function Compare-Type
{
    <#
        .SYNOPSIS
        Convenience function for Compare-Object with -ObjectClass "Type"

        .DESCRIPTION
        Calls Compare-Object -ObjectClass "Type" @Params, where @Params contains
        the values of the remaining parameters passed into this function. 
        See Compare-Object for details

        .PARAMETER ServerInstance
        The SQL Server Instance hosting Database

        .PARAMETER Database
        The SQL Server database of SchemaCompare

        .PARAMETER ServerInstanceLeft
        The SQL Server Instance hosting DatabaseLeft

        .PARAMETER DatabaseLeft
        The SQL Server database used on the left side of the comparison
        
        .PARAMETER SchemaLeft
        The schema within Database on the left side of the comparison 

        .PARAMETER ServerInstanceRight
        The SQL Server Instance hosting DatabaseRight

        .PARAMETER DatabaseRight
        The SQL Server database used on the right side of the comparison

        .PARAMETER SchemaRight
        The schema within Database on the right side of the comparison
    #>
    [CmdletBinding()]
    param
    (
        [String] $ServerInstance
    ,   
        [String] $Database
    ,
        [String] $ServerInstanceLeft
    ,
        [String] $DatabaseLeft
    ,
        [String] $SchemaLeft
    ,
        [String] $ServerInstanceRight
    ,
        [String] $DatabaseRight
    ,
        [String] $SchemaRight
    )
}

function Get-ObjectClassProperty
{
    <#
        .SYNOPSIS
        Returns the properties associated with an object class

        .DESCRIPTION
        For each object class, there is at least a property 'name' which uniquely identifies
        an instance of the object within a database and schema combination. This command
        lists this name property along with any additional properties which are being tracked
        by the current configuration of the module. These tracked properties are the values 
        that are considered in the comparison. That is, we are looking for and reporting
        objects of the same object class with differing object properties.
        
        We will define an "enabled" property to be a property that is being tracked and a "disabled" property 
        to be a property that is not currently being tracked. 
        By default, this command displays only the enabled properties of an object class.
        Use the IncludeDisabled switch to display all properties, including those that are disabled. 
    
        .PARAMETER ServerInstance
        The SQL Server Instance hosting Database

        .PARAMETER Database
        The SQL Server database of SchemaCompare
    #>
    [CmdletBinding()]
    param
    (
        [String] $ServerInstance
    ,   
        [String] $Database
    ,
        [String] $ObjectClass
    ,
        [Switch] $IncludeDisabled
    )
}

function Disable-ObjectClassProperty
{
    <#
        .SYNOPSIS
        Removes a specified object class property for consideration in comparisons

        .DESCRIPTION
        Disables a currently enabled property of an object class.
        If ObjectClass does not have a property ObjectClassProperty or it does and the 
        property is currently disabled, this command raises an error. 

        For a description of enabled vs. disabled projects, see the help for Get-ObjectClassProperty
    
        .PARAMETER ServerInstance
        The SQL Server Instance hosting Database

        .PARAMETER Database
        The SQL Server database of SchemaCompare
    #>
    [CmdletBinding()]
    param
    (
        [String] $ServerInstance
    ,   
        [String] $Database
    ,
        [String] $ObjectClass
    ,
        [String] $ObjectClassProperty
    )
}

function Enable-ObjectProperty
{
    <#
        .SYNOPSIS
        Includes a specified object class property for consideration in comparisons

        .DESCRIPTION
        Enables a currently disabled property of an object class.
        If ObjectClass does not have a property ObjectClassProperty or it does and the 
        property is currently enabled, this command raises an error. 

        For a description of enabled vs. disabled projects, see the help for Get-ObjectClassProperty
    
        .PARAMETER ServerInstance
        The SQL Server Instance hosting Database

        .PARAMETER Database
        The SQL Server database of SchemaCompare
    #>
    [CmdletBinding()]
    param
    (
        [String] $ServerInstance
    ,   
        [String] $Database
    ,
        [String] $ObjectClass
    ,
        [String] $ObjectClassProperty
    )
}

function Register-SQLServerInstance
{
    <#
        .SYNOPSIS
        Registers a SQL Server Instance for SchemaCompare monitoring.

        .DESCRIPTION
        Makes SchemaCompare aware of a new SQL Server instance. This 
        is a prerequisite command to adding databases to watch, since we may
        have the same database name on different SQL Server instances.

        .PARAMETER SchemaCompareServerInstance
        The SQL Server instance hosting SchemaCompareDatabase

        .PARAMETER SchemaCompareDatabase
        The SQL Server database supporting the SchemaCompare module

        .PARAMETER ServerInstance
        The SQL Server instance to register
    #>
    [CmdletBinding()]
    param
    (
        [String] $SchemaCompareServerInstance
    ,   [String] $SchemaCompareDatabase 
    ,   [String] $ServerInstance
    )
}

function Register-SQLServerDatabase
{
    <#
        .SYNOPSIS
        Registers a SQL Server database for SchemaCompare monitoring.

        .DESCRIPTION
        Assuming the SQL Server Instance was previously registered, 
        this command makes SchemaCompare aware of a particular database to watch.
        If the SQL Server instance has not been registered previously, this command
        raises an error.

        .PARAMETER SchemaCompareServerInstance
        The SQL Server instance hosting SchemaCompareDatabase

        .PARAMETER SchemaCompareDatabase
        The SQL Server database supporting the SchemaCompare module

        .PARAMETER ServerInstance
        A SQL Server instance which has previously been registered with Register-SQLServerInstance

        .PARAMETER Database
        The SQL Server database on ServerInstance to register
    #>
    param
    (
        [String] $SchemaCompareServerInstance
    ,   [String] $SchemaCompareDatabase
    ,   [String] $ServerInstance
    ,   [String] $Database 
    )


}