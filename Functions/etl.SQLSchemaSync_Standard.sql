SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
DECLARE
@SourceSchema NVARCHAR(400) = 'src'
,@TargetSchema NVARCHAR(400) = 'ods'
,@TableName NVARCHAR(400) = 'Dyn_Account'
,@TargetTableExists BIT = 0
,@TargetTableColumnsMatch BIT = 0

SELECT [etl].[SQLSchemaSync_Standard] (@SourceSchema,@TargetSchema,@TableName,@TargetTableExists,@TargetTableColumnsMatch)
*/


CREATE FUNCTION [etl].[SQLSchemaSync_Standard]
(@SourceSchema NVARCHAR(400)
,@TargetSchema NVARCHAR(400)
,@TableName NVARCHAR(400)
,@TargetTableExists BIT
,@TargetTableColumnsMatch BIT)

RETURNS NVARCHAR(MAX)

AS
BEGIN

DECLARE @SQL NVARCHAR(MAX) = ''
--/*------------------------------------------------------------------------
--Standard Set Schema Sync Module
--Transformations Supported: Update, Insert, Upsert, Sync
--Notes: Creates exact copy target table based on source table
--------------------------------------------------------------------------*/
--'

DECLARE @Source NVARCHAR(MAX) = '[' + @SourceSchema + '].[' + @TableName + ']'
DECLARE @Target NVARCHAR(MAX) = '[' + @TargetSchema + '].[' + @TableName + ']'
DECLARE @DateTime DATETIME = [etl].[ConvertToLocalTime](CAST(GETDATE() AS DATETIME2(0)))
DECLARE @CopyTargetTableName NVARCHAR(MAX) = @TableName + '_BKP' +
	CONVERT(NVARCHAR(4),DATEPART(YEAR,@DateTime)) +
	RIGHT('0' + CONVERT(NVARCHAR(2),DATEPART(MONTH,@DateTime)),2) +
	RIGHT('0' + CONVERT(NVARCHAR(2),DATEPART(DAY,@DateTime)),2) +
	RIGHT('0' + CONVERT(NVARCHAR(10),DATEPART(HOUR,@DateTime)),2) +
	RIGHT('0' + CONVERT(NVARCHAR(10),DATEPART(MINUTE,@DateTime)),2) +
	RIGHT('0' + CONVERT(NVARCHAR(10),DATEPART(SECOND,@DateTime)),2)


DECLARE @CarryOverColumnList NVARCHAR(MAX) = NULL
IF @TargetTableExists = 1 AND @TargetTableColumnsMatch = 0
SET @CarryOverColumnList =
	(
	SELECT
		SUBSTRING(
		(SELECT ',[' + l.ColumnName + ']' [text()]
		FROM 
			(
			SELECT ColumnName
			FROM [etl].[SchemaCompare](@Source,@Target)
			WHERE IsMatch = 1
			) l
		FOR XML PATH ('')
		), 2, 100000)
	)

DECLARE @PKOnSourceAndTargetMatch BIT =
	(SELECT CASE WHEN ISNULL(SUM(CONVERT(INT,IsPK)),0) = ISNULL(SUM(CONVERT(INT,IsMatch)),0) THEN 1 ELSE 0 END
	FROM [etl].[SchemaCompare](@Source,@Target)
	WHERE IsPK = 1)

IF @TargetTableExists = 1 AND @TargetTableColumnsMatch = 0

SELECT @SQL += '
----------- TABLE EXISTS, BUT SCHEMA MUST CHANGE. BACKUP THE TABLE -----------
SELECT * INTO [dbo].[' + @CopyTargetTableName + '] FROM ' + @Target + '
DROP TABLE ' + @Target + '
'

;WITH TableColumnData AS
(
SELECT
	@Source FullTableName
	,0 GroupOrder
	,c.ColumnOrder
	,c.ColumnName
	,c.[Name]
	,c.[Length]
	,c.[Precision]
	,c.Scale
	,c.Is_Identity
	,c.Is_Nullable
	,c.IsPK
	,ISNULL(c.IsDescPK,0) IsDescPK
	,NULL [Default]
FROM [etl].[ObjectSchema] c
WHERE FullTableName = @Source
)

