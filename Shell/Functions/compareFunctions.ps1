
        function Compare-SchemaCompareDatabase
        {
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
            ,
                [Switch] $Recurse
            ,
                [Int] $Depth
            )

            Compare-SchemaCompareObjectClass -ObjectClassName "database" @PSBoundParameters
        }
        

        function Compare-SchemaCompareSchema
        {
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
            ,
                [Switch] $Recurse
            ,
                [Int] $Depth
            )

            Compare-SchemaCompareObjectClass -ObjectClassName "schema" @PSBoundParameters
        }
        

        function Compare-SchemaCompareTable
        {
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
            ,
                [Switch] $Recurse
            ,
                [Int] $Depth
            )

            Compare-SchemaCompareObjectClass -ObjectClassName "table" @PSBoundParameters
        }
        

        function Compare-SchemaCompareTablecolumn
        {
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
            ,
                [Switch] $Recurse
            ,
                [Int] $Depth
            )

            Compare-SchemaCompareObjectClass -ObjectClassName "table_column" @PSBoundParameters
        }
        

        function Compare-SchemaCompareView
        {
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
            ,
                [Switch] $Recurse
            ,
                [Int] $Depth
            )

            Compare-SchemaCompareObjectClass -ObjectClassName "view" @PSBoundParameters
        }
        

        function Compare-SchemaCompareViewcolumn
        {
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
            ,
                [Switch] $Recurse
            ,
                [Int] $Depth
            )

            Compare-SchemaCompareObjectClass -ObjectClassName "view_column" @PSBoundParameters
        }
        

        function Compare-SchemaCompareProcedure
        {
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
            ,
                [Switch] $Recurse
            ,
                [Int] $Depth
            )

            Compare-SchemaCompareObjectClass -ObjectClassName "procedure" @PSBoundParameters
        }
        

        function Compare-SchemaCompareProcedureparam
        {
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
            ,
                [Switch] $Recurse
            ,
                [Int] $Depth
            )

            Compare-SchemaCompareObjectClass -ObjectClassName "procedure_param" @PSBoundParameters
        }
        

        function Compare-SchemaCompareFunction
        {
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
            ,
                [Switch] $Recurse
            ,
                [Int] $Depth
            )

            Compare-SchemaCompareObjectClass -ObjectClassName "function" @PSBoundParameters
        }
        

        function Compare-SchemaCompareFunctionparam
        {
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
            ,
                [Switch] $Recurse
            ,
                [Int] $Depth
            )

            Compare-SchemaCompareObjectClass -ObjectClassName "function_param" @PSBoundParameters
        }
        
