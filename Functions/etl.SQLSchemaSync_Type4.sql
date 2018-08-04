SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*
DECLARE
@SourceSchema NVARCHAR(400) = 'src'
,@TargetSchema NVARCHAR(400) = 'ods'
,@TableName NVARCHAR(400) = 'Question'
,@TargetTableExists BIT = 0
,@TargetTableColumnsMatch BIT = 0

SELECT [etl].[SQLSchemaSync_Type4] (@SourceSchema,@TargetSchema,@TableName,@TargetTableExists,@TargetTableColumnsMatch)
*/


CREATE FUNCTION [etl].[SQLSchemaSync_Type4]
(@SourceSchema NVARCHAR(400)
,@TargetSchema NVARCHAR(400)
,@TableName NVARCHAR(400)
,@TargetTableExists BIT
,@TargetTableColumnsMatch BIT)

RETURNS NVARCHAR(MAX)

AS
BEGIN

DECLARE @CreateTargetTableSQL NVARCHAR(MAX) = '
/*------------------------------------------------------------------------
Type4 Schema Sync Module
Transformations Supported: Type4
Notes: Creates target table, trigger, snapshot table, and AsOf TVF
  Target Table: Matching columns plus CreatedOn, CreatedBy, UpdatedOn, UpdatedBy
  Snapshot Table: Matching target table columns plus Identity/PK SK Column, CreatedOn, CreatedBy, UpdatedOn, UpdatedBy
  Trigger: Updates UpdatedOn and UpdatedBy with time stamp and user
  AsOf TVF: Allows you to recreate the state of the table at any point in time (to the second)
------------------------------------------------------------------------*/
'

DECLARE @Source NVARCHAR(MAX) = '[' + @SourceSchema + '].[' + @TableName + ']'
DECLARE @Target NVARCHAR(MAX) = '[' + @TargetSchema + '].[' + @TableName + ']'
DECLARE @SnapshotTarget NVARCHAR(MAX) = '[' + @TargetSchema + '].[Snapshot_' + @TableName + ']'
DECLARE @DateTime DATETIME = [etl].[ConvertToLocalTime](CAST(GETDATE() AS DATETIME2(0)))
DECLARE @CopyTargetTableName NVARCHAR(MAX) = @TableName + '_BKP' +
	CONVERT(NVARCHAR(4),DATEPART(YEAR,@DateTime)) +
	RIGHT('0' + CONVERT(NVARCHAR(2),DATEPART(MONTH,@DateTime)),2) +
	RIGHT('0' + CONVERT(NVARCHAR(2),DATEPART(DAY,@DateTime)),2) +
	RIGHT('0' + CONVERT(NVARCHAR(10),DATEPART(HOUR,@DateTime)),2) +
	RIGHT('0' + CONVERT(NVARCHAR(10),DATEPART(MINUTE,@DateTime)),2) +
	RIGHT('0' + CONVERT(NVARCHAR(10),DATEPART(SECOND,@DateTime)),2)
DECLARE @SnapshotCopyTargetTableName NVARCHAR(MAX) = 'Snapshot_' + @TableName + '_BKP' +
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
	
-------------------------------- Create Target Table --------------------------------

IF @TargetTableExists = 1 AND @TargetTableColumnsMatch = 0

SELECT @CreateTargetTableSQL += '
----------- TABLE EXISTS, BUT SCHEMA MUST CHANGE. BACKUP THE TABLE -----------
SELECT * INTO [dbo].[' + @CopyTargetTableName + '] FROM ' + @Target + '
DROP TABLE ' + @Target + '
'

