function Compare-SchemaCompareObjectClass
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
        [String] $ObjectClassName
    ,
        [Switch] $Recurse
    ,
        [Int] $Depth
    )

    $Query = "EXECUTE [object].[p_compare_object]
                @as_instance_name_left = '$ServerInstanceLeft'
    ,           @as_database_name_left = '$DatabaseLeft'
    ,           @as_instance_name_right = '$ServerInstanceRight'
    ,           @as_database_name_right = '$DatabaseRight'
    ,           @as_object_class_name = '$ObjectClassName'
    ,           @as_recurse = $(if($Recurse.IsPresent){1} else{0})
    ,           @ai_depth = $Depth
    ;
    "
}

function Get-SchemaCompareObjectCompareWrapperFunction
{
    [CmdletBinding()]
    param
    (
        [parameter(ValueFromPipeline=$true)]
        [String] 
        $ObjectClassName
    )

    Process 
    {
        $ObjectClassNameFormatted = (([char]::ToUpper($ObjectClassName[0]) + $ObjectClassName.Substring(1)) -replace "[^a-z]", "")

        $functionDefinition = "
        function Compare-SchemaCompare$ObjectClassNameFormatted
        {
            [CmdletBinding()]
            param
            (
                [String] `$ServerInstance
            ,
                [String] `$Database 
            ,   
                [String] `$ServerInstanceLeft 
            ,
                [String] `$DatabaseLeft 
            ,
                [String] `$ServerInstanceRight
            ,
                [String] `$DatabaseRight
            ,
                [Switch] `$Recurse
            ,
                [Int] `$Depth
            )

            Compare-SchemaCompareObjectClass -ObjectClassName `"$ObjectClassName`" @PSBoundParameters
        }
        "
        Write-Output $functionDefinition
    }    
}
