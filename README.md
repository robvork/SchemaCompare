# SchemaCompare
A PowerShell module for comparing the names and properties of database objects

## Introduction
SchemaCompare is a Windows PowerShell module built on SQL Server which facilitates
the comparison of SQL Server databases. Its comparisons produce result sets
which provide structured diff-like output for relational metadata.

A common need in database development is to compare databases at different levels of 
granularity. For brevity, let's fix two databases and call them Left and Right, respectively.

Sample comparisons between Left and Right might include:
* What tables does Left have that Right does not have?
* What tables do Left and Right have in common but for which Left has columns Right doesn't have or vice versa?
* What procedures does Right have that Left does not have?
* What procedures do Left and Right have in common but for which the data types of the respective parameters are different?
* Are there any differences between the entire Left database and the entire Right database? 
  If so, where are these differences?
* Given some set of properties we wish to ignore for the sake of a comparison, and another list of important properties, what are the differences between only the properties of interest?

SchemaCompare is designed to handle questions like the above and more. 

The basic idea of the module is to provide a generic solution for comparing any kind of SQL Server object which can be configured to the needs of the end user. 
The properties of interest are completely configurable, so that the user can make his or her own choices as to what should be compared. This can come in handy whenever we encounter surrogate keys (such as those that are found in system catalogs) and dates/times which we might not be interested as far as differences are concerned. 

Further, the inner workings of the database used to support SchemaCompare are fully 
exposed and can be added to or integrated into existing systems, as needed. Supporting
documentation for the data model and procedures are provided. 

## Initializing the SchemaCompare database
Before you can start using the database, you must create it and initialize it.
You can do this with the module function 
```powershell
Install-SchemaCompare
```

You must specify the ServerInstance and Database name.

## Configuring Object Class Properties
Following initialization, each object class has by default all properties enabled.
To see the list for each property, use the command 
```powershell
Get-SchemaCompareObjectClassProperty
```

To disable a property from being watched, use the command
```powershell
Disable-SchemaCompareObjectClassProperty
```

To enable a property that has been disabled, use the command
```powershell
Enable-SchemaCompareObjectClassProperty
```

## Adding server instances and databases to watch
Before you run comparisons, you must specify the SQL Server databases
and their respective instances that we are interested in watching. 
Following this setup, the database you initialized will get an initial read
of each database's metadata which will be refreshed upon each comparison.

To add a SQL Server instance to the system database, use the command
```powershell
Register-SchemaCompareSQLServerInstance
```

To add a SQL Server database which has previously had its instance registered, use the command
```powershell
Register-SchemaCompareSQLServerDatabase
```

## Running Comparisons
Assuming you have completed the initialization, the object property configuration (optional), and Server Instance/Database configuration, you are now ready to compare data models.

To compare entire databases, including all object classes, use the command
```powershell
Compare-SchemaCompareDatabase
```

To compare schemas within particular databases, use the command
```powershell
Compare-SchemaCompareSchema
```

To compare categories of objects within schemas, use the command
```powershell
Compare-SchemaCompareObject 
```

Alternatively, you can use the convenience commands which call Compare-Object and Compare-SubObject
```powershell
Compare-SchemaCompareTable
Compare-SchemaCompareTableColumn
Compare-SchemaCompareView
Compare-SchemaCompareViewColumn
Compare-SchemaCompareProcedure
Compare-SchemaCompareProcedureParameter
Compare-SchemaCompareFunction
Compare-SchemaCompareFunctionParameter
```