;WITH TableColumnData AS
(
SELECT
	@Source FullTableName
	,1 GroupOrder
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
UNION ALL
SELECT *
FROM
	(
	SELECT @Source FullTableName, 2 GroupOrder, 1 ColumnOrder, 'ETL_CreatedOn' ColumnName, 'DATETIME' Name, 8 [Length], 23 [Precision], 3 Scale, 0 Is_Identity, 0 Is_Nullable, 0 IsPK, 0 IsDescPK, '[etl].[ConvertToLocalTime](CAST(GETDATE() AS DATETIME2(0)))' [Default]
	UNION ALL
	SELECT @Source FullTableName, 2 GroupOrder, 2 ColumnOrder, 'ETL_CreatedBy' ColumnName, 'NVARCHAR' Name, 400 [Length], 0 [Precision], 0 Scale, 0 Is_Identity, 0 Is_Nullable, 0 IsPK, 0 IsDescPK, 'SYSTEM_USER' [Default]
	UNION ALL
	SELECT @Source FullTableName, 2 GroupOrder, 3 ColumnOrder, 'ETL_UpdatedOn' ColumnName, 'DATETIME' Name, 8 [Length], 23 [Precision], 3 Scale, 0 Is_Identity, 0 Is_Nullable, 0 IsPK, 0 IsDescPK, '[etl].[ConvertToLocalTime](CAST(GETDATE() AS DATETIME2(0)))' [Default]
	UNION ALL
	SELECT @Source FullTableName, 2 GroupOrder, 4 ColumnOrder, 'ETL_UpdatedBy' ColumnName, 'NVARCHAR' Name, 400 [Length], 0 [Precision], 0 Scale, 0 Is_Identity, 0 Is_Nullable, 0 IsPK, 0 IsDescPK, 'SYSTEM_USER' [Default]
	) addl
)

SELECT @CreateTargetTableSQL += '
----------- CREATE THE TARGET TABLE WITH THE DESIRED SCHEMA -----------
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
SELECT @CreateTargetTableSQL += '
----------- PULL IN OLD COLUMNS LONG THE NEW SCHEMA MATCHES THE OLD, AND PK COLUMNS HAVE NOT CHANGED -----------
' + CASE WHEN @PKOnSourceAndTargetMatch = 0 THEN '/* PK has changed, so no columns can be carried over
' ELSE '' END + 'INSERT INTO ' + @Target + ' (' + @CarryOverColumnList + ')
SELECT ' + @CarryOverColumnList + '
FROM ' + '[dbo].[' + @CopyTargetTableName + ']
' + CASE WHEN @PKOnSourceAndTargetMatch = 0 THEN '*/
' ELSE '' END

IF @TargetTableExists = 1 AND @TargetTableColumnsMatch = 0
SELECT @CreateTargetTableSQL += '
DROP TABLE [dbo].[' + @CopyTargetTableName + ']
'


-------------------------------- Create Snapshot Table --------------------------------
DECLARE @CreateSnapshotTableSQL NVARCHAR(MAX) = ''
DECLARE @SnapshotTableExists BIT = (SELECT CASE WHEN @SnapshotTarget IN (SELECT '[' + s.name + '].[' + t.name + ']' TableName FROM sys.tables t JOIN sys.schemas s ON t.[schema_id] = s.[schema_id]) THEN 1 ELSE 0 END)

IF @SnapshotTableExists = 1
SELECT @CreateSnapshotTableSQL += '
----------- SNAPSHOT TABLE EXISTS, BUT SCHEMA MUST CHANGE. BACKUP THE TABLE -----------
SELECT * INTO [dbo].[' + @SnapshotCopyTargetTableName + '] FROM ' + @SnapshotTarget + '
DROP TABLE ' + @SnapshotTarget + '
'