--SELECT * FROM TableColumnData ORDER BY GroupOrder,ColumnOrder

SELECT @SQL += '
----------- CREATE THE TABLE WITH THE DESIRED SCHEMA -----------
CREATE TABLE ' + @Target + '(
	' + ColumnList + PrimaryKey
FROM
	(SELECT DISTINCT
		a.FullTableName
		,SUBSTRING(
			(SELECT ',' + CHAR(10) + '	[' + l.ColumnName + '] [' + l.Name + ']' +
			CASE WHEN l.Name IN ('char','varchar','binary','varbinary') THEN '(' + CASE WHEN l.[Length] = -1 THEN 'max' ELSE CONVERT(NVARCHAR(100),l.[Length]) END + ')' ELSE '' END +
			CASE WHEN l.Name IN ('nvarchar','nchar') THEN '(' + CASE WHEN l.[Length] = -1 THEN 'max' ELSE CONVERT(NVARCHAR(100),l.[Length] / 2) END + ')' ELSE '' END +
			CASE WHEN l.Name IN ('datetime2','datetimeoffset','time') THEN '(' + CONVERT(NVARCHAR(100),l.[Scale]) + ')' ELSE '' END +
			CASE WHEN l.Name IN ('decimal','numeric') THEN '(' + CONVERT(NVARCHAR(100),l.[Precision]) + ', ' + CONVERT(NVARCHAR(100),l.[Scale]) + ')' ELSE '' END +
			' ' + CASE WHEN Is_Identity = 1 THEN 'IDENTITY (1,1)'
					   WHEN (Is_Identity = 0 AND (Is_Nullable = 0 OR IsPK = 1)) THEN 'NOT NULL' 
					   ELSE 'NULL'
					   END
				+ CASE WHEN [Default] IS NOT NULL THEN ' DEFAULT(' + [Default] + ') ' ELSE '' END [text()]
			FROM TableColumnData l
			WHERE l.FullTableName = a.FullTableName
			ORDER BY l.GroupOrder, l.ColumnOrder
			FOR XML PATH ('')
			), 4, 100000) ColumnList
		,ISNULL(',
PRIMARY KEY CLUSTERED 
(
	' + SUBSTRING(
			(SELECT ',' + CHAR(10) + '	[' + l.ColumnName + '] ' + CASE WHEN IsDescPK = 1 THEN 'DESC' ELSE 'ASC' END [text()]
			FROM TableColumnData l
			WHERE l.FullTableName = a.FullTableName AND IsPK = 1
			ORDER BY l.GroupOrder, l.ColumnOrder
			FOR XML PATH ('')
			), 4, 100000) + '
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
','') + '
)
' PrimaryKey
	FROM TableColumnData a
	) a
ORDER BY a.FullTableName

IF @TargetTableExists = 1 AND @TargetTableColumnsMatch = 0 AND @CarryOverColumnList IS NOT NULL
SELECT @SQL += '
----------- PULL IN OLD COLUMNS LONG THE NEW SCHEMA MATCHES THE OLD, AND PK COLUMNS HAVE NOT CHANGED -----------
' + CASE WHEN @PKOnSourceAndTargetMatch = 0 THEN '/* PK has changed, so no columns can be carried over
' ELSE '' END + 'INSERT INTO ' + @Target + ' (' + @CarryOverColumnList + ')
SELECT ' + @CarryOverColumnList + '
FROM ' + '[dbo].[' + @CopyTargetTableName + ']
' + CASE WHEN @PKOnSourceAndTargetMatch = 0 THEN '*/
' ELSE '' END

IF @TargetTableExists = 1 AND @TargetTableColumnsMatch = 0
SELECT @SQL += '
DROP TABLE [dbo].[' + @CopyTargetTableName + ']
'

--PRINT CAST(@SQL AS NTEXT)

RETURN @SQL

END

GO