;WITH SnapshotColumnData AS
(
SELECT
	@Source FullTableName
	,1 GroupOrder
	,c.ColumnOrder
	,c.ColumnName
	,c.[Name]
	,c.[Length]
	,c.[Precision]
	,c.Scale
	,0 Is_Identity
	,c.Is_Nullable
	,0 IsPK
	,ISNULL(c.IsDescPK,0) IsDescPK
	,NULL [Default]
FROM [etl].[ObjectSchema] c
WHERE FullTableName = @Source
UNION ALL
SELECT *
FROM
	(
	SELECT DISTINCT FullTableName,0 GroupOrder,0 ColumnOrder,@TableName + 'SK' ColumnName,'INT' [Name],4 [Length],10 [Precision],0 Scale,1 Is_Identity,0 Is_Nullable,1 IsPK,0 IsDescPK,NULL [Default]
	FROM [etl].[ObjectSchema] c
	WHERE FullTableName = @Source
	UNION ALL
	SELECT @Source FullTableName, 2 GroupOrder, 1 ColumnOrder, 'ETL_CreatedOn' ColumnName, 'DATETIME' Name, 8 [Length], 23 [Precision], 3 Scale, 0 Is_Identity, 0 Is_Nullable, 0 IsPK, 0 IsDescPK, NULL [Default]
	UNION ALL
	SELECT @Source FullTableName, 2 GroupOrder, 2 ColumnOrder, 'ETL_CreatedBy' ColumnName, 'NVARCHAR' Name, 400 [Length], 0 [Precision], 0 Scale, 0 Is_Identity, 0 Is_Nullable, 0 IsPK, 0 IsDescPK, NULL [Default]
	UNION ALL
	SELECT @Source FullTableName, 2 GroupOrder, 3 ColumnOrder, 'ETL_UpdatedOn' ColumnName, 'DATETIME' Name, 8 [Length], 23 [Precision], 3 Scale, 0 Is_Identity, 0 Is_Nullable, 0 IsPK, 0 IsDescPK, NULL [Default]
	UNION ALL
	SELECT @Source FullTableName, 2 GroupOrder, 4 ColumnOrder, 'ETL_UpdatedBy' ColumnName, 'NVARCHAR' Name, 400 [Length], 0 [Precision], 0 Scale, 0 Is_Identity, 0 Is_Nullable, 0 IsPK, 0 IsDescPK, NULL [Default]
	UNION ALL
	SELECT @Source FullTableName, 2 GroupOrder, 4 ColumnOrder, 'RecordEndDate' ColumnName, 'DATETIME' Name, 8 [Length], 23 [Precision], 3 Scale, 0 Is_Identity, 0 Is_Nullable, 0 IsPK, 0 IsDescPK, NULL [Default]
	) addl
)

SELECT @CreateSnapshotTableSQL += '
----------- CREATE SNAPSHOT TABLE WITH THE DESIRED SCHEMA -----------
CREATE TABLE ' + @SnapshotTarget + '(
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
					   ELSE 'NULL'
					   END
				+ CASE WHEN [Default] IS NOT NULL THEN ' DEFAULT(' + [Default] + ') ' ELSE '' END [text()]
			FROM SnapshotColumnData l
			WHERE l.FullTableName = a.FullTableName
			ORDER BY l.GroupOrder, l.ColumnOrder
			FOR XML PATH ('')
			), 4, 100000) ColumnList
		,ISNULL(',
PRIMARY KEY CLUSTERED 
(
	' + SUBSTRING(
			(SELECT ',' + CHAR(10) + '	[' + l.ColumnName + '] ' + CASE WHEN IsDescPK = 1 THEN 'DESC' ELSE 'ASC' END [text()]
			FROM SnapshotColumnData l
			WHERE l.FullTableName = a.FullTableName AND IsPK = 1
			ORDER BY l.GroupOrder, l.ColumnOrder
			FOR XML PATH ('')
			), 4, 100000) + '
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
','') + '
)
' PrimaryKey
	FROM SnapshotColumnData a
	) a
ORDER BY a.FullTableName

IF @SnapshotTableExists = 1
SELECT @CreateSnapshotTableSQL += '
----------- PULL IN OLD COLUMNS LONG THE NEW SCHEMA MATCHES THE OLD, AND PK COLUMNS HAVE NOT CHANGED -----------
INSERT INTO ' + @SnapshotTarget + ' (' + @CarryOverColumnList + ',[ETL_CreatedOn],[ETL_CreatedBy],[ETL_UpdatedOn],[ETL_UpdatedBy],[RecordEndDate])
SELECT ' + @CarryOverColumnList + ',[ETL_CreatedOn],[ETL_CreatedBy],[ETL_UpdatedOn],[ETL_UpdatedBy],[RecordEndDate]
FROM ' + '[dbo].[' + @SnapshotCopyTargetTableName + ']
'

IF @SnapshotTableExists = 1
BEGIN
SELECT @CreateSnapshotTableSQL += '
DROP TABLE [dbo].[' + @SnapshotCopyTargetTableName + ']
'
END


-------------------------------- Create Trigger --------------------------------
DECLARE @CreateTriggerSQL NVARCHAR(MAX) = ''

;WITH TriggerColumnData AS
(
SELECT
	@Source FullTableName
	,1 GroupOrder
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

SELECT DISTINCT @CreateTriggerSQL += '
----------- CREATE TRIGGER -----------
CREATE TRIGGER [' + @TargetSchema + '].[Snapshot_' + @TableName + 'Update] ON ' + @Target + '
AFTER UPDATE, DELETE

AS
BEGIN

DECLARE @ETL_UpdatedOn DATETIME = (SELECT [etl].[ConvertToLocalTime](CAST(GETDATE() AS DATETIME2(0))))
DECLARE @ETL_UpdatedBy NVARCHAR(400) = (SELECT SYSTEM_USER)

UPDATE t SET
[ETL_UpdatedOn] = @ETL_UpdatedOn
,[ETL_UpdatedBy] = @ETL_UpdatedBy
FROM ' + @Target + ' t
	JOIN inserted i ON ' + JoinOn + '

INSERT INTO ' + @SnapshotTarget + ' (' + ColumnList + '[ETL_CreatedOn],[ETL_CreatedBy],[ETL_UpdatedOn],[ETL_UpdatedBy],[RecordEndDate])
SELECT a.*,dateadd(s,-1,@ETL_UpdatedOn)
FROM deleted a

END
'
FROM
	(SELECT
		a.FullTableName
		,(SELECT '[' + l.ColumnName + '],' [text()]
		FROM TriggerColumnData l
		WHERE l.FullTableName = a.FullTableName
		ORDER BY l.GroupOrder, l.ColumnOrder
		FOR XML PATH ('')
		) ColumnList
	,SUBSTRING(
		(SELECT ' AND t.[' + l.ColumnName + '] = i.[' + l.ColumnName + ']' [text()]
		FROM TriggerColumnData l
		WHERE l.FullTableName = a.FullTableName AND l.IsPK = 1
		ORDER BY l.GroupOrder, l.ColumnOrder
		FOR XML PATH ('')
		), 5, 10000000) JoinOn
	FROM TriggerColumnData a
) a


-------------------------------- Create AsOf TVF --------------------------------
DECLARE @CreateAsOfTVFSQL NVARCHAR(MAX) = ''

;WITH AsOfColumnData AS
(
SELECT
	@Source FullTableName
	,1 GroupOrder
	,c.ColumnOrder
	,c.ColumnName
	,c.[Name]
	,c.[Length]
	,c.[Precision]
	,c.Scale
	,0 Is_Identity
	,c.Is_Nullable
	,0 IsPK
	,ISNULL(c.IsDescPK,0) IsDescPK
	,NULL [Default]
FROM [etl].[ObjectSchema] c
WHERE FullTableName = @Source
)

SELECT DISTINCT @CreateAsOfTVFSQL += '
/*
-- Get the status of your table 20 minutes ago...
DECLARE @AsOfDate DATETIME = (SELECT [etl].[ConvertToLocalTime](DATEADD(MINUTE,-20,GETDATE())))
SELECT * FROM [' + @TargetSchema + '].[AsOf_' + @TableName + '] (@AsOfDate)
*/

CREATE FUNCTION [' + @TargetSchema + '].[AsOf_' + @TableName + '] (@AsOfDate DATETIME)

RETURNS @Results TABLE
(
' + ColumnListWithDataTypes + ',
[ETL_CreatedOn] [datetime] NOT NULL,
[ETL_CreatedBy] NVARCHAR(400) NOT NULL,
[ETL_UpdatedOn] [datetime] NOT NULL,
[ETL_UpdatedBy] NVARCHAR(400) NOT NULL
)

AS
BEGIN

DECLARE @EndDate DATETIME = (SELECT [etl].[ConvertToLocalTime](CAST(GETDATE() AS datetime2(0))))
SET @AsOfDate = (SELECT CAST(@AsOfDate AS datetime2(0)))

INSERT INTO @Results
SELECT ' + ColumnList + '[ETL_CreatedOn],[ETL_CreatedBy],[ETL_UpdatedOn],[ETL_UpdatedBy]
FROM
	(
	SELECT ' + ColumnList + '[ETL_CreatedOn],[ETL_CreatedBy],[ETL_UpdatedOn],[ETL_UpdatedBy],@EndDate [RecordEndDate]
	FROM ' + @Target + ' t
	UNION ALL
	SELECT ' + ColumnList + '[ETL_CreatedOn],[ETL_CreatedBy],[ETL_UpdatedOn],[ETL_UpdatedBy],[RecordEndDate]
	FROM ' + @SnapshotTarget + '
	) a
WHERE
	@AsOfDate BETWEEN [ETL_UpdatedOn] AND [RecordEndDate]
	AND [ETL_CreatedOn] <= @AsOfDate

RETURN

END
'
FROM
	(SELECT
		a.FullTableName
		,(SELECT '[' + l.ColumnName + '],' [text()]
		FROM AsOfColumnData l
		WHERE l.FullTableName = a.FullTableName
		ORDER BY l.GroupOrder, l.ColumnOrder
		FOR XML PATH ('')
		) ColumnList
	,SUBSTRING(
		(SELECT ',' + CHAR(10) + '[' + l.ColumnName + '] [' + l.Name + ']' +
		CASE WHEN l.Name IN ('char','varchar','binary','varbinary') THEN '(' + CASE WHEN l.[Length] = -1 THEN 'max' ELSE CONVERT(NVARCHAR(100),l.[Length]) END + ')' ELSE '' END +
		CASE WHEN l.Name IN ('nvarchar','nchar') THEN '(' + CASE WHEN l.[Length] = -1 THEN 'max' ELSE CONVERT(NVARCHAR(100),l.[Length] / 2) END + ')' ELSE '' END +
		CASE WHEN l.Name IN ('datetime2','datetimeoffset','time') THEN '(' + CONVERT(NVARCHAR(100),l.[Scale]) + ')' ELSE '' END +
		CASE WHEN l.Name IN ('decimal','numeric') THEN '(' + CONVERT(NVARCHAR(100),l.[Precision]) + ', ' + CONVERT(NVARCHAR(100),l.[Scale]) + ')' ELSE '' END +
		' ' + CASE WHEN Is_Identity = 1 THEN 'IDENTITY (1,1)'
					WHEN (Is_Identity = 0 AND (Is_Nullable = 0 OR IsPK = 1)) THEN 'NOT NULL' 
					ELSE 'NULL'
					END
			+ CASE WHEN [Default] IS NOT NULL THEN ' DEFAULT(' + [Default] + ') ' ELSE '' END [text()]
		FROM AsOfColumnData l
		WHERE l.FullTableName = a.FullTableName
		ORDER BY l.GroupOrder, l.ColumnOrder
		FOR XML PATH ('')
		), 3, 100000) ColumnListWithDataTypes
	FROM AsOfColumnData a
) a


--PRINT CAST(@SQL AS NTEXT)

RETURN
@CreateTargetTableSQL +
@CreateSnapshotTableSQL + '
IF OBJECT_ID (''[' + @TargetSchema + '].[Snapshot_' + @TableName + 'Update]'',''TR'') IS NOT NULL DROP TRIGGER [' + @TargetSchema + '].[Snapshot_' + @TableName + 'Update]
EXEC (''' +
@CreateTriggerSQL + ''')

IF OBJECT_ID (''[' + @TargetSchema + '].[AsOf_' + @TableName + ']'',''TF'') IS NOT NULL DROP FUNCTION [' + @TargetSchema + '].[AsOf_' + @TableName + ']
EXEC (''' +
@CreateAsOfTVFSQL + ''')
'

END

GO
