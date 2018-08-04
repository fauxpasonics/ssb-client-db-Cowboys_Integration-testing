SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [etl].[JSONTranslator]
(
@Step NVARCHAR(1000) = NULL
,@StageSchema NVARCHAR(1000) = NULL
,@TableNameLike NVARCHAR(255) = NULL
,@TableName NVARCHAR(255) = NULL
,@ETL__session_id NVARCHAR(36) = NULL
,@TargetTable NVARCHAR(255) = NULL
,@ParentBatchID INT = NULL
,@RawDataRowID int = NULL
)
AS

SET NOCOUNT ON

/**************************************************************************************************************************
*	Version Number:	1.0
*	Description:		Translate JSON into an appropriate set of SQL tables
*	Author:			Tommy Dickinson & Eric Laurello
*	Date:			06/29/2017
***************************************************************************************************************************
*	Change History
***************************************************************************************************************************
*	PR	Date			Author					Description 
*	--	----------		----------------		------------------------------------
*	1	06/29/2017		Tommy Dickinson			Initial Creation
*	2	07/06/2017		Eric Laurello			Removed Hname update with recursive CTE.  Data now written on insert
***************************************************************************************************************************/

DECLARE @IsSuccess AS TABLE (IsSuccess BIT)

DECLARE @Message NVARCHAR(MAX) = ''
DECLARE @SQL NVARCHAR(MAX) = ''
DECLARE @TaskName NVARCHAR(MAX) = ''

DECLARE @RunSQL NVARCHAR(MAX) = 'EXEC [etl].[JSONTranslator] 
' +
ISNULL('@Step = ''' + @Step + ''',
','') +
ISNULL('@StageSchema = ''' + @StageSchema + ''',
','') +
ISNULL('@TableNameLike = ''' + @TableNameLike + ''',
','') +
ISNULL('@TableName = ''' + @TableName + ''',
','') +
ISNULL('@ETL__session_id = ''' + @ETL__session_id + ''',
','') +
ISNULL('@TargetTable = ''' + @TargetTable + ''',
','') +
ISNULL('@RawDataRowID = ''' + CONVERT(NVARCHAR(10),@RawDataRowID) + ''',
','')

SET @RunSQL = LEFT(@RunSQL,LEN(@RunSQL) - 3)

-- Start the ETL Batch
DECLARE @BatchID INT
INSERT INTO [audit].[TaskBatchLog] ([ParentID],[Step],[RunSQL],[ExecuteStart])
VALUES (@ParentBatchID,@Step,@RunSQL,(SELECT [etl].[ConvertToLocalTime](GetDate())))
SET @BatchID = SCOPE_IDENTITY()

DECLARE @WorkingSchema NVARCHAR(1000) = 'working'
DECLARE @TargetTableName NVARCHAR(1000)
DECLARE @JSON_Meta_Table_Configuration_ID NVARCHAR(1000)
DECLARE @StageTableName NVARCHAR(1000)
DECLARE @WorkingTableName NVARCHAR(1000)
DECLARE @JSON_Meta_Table_ID NVARCHAR(1000)

SELECT
	@StageTableName = '[' + [Schema] + '].[' + t.[Name] + ']'
	,@WorkingTableName = '[' + @WorkingSchema + '].[' + t.[Name] + ']'
	,@TargetTableName = '[' + tc.[TargetSchema] + '].[' + tc.[TargetTableName] + ']'
	,@JSON_Meta_Table_Configuration_ID = tc.JSON_Meta_Table_Configuration_ID
	,@JSON_Meta_Table_ID = t.JSON_Meta_Table_ID
	,@StageSchema = t.[Schema]
	,@TableName = t.[Name]
FROM [etl].[JSON_Meta_Table] t
	LEFT JOIN [etl].[JSON_Meta_Table_Configuration] tc ON t.JSON_Meta_Table_ID = tc.JSON_Meta_Table_ID
WHERE
	('[' + TargetSchema + '].[' + TargetTableName + ']' = @TargetTable)
	OR (t.[Schema] = @StageSchema AND t.[Name] = @TableName)
	OR ('[working].[' + t.Name + ']' = @TargetTable) -- for working set

-- Insert any new stage tables into the JSON_Meta_Table list
IF EXISTS (SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA IN ('apietl','stg') AND TABLE_TYPE = 'BASE TABLE' AND Table_Name NOT IN (SELECT DISTINCT Name FROM [etl].[JSON_Meta_Table]))
BEGIN

SET @SQL = '
INSERT INTO [etl].[JSON_Meta_Table] ([Schema],Name)
SELECT TABLE_SCHEMA,Table_Name FROM INFORMATION_SCHEMA.Tables WHERE TABLE_SCHEMA IN (''apietl'',''stg'') AND TABLE_TYPE = ''BASE TABLE'' AND Table_Name NOT IN (SELECT DISTINCT Name FROM [etl].[JSON_Meta_Table])
SET @Inserted = @@ROWCOUNT
'

------------------------------- RunSQL -------------------------------
EXEC [etl].[RunSQL]
	@BatchID = @BatchID
	,@TaskName = 'Update Metadata | New Configuration: Insert New Table(s)'
	,@Target = '[etl].[JSON_Meta_Table]'
	,@SQL = @SQL

END
----------------------------------------------------------------------


IF @Step IS NULL
BEGIN
SET @Message = '
/* ---------------------------------------------------------------------------------------------------------
Step 1: Select the source JSON table prefix
    Execute the desired procedure below based on the data set you want to target for data loading.
--------------------------------------------------------------------------------------------------------- */
'

SELECT @Message += '
-- ' + LEFT([Name],CHARINDEX('_',[Name]) - 1) + '
EXEC etl.JSONTranslator @Step = ''Retrieve JSON Source Load Scripts'', @StageSchema = ''' + [Schema] + ''', @TableNameLike = ''' + LEFT([Name],CHARINDEX('_',[Name]) - 1) + '''
'
FROM etl.JSON_Meta_Table
GROUP BY [Schema],LEFT([Name],CHARINDEX('_',[Name]) - 1)
ORDER BY [Schema],LEFT([Name],CHARINDEX('_',[Name]) - 1)

GOTO Success

END


IF @Step = 'Retrieve JSON Source Load Scripts'
BEGIN
SET @Message = '
/* ---------------------------------------------------------------------------------------------------------
Step 2: Select the stage JSON table
    Execute the desired procedure below based on the ' + @StageSchema + ' table with the data you want to flatten.
--------------------------------------------------------------------------------------------------------- */
'

SELECT @Message += '
-- ' + [Name] + '
EXEC etl.JSONTranslator @Step = ''Retrieve Working Table Load Scripts'', @StageSchema = ''' + [Schema] + ''', @TableName = ''' + [Name] + '''
'
FROM etl.JSON_Meta_Table
WHERE [Schema] = @StageSchema
ORDER BY [Name]

GOTO Success

END


----------------------------------------------------------------------------------------------------------------

IF @Step = 'Retrieve Working Table Load Scripts'
BEGIN

SET @Message = '
/* ---------------------------------------------------------------------------------------------------------
Step 3: Create Default Metadata + Working Table
    In this step, you will be creating the initial working data set.
    Execute the stored procedure below related to the JSON data you want to load.
--------------------------------------------------------------------------------------------------------- */
'

SET @SQL = '
SELECT  MIN(ETL__insert_datetime) ETL__insert_datetime,ETL__session_id
FROM [' + @StageSchema + '].[' + @TableName + ']
GROUP BY ETL__session_id'

CREATE TABLE #temp (ETL__insert_datetime DATETIME, ETL__session_id NVARCHAR(1000))
INSERT INTO #temp
EXEC(@SQL)

SELECT @Message += '
-- Created on ' + CONVERT(NVARCHAR(100),ETL__insert_datetime) + '
EXEC etl.JSONTranslator @Step = ''Create Working Table'', @TargetTable = ''[working].[' + @TableName + ']'', @ETL__session_id = ''' + ETL__session_id + '''
'
FROM #temp
ORDER BY [ETL__insert_datetime]

GOTO Success

END


IF @Step = 'Create Working Table'
BEGIN

DECLARE @Counter INT = 0
DECLARE @IsJSON INT = 1
DECLARE @SQLIsJSON NVARCHAR(MAX)

WHILE @IsJSON > 0
BEGIN

IF @Counter = 0
BEGIN

SET @SQL =
'
IF OBJECT_ID(''' + @WorkingTableName + ''', ''U'') IS NOT NULL DROP TABLE ' + @WorkingTableName + '
CREATE TABLE ' + @WorkingTableName + '
(
	[StageTable] [NVARCHAR](4000) NOT NULL,
	[ETL__session_id] [UNIQUEIDENTIFIER] NOT NULL,
	[ETL__insert_datetime] [DATETIME] NOT NULL,
	[ETL__multi_query_value_for_audit] [NVARCHAR](MAX) NULL,
	[id] [INT] IDENTITY(1,1) NOT NULL PRIMARY KEY,
	[parent] [INT] NOT NULL,
	[name] [NVARCHAR](4000) NOT NULL,
	[kind] [NVARCHAR](4000) NOT NULL,
	[value] [NVARCHAR](MAX) NULL,
	[HName] [NVARCHAR](4000) NULL,
	[Length] [INT] NULL,
	[IsJSON] [INT] NULL,
	[Level] [INT] NOT NULL
)
'

------------------------------- RunSQL -------------------------------
EXEC [etl].[RunSQL]
	@BatchID = @BatchID
	,@TaskName = 'Drop And Create Working Table'
	,@Target = @WorkingTableName
	,@SQL = @SQL
----------------------------------------------------------------------

SET @SQL =
'
INSERT INTO ' + @WorkingTableName + '
SELECT
	''' + @StageTableName + ''' StageTable
	,z.[ETL__session_id]
	,z.[ETL__insert_datetime]
	,z.[ETL__multi_query_value_for_audit]
	,0 parent
	,REPLACE(a.[key],''_'',''-'') [name]
	,CASE
		WHEN a.[type] = 4 THEN ''ARRAY''
		WHEN a.[type] = 5 THEN ''OBJECT''
	 ELSE ''STRING'' END [kind]
	,a.[value]
	,''AllData'' [HName]
	,NULL [Length]
	,ISNULL(IsJSON(a.[value]),0) IsJSON
	,''' + CAST(@Counter as varchar) + ''' [Level]
FROM ' + @StageTableName + ' z WITH (NOLOCK)
CROSS APPLY OPENJSON (''{"AllData":'' + json_payload +''}'')  a 
WHERE z.ETL__session_id = ''' + @ETL__session_id + '''
--AND ETL__multi_query_value_for_audit not in (578983759,578902695,578520977)
AND ID = ' + ISNULL(CONVERT(NVARCHAR(10),@RawDataRowID), 'ID') +'
SET @Inserted = @@ROWCOUNT
'
END

ELSE
SET @SQL =
'
INSERT INTO ' + @WorkingTableName + '
SELECT
	''' + @StageTableName + ''' StageTable
	,z.[ETL__session_id]
	,z.[ETL__insert_datetime]
	,z.[ETL__multi_query_value_for_audit]
	,z.id [parentid]
	,REPLACE(a.[key],''_'',''-'') [name]
	,CASE
		WHEN a.[type] = 4 THEN ''ARRAY''
		WHEN a.[type] = 5 THEN ''OBJECT''
	 ELSE ''STRING'' END [kind]
	,a.[value]
	,REPLACE(Concat(z.HName COLLATE DATABASE_DEFAULT,''_'',CASE WHEN ISNUMERIC(REPLACE(a.[key],''_'',''-'') ) = 1 THEN '''' ELSE REPLACE(a.[key],''_'',''-'') END),''__'',''_'') [HName]
	,NULL [Length]
	,ISNULL(IsJSON(a.[value]),0) IsJSON
	,''' + CAST(@Counter as varchar) + ''' [Level]
FROM ' + @WorkingTableName + ' z WITH (NOLOCK)
CROSS APPLY OPENJSON (value)  a 
WHERE IsJSON(z.[value]) = 1 and [Level] =''' + CAST(@Counter -1 as varchar)  + '''

SET @Inserted = @@ROWCOUNT
'

SET @TaskName = 'Insert Level ' + CONVERT(NVARCHAR(10),@Counter) + ' Data'

------------------------------- RunSQL -------------------------------
EXEC [etl].[RunSQL]
	@BatchID = @BatchID
	,@TaskName = @TaskName
	,@Target = @WorkingTableName
	,@SQL = @SQL
----------------------------------------------------------------------

SET @SQLIsJSON = 'SELECT @IsJSON = max(IsJSON) FROM ' + @WorkingTableName + ' WHERE IsJSON = 1 and Level = ' + CAST(@Counter AS VARCHAR)

DECLARE @CommaString VARCHAR(MAX)
SET @CommaString = ''

EXEC SP_EXECUTESQL @SQLIsJSON, N'@IsJSON INT OUT', @CommaString OUT

SET @IsJSON = @CommaString

SET @Counter = @Counter + 1

END


SET @SQL = 'CREATE NONCLUSTERED INDEX [ix_parent] ON ' + @WorkingTableName + ' ([parent]);
CREATE NONCLUSTERED INDEX [IX_Working__IsJSONLevel] ON ' + @WorkingTableName + ' ([IsJSON],[Level]) INCLUDE ([id],[parent])'

------------------------------- RunSQL -------------------------------
EXEC [etl].[RunSQL]
	@BatchID = @BatchID
	,@TaskName = 'Add Indexes'
	,@Target = @WorkingTableName
	,@SQL = @SQL
----------------------------------------------------------------------

--SET @SQL = '

--;WITH Hierarchy
--AS (
--SELECT id,parent,CONVERT(VARCHAR(1000),name) [HName]
--FROM ' + @WorkingTableName + ' WITH (NOLOCK)
--WHERE parent = 0
--UNION ALL
--SELECT a.id,a.parent,CONVERT(VARCHAR(1000),REPLACE(h.[HName] + ''_'' + CASE WHEN TRY_PARSE(a.name AS INT) IS NULL THEN a.name ELSE '''' END,''__'',''_'')) [HName]
--FROM ' + @WorkingTableName + ' a WITH (NOLOCK)
--    JOIN Hierarchy h ON	h.id = a.parent
--)

--UPDATE t
--SET	 t.[HName] = s.[HName]
--FROM ' + @WorkingTableName + ' t WITH (NOLOCK)
--	JOIN Hierarchy s ON t.[id] = s.[id]

--SET @Updated = @@ROWCOUNT
--'

--------------------------------- RunSQL -------------------------------
--EXEC [etl].[RunSQL]
--	@BatchID = @BatchID
--	,@TaskName = 'Update HName'
--	,@Target = @WorkingTableName
--	,@SQL = @SQL

SET @SQL = '

SELECT
	''' + @WorkingTableName + ''' [StageSource]
	,ROW_NUMBER() OVER(ORDER BY MIN([id])) [ColumnOrder]
	,[HName] [ColumnName]
	,[Level]
	,''NVARCHAR'' [DataType]
	,MAX([Length]) [Length]
	,MIN([id]) FirstInstanceRowNumber
	,SUM([IsNotEmptyValue]) CountIsNotEmptyValue
	,GETDATE() [ETL__insert_datetime_LastProcessed]
INTO #JSON_Meta_WorkingTableColumn
FROM
	(
	SELECT [Level],[id],[HName],[IsJSON],ISNULL(LEN(value),0) [Length],CASE WHEN value IS NOT NULL AND value <> '''' THEN 1 ELSE 0 END IsNotEmptyValue
	, row_number() over(partition by Level order by [Length] desc) rn
	,MinJay
	FROM ' + @WorkingTableName + ' aa WITH (NOLOCK)
	INNER JOIN (Select Level xlevel, MIN(IsJSON) MinJay FROM ' + @WorkingTableName + ' WITH (NOLOCK) GROUP BY Level) bb
		ON aa.Level = bb.xLevel) a
WHERE [IsJSON] = 0 or (rn = 1 and level <> 0 AND MinJay <> 0)
GROUP BY [Level],[HName]

DECLARE @RunDateTime DATETIME = [etl].[ConvertToLocalTime](GETDATE())
DECLARE @MergeAudit TABLE (MergeAction NVARCHAR(10))
MERGE [etl].[JSON_Meta_TableColumn] t
USING
	(
	SELECT
		(SELECT [JSON_Meta_Table_ID] FROM etl.JSON_Meta_Table WHERE Name = ''' + @TableName + ''') JSON_Meta_Table_ID
		,[Level]
		,[Grouping]
		,[HierarchyName]
		,ROW_NUMBER() OVER(ORDER BY [Level],[MaxColumnOrder]) [Order]
		,[DataType]
		,1 [Active]
		,GETDATE() [CreatedOn]
		,SYSTEM_USER [CreatedBy]
		,GETDATE() [LastUpdatedOn]
		,SYSTEM_USER [LastUpdatedBy]
	FROM
		(
		SELECT
			[Level]
			,LEFT([ColumnName],LEN([ColumnName]) - CHARINDEX(''_'',REVERSE([ColumnName]))) [Grouping]
			,MAX([ColumnOrder]) [MaxColumnOrder]
			,[ColumnName] [HierarchyName]
			,''NVARCHAR('' + CASE WHEN MAX([Length]) > 500 THEN ''MAX'' ELSE ''1000'' END + '')'' [DataType]
		FROM #JSON_Meta_WorkingTableColumn
		WHERE [StageSource] = ''' + @WorkingTableName + '''
		GROUP BY [StageSource],[ColumnName],[Level]
		) a
	) s
ON
	(
	t.[JSON_Meta_Table_ID] = s.[JSON_Meta_Table_ID] AND
	t.[Level] = s.[Level] AND
	t.[HierarchyName] = s.[HierarchyName]
	)
WHEN MATCHED AND
	(
	ISNULL(t.[Grouping],'''') <> ISNULL(s.[Grouping],'''') OR
	ISNULL(t.[Order],-1) <> ISNULL(s.[Order],-1) OR
	ISNULL(t.[DataType],'''') <> ISNULL(s.[DataType],'''')
	) 
THEN UPDATE SET
	[Grouping] = s.[Grouping]
	,[Order] = s.[Order]
	,[DataType] = s.[DataType]
	,[LastUpdatedOn] = s.[LastUpdatedOn]
	,[LastUpdatedBy] = s.[LastUpdatedBy]
WHEN NOT MATCHED THEN INSERT
	(
	[JSON_Meta_Table_ID]
	,[Level]
	,[Grouping]
	,[HierarchyName]
	,[Order]
	,[DataType]
	,[Active]
	,[CreatedOn]
	,[CreatedBy]
	,[LastUpdatedOn]
	,[LastUpdatedBy]
	)
VALUES
	(
	 s.[JSON_Meta_Table_ID]
	,s.[Level]
	,s.[Grouping]
	,s.[HierarchyName]
	,s.[Order]
	,s.[DataType]
	,s.[Active]
	,s.[CreatedOn]
	,s.[CreatedBy]
	,s.[LastUpdatedOn]
	,s.[LastUpdatedBy]
	)
OUTPUT $action INTO @MergeAudit;
SELECT @Inserted = [INSERT], @Updated = [UPDATE], @Deleted = [DELETE]
FROM (SELECT NULL MergeAction, 0 [Rows] UNION ALL SELECT MergeAction, 1 [Rows] FROM @MergeAudit) p
PIVOT (COUNT(rows) FOR MergeAction IN ([INSERT],[UPDATE],[DELETE])) pvt
'

------------------------------- RunSQL -------------------------------
EXEC [etl].[RunSQL]
	@BatchID = @BatchID
	,@TaskName = 'Update Column Metadata'
	,@Target = '[etl].[JSON_Meta_TableColumn]'
	,@SQL = @SQL

-- Create Default Configuration if none exists
IF NOT EXISTS
	(SELECT 1
	FROM [etl].[JSON_Meta_Table_Configuration] mtcon
		JOIN [etl].[JSON_Meta_Table] mt ON mtcon.JSON_Meta_Table_ID = mt.JSON_Meta_Table_ID
	WHERE mt.[Name] = @TableName)

BEGIN

SET @SQL = '

INSERT INTO [etl].[JSON_Meta_Table_Configuration] ([JSON_Meta_Table_ID],[TargetSchema],[TargetTableName])
VALUES (' + CONVERT(NVARCHAR(10),@JSON_Meta_Table_ID) + ',''src'',''' + @TableName + ''')

SET @Inserted = @@ROWCOUNT
'

------------------------------- RunSQL -------------------------------
EXEC [etl].[RunSQL]
	@BatchID = @BatchID
	,@TaskName = 'New Configuration: [etl].[JSON_Meta_Table_Configuration]'
	,@Target = '[etl].[JSON_Meta_Table_Configuration]'
	,@SQL = @SQL

SELECT
	@TargetTableName = '[' + TargetSchema + '].[' + TargetTableName + ']'
	,@JSON_Meta_Table_Configuration_ID = JSON_Meta_Table_Configuration_ID
FROM [etl].[JSON_Meta_Table_Configuration]
WHERE JSON_Meta_Table_ID = (SELECT JSON_Meta_Table_ID FROM [etl].[JSON_Meta_Table] WHERE [Name] = @TableName)

SET @SQL = '
INSERT INTO [etl].[JSON_Meta_TableColumn_Configuration] ([JSON_Meta_Table_Configuration_ID],[JSON_Meta_TableColumn_ID],[JSON_Meta_TableColumn_ID_MultiClause],[ColumnName],[Order],[DataType],[Unpivot],[Active])
SELECT
	' + CONVERT(NVARCHAR(10),@JSON_Meta_Table_Configuration_ID) + ' [JSON_Meta_Table_Configuration_ID]
	,tc.[JSON_Meta_TableColumn_ID]
	,NULL [JSON_Meta_TableColumn_ID_MultiClause]
	,''L'' + CONVERT(NVARCHAR(10),[Level]) + ''_'' + tc.[HierarchyName] [ColumnName]
	,tc.[Order]
	,tc.[DataType]
	,tc.[Unpivot]
	,1 [Active]
FROM [etl].[JSON_Meta_Table] t
	JOIN [etl].[JSON_Meta_TableColumn] tc ON t.JSON_Meta_Table_ID =  tc.JSON_Meta_Table_ID
WHERE t.JSON_Meta_Table_ID NOT IN 
		(SELECT DISTINCT t.JSON_Meta_Table_ID
		FROM [etl].[JSON_Meta_TableColumn_Configuration] tccon
			JOIN [etl].[JSON_Meta_Table_Configuration] tcon ON tccon.JSON_Meta_Table_Configuration_ID = tcon.JSON_Meta_Table_Configuration_ID
			JOIN [etl].[JSON_Meta_Table] t ON tcon.JSON_Meta_Table_ID = t.JSON_Meta_Table_ID)
ORDER BY [Order]

SET @Inserted = @@ROWCOUNT
'

------------------------------- RunSQL -------------------------------
EXEC [etl].[RunSQL]
	@BatchID = @BatchID
	,@TaskName = 'New Configuration: Insert Table Reference Into [etl].[JSON_Meta_TableColumn_Configuration]'
	,@Target = '[etl].[JSON_Meta_TableColumn_Configuration]'
	,@SQL = @SQL

IF
	(SELECT CASE WHEN COUNT(*) > 100 THEN 1 ELSE 0 END NeedToUnpivot
	FROM [etl].[JSON_Meta_TableColumn_Configuration]
	WHERE JSON_Meta_Table_Configuration_ID = @JSON_Meta_Table_Configuration_ID
		AND active = 1) = 1
BEGIN

SET @SQL = '
UPDATE [etl].[JSON_Meta_TableColumn_Configuration] SET [Unpivot] = ''Default'' WHERE JSON_Meta_Table_Configuration_ID = ' + CONVERT(NVARCHAR(10),@JSON_Meta_Table_Configuration_ID) + '

SET @Updated = @@ROWCOUNT
'

------------------------------- RunSQL -------------------------------
EXEC [etl].[RunSQL]
	@BatchID = @BatchID
	,@TaskName = 'New Configuration: Wide Table - Set Default to Unpivot Columns'
	,@Target = '[etl].[JSON_Meta_TableColumn_Configuration]'
	,@SQL = @SQL

END

SET @Message = '
/* ---------------------------------------------------------------------------------------------------------
NOTE: This is the initial setup of the transformation process for the ' + @TableName + ' JSON source.
As a result, the initial defaults have been automatically setup.
Follow the instuctions to continue customizing the configuration.
--------------------------------------------------------------------------------------------------------- */
'

GOTO StepThree

END

StepThree:

SET @Message += '
/* ---------------------------------------------------------------------------------------------------------
Step 4: Create the default src (ie. source/stage) table. This will be a flattened version of the JSON.
    Execute the procedure below to create the src table
--------------------------------------------------------------------------------------------------------- */

-- The following [working] table has been automatically created:
SELECT * FROM ' + @WorkingTableName + '

--This is your command(s) to drop/create/load the destination src table:
EXEC etl.JSONTranslator @Step = ''Create SRC Table'', @TargetTable = ''' + @TargetTableName + ''''


GOTO Success

END


IF @Step = 'Create SRC Table'
BEGIN

------------------------------------------------------------------------------------------------------------------

DECLARE @PivotSetTemplate NVARCHAR(MAX) = ''
DECLARE @UnpivotList NVARCHAR(MAX) = ''
DECLARE @FinalUnpivotList NVARCHAR(MAX) = ''
DECLARE @PivotList NVARCHAR(MAX) = ''
DECLARE @PivotSubquerySelect NVARCHAR(MAX) = ''
DECLARE @LevelOrderBy NVARCHAR(MAX) = ''
DECLARE @MinLevel NVARCHAR(MAX) = ''
DECLARE @UnpivotWhereIn NVARCHAR(MAX) = ''
DECLARE @FlatTableColumnsForView NVARCHAR(MAX) = ''
DECLARE @FlatTableName NVARCHAR(1000)
DECLARE @FlatTableNameOnly NVARCHAR(1000)


IF OBJECT_ID('tempdb.dbo.#Metadata','U') IS NOT NULL DROP TABLE #Metadata
SELECT
	tcon.TargetSchema
	,tcon.TargetTableName
	,tcc.[Level] [Level]
	,tcc.[Grouping]
	,REPLACE(COALESCE(tccon.[ColumnName], 'L' + CONVERT(NVARCHAR(10),tcc.[Level]) + '_' + tcc.[HierarchyName]),'@','') [ColumnName]
	,tcc.[HierarchyName]
	,COALESCE(tccon.[Order],tcc.[Order]) [Order]
	,COALESCE(tccon.[DataType],tcc.[DataType]) [DataType]
	,CONVERT(NVARCHAR(100),tccon.[Unpivot]) [Unpivot]
	,'[' + tcon.TargetSchema + '].[' + tcon.TargetTableName + ']' TableName
	,tccon.[Active] [Active]
INTO #Metadata
FROM [etl].[JSON_Meta_Table_Configuration] tcon
	JOIN [etl].[JSON_Meta_TableColumn_Configuration] tccon ON tcon.JSON_Meta_Table_Configuration_ID = tccon.JSON_Meta_Table_Configuration_ID
	LEFT JOIN [etl].[JSON_Meta_TableColumn] tcc ON tcon.JSON_Meta_Table_ID = tcc.JSON_Meta_Table_ID AND tccon.JSON_Meta_TableColumn_ID = tcc.JSON_Meta_TableColumn_ID
WHERE ('[' + tcon.TargetSchema + '].[' + tcon.TargetTableName + ']' = @TargetTableName OR tcon.JSON_Meta_Table_Configuration_ID = @JSON_Meta_Table_Configuration_ID)
	AND tccon.[Active] = 1

SET @FlatTableName = (SELECT DISTINCT '[' + TargetSchema + '].[' + TargetTableName + ']' FROM #Metadata)
SET @FlatTableNameOnly = (SELECT DISTINCT TargetTableName FROM #Metadata)

SET @MinLevel = (SELECT MIN([Level]) FROM #Metadata)

SELECT
	@PivotList += '	,[' + ColumnName + ']
'
	,@PivotSubquerySelect += '		,[' + ColumnName + ']
'
FROM #Metadata
WHERE [Unpivot] IS NULL
ORDER BY [Order]


SELECT @LevelOrderBy += 'L' + CONVERT(NVARCHAR(10),[Level]) + '.[id],'
FROM #Metadata
GROUP BY [Level]
ORDER BY [Level]


SET @LevelOrderBy = LEFT(@LevelOrderBy,LEN(@LevelOrderBy) - 1)

SELECT TOP 1
	@UnpivotList += ISNULL('	,up.[HName] [' + [Unpivot] + '_Key]
	,up.[value] [' + [Unpivot] + '_Value]','')
	,@FinalUnpivotList += ISNULL('	,[' + [Unpivot] + '_Key]
	,[' + [Unpivot] + '_Value]','')
FROM
	(
	SELECT TOP 1 [Unpivot] FROM #Metadata WHERE [Unpivot] IS NOT NULL
	UNION ALL
	SELECT NULL [Unpivot]
	) a -- Limited to only one unpivot because we do not expect a use case for multiple unpivots in the same set

SELECT @UnpivotWhereIn += ISNULL('			,''' + [HierarchyName] + '''
','')
FROM #Metadata
WHERE [Unpivot] IS NOT NULL

SELECT @PivotSetTemplate += [LevelHeader] + CASE WHEN [PartitionedRowNumber] = 1 THEN '		(
		SELECT
			p.[id]
			,p.[parent]
			,[ETL__multi_query_value_for_audit]
' + [AllColumns] + '		FROM
			(
			SELECT DISTINCT [id],[parent],[ETL__multi_query_value_for_audit]
			FROM ' + @WorkingTableName + ' WITH (NOLOCK)
			WHERE [Level] =	' +  CONVERT(NVARCHAR(10),[Level] - 1)  + ' AND ISJSON = 1
			) p
' ELSE '' END + '			LEFT JOIN
			(
			SELECT s.[id],s.[parent],oj.*
			FROM ' + @WorkingTableName + ' s WITH (NOLOCK)
				CROSS APPLY
				(SELECT * FROM OPENJSON (s.value) WITH
					(
					[EmptySet] NVARCHAR(1000) N''$."@EmptySet"''
' + [OJWith] + '					)
				) oj
			WHERE [Level] = ' +  CONVERT(NVARCHAR(10),[Level] - 1)  + ' AND IsJSON = 1 AND [kind] = ''Object'' AND (' + [HNameWhere] + ')
			) [' + [Grouping] + '] ON p.[id] = [' + [Grouping] + '].[id]' + CASE WHEN LEAD([Level],1,NULL) OVER(ORDER BY [Level]) <> [Level] OR LEAD([Level],1,NULL) OVER(ORDER BY [Level]) IS NULL THEN '
		) L' + CONVERT(NVARCHAR(10),[Level]) + CASE WHEN [Level] <> @MinLevel THEN ' ON L' + CONVERT(NVARCHAR(10),[Level] - 1) + '.[id] = L' + CONVERT(NVARCHAR(10),[Level]) + '.[parent]
' ELSE '
' END ELSE '
' END
FROM
	(
	SELECT
		[RowNumber]
		,[PartitionedRowNumber]
		,[DenseRank]
		,[Level]
		,[Grouping]
		,CASE WHEN [PartitionedRowNumber] = 1 THEN '		-------------------- L' + CONVERT(NVARCHAR(10),[Level]) + ' ------------------
' + CASE WHEN [RowNumber] = 1 THEN '' ELSE '		LEFT JOIN
' END ELSE '' END [LevelHeader]
		,CASE WHEN [PartitionedRowNumber] = 1 THEN [AllColumns] ELSE '' END [AllColumns]
		,[ColumnListWithAlias]
		,[OJWith]
		,[HNameWhere]
	FROM
		(
		SELECT
			ROW_NUMBER() OVER(ORDER BY [Level]) [RowNumber]
			,ROW_NUMBER() OVER(PARTITION BY [Level] ORDER BY [Level]) [PartitionedRowNumber]
			,DENSE_RANK() OVER(ORDER BY [Level]) [DenseRank]
			,*
		FROM
			(
			SELECT DISTINCT
				[Level]
				,[Grouping]
				,ISNULL(REPLACE((SELECT '			,[' + [ColumnName] + ']
' [text()]
				FROM #Metadata l WITH (NOLOCK)
				WHERE a.[Level] = l.[Level] AND l.[Unpivot] IS NULL
				ORDER BY l.[Order]
				FOR XML PATH ('')),'&#x0D;',''),'') [AllColumns]
				,ISNULL(REPLACE((SELECT '			,' + [Grouping] + '.[' + [ColumnName] + ']
' [text()]
				FROM #Metadata l WITH (NOLOCK)
				WHERE a.[Level] = l.[Level] AND a.[Grouping] = l.[Grouping] AND l.[Unpivot] IS NULL
				ORDER BY l.[Order]
				FOR XML PATH ('')),'&#x0D;',''),'') [ColumnListWithAlias]
				,ISNULL(REPLACE((SELECT '					,[' + [ColumnName] + '] ' + DataType + ' N''$."' + CASE WHEN [HierarchyName] NOT LIKE '%[_]%'THEN [HierarchyName] ELSE REPLACE(RIGHT([HierarchyName],CHARINDEX('_',REVERSE([HierarchyName])) - 1),'-','_') END + '"''
' [text()]
				FROM #Metadata l WITH (NOLOCK)
				WHERE a.[Level] = l.[Level] AND a.[Grouping] = l.[Grouping] AND l.[Unpivot] IS NULL
				ORDER BY l.[Order]
				FOR XML PATH ('')),'&#x0D;',''),'') [OJWith]
				,ISNULL('[HName] = ''' + [Grouping] + ''' OR [HName] = ''' + [Grouping] + '_''','') [HNameWhere]
			FROM #Metadata a
			) a
		) a
	) a
	ORDER BY [Level]


SET @SQL =
'IF OBJECT_ID(''' + @FlatTableName + ''',''U'') IS NOT NULL DROP TABLE ' + @FlatTableName

------------------------------- RunSQL -------------------------------
EXEC [etl].[RunSQL]
	@BatchID = @BatchID
	,@TaskName = 'Drop And Create Destination Table'
	,@Target = @FlatTableName
	,@SQL = @SQL

SET @SQL = '
SELECT
	ROW_NUMBER() OVER(ORDER BY MAX([OrderBy])) [SK]
	,[ETL__multi_query_value_for_audit]
' + @FinalUnpivotList + '
' + @PivotList + 'INTO ' + @FlatTableName + '
FROM
(
SELECT
	ROW_NUMBER() OVER(ORDER BY COALESCE(up.[id],p.[id])) [OrderBy]
	,COALESCE(up.[ETL__multi_query_value_for_audit],p.[ETL__multi_query_value_for_audit]) [ETL__multi_query_value_for_audit]
' + @UnpivotList + '
' + @PivotList + '
FROM
	(
	-- Unpivot
	SELECT [id],[parent],[HName],[value],[Level],[ETL__multi_query_value_for_audit]
	FROM ' + @WorkingTableName + ' WITH (NOLOCK)
	WHERE value IS NOT NULL AND value <> ''''
		AND [HName] IN (''''
' + @UnpivotWhereIn + '		)
	) up
	FULL OUTER JOIN
	(
	-- Pivoted Set
	SELECT
		L' + @MinLevel + '.[id]
' + @PivotSubquerySelect + '
	,L' + @MinLevel + '.[ETL__multi_query_value_for_audit]
	FROM
' + @PivotSetTemplate + '	) p
	ON up.[parent] = p.[id]
) a
GROUP BY
	[ETL__multi_query_value_for_audit]
' + @FinalUnpivotList + '
' + @PivotList

------------------------------- RunSQL -------------------------------
EXEC [etl].[RunSQL]
	@BatchID = @BatchID
	,@TaskName = 'Populate Destination Table'
	,@Target = @FlatTableName
	,@SQL = @SQL

SET @Message += '
/* ---------------------------------------------------------------------------------------------------------
Step 5: Configure!
    Use the scripts below to iterate through revisions of your desired table structure
--------------------------------------------------------------------------------------------------------- */

-------------------- Use the scripts below to iterate through revisions of your desired table structure ----------------------

-- The following table has been created:
SELECT * FROM ' + @FlatTableName + '

--This is your command(s) to drop/create/load the destination src table:
EXEC etl.JSONTranslator @Step = ''Create SRC Table'', @TargetTable = ''' + @TargetTable + ''''

SET @Message += '

---- RENAME TABLE ----
UPDATE [etl].[JSON_Meta_Table_Configuration] SET TargetTableName = ''NewTableNameHere'' WHERE [JSON_Meta_Table_Configuration_ID] = ' + CONVERT(NVARCHAR(10),@JSON_Meta_Table_Configuration_ID) + '

---- RECONFIGURE COLUMNS ----
'

SELECT @Message += CASE WHEN [ColumnName] IS NOT NULL THEN 'UPDATE [etl].[JSON_Meta_TableColumn_Configuration] SET [Active] = ' + CONVERT(NVARCHAR(1),[Active]) + ',[Unpivot] = NULL,[ColumnName] = ''' + [ColumnName] + ''' WHERE [JSON_Meta_TableColumn_Configuration_ID] = ' + CONVERT(NVARCHAR(10),[JSON_Meta_TableColumn_Configuration_ID]) + '
' ELSE 'N/A' END
FROM [etl].[JSON_Meta_TableColumn_Configuration]
WHERE JSON_Meta_Table_Configuration_ID = @JSON_Meta_Table_Configuration_ID
ORDER BY [Order]

SELECT
	@FlatTableColumnsForView += '	,CONVERT(NVARCHAR(MAX),[' + COLUMN_NAME + ']) [' + COLUMN_NAME + ']
'
	
FROM Information_Schema.columns 
WHERE TABLE_NAME = @FlatTableNameOnly
AND TABLE_SCHEMA = 'src'
and COLUMN_NAME <> 'ETL__multi_query_value_for_audit'
ORDER BY ORDINAL_POSITION

SET @Message += '
/* ---------------------------------------------------------------------------------------------------------
Step 6: Create your preods view
    The script below is a starting point for use in creating the preods view that will feed the ods layer
	Modify as desired and create as many as desired to use as the final staging step

	IMPORTANT:
	-- ** You must define your PK by adding "_K" to the aliased column names ** --
	-- ** You must change the datatypes for your Key columns (NVARCHAR(MAX) will not work) ** --
--------------------------------------------------------------------------------------------------------- */


IF OBJECT_ID(''' + REPLACE(@FlatTableName,'[src]','[preods]') + ''', ''V'') IS NOT NULL DROP VIEW ' + REPLACE(@FlatTableName,'[src]','[preods]') + '
EXEC(''
CREATE VIEW ' + REPLACE(@FlatTableName,'[src]','[preods]') + '
AS

SELECT DISTINCT
	[ETL__multi_query_value_for_audit]
' + @FlatTableColumnsForView + 'FROM ' + @FlatTableName + ' WITH (NOLOCK)
'')
GO

/* ---------------------------------------------------------------------------------------------------------
Step 7: Create your ods table and related objects for the ods layer
    Run the following script to create your ods tables
--------------------------------------------------------------------------------------------------------- */

----------- Run the following to automatically create your ODS merge script -----------
EXEC [etl].[JSONTranslator] @Step = ''Generate ODS Create Scripts'', @StageSchema = ''' + @StageSchema + ''', @TableName = ''' + @TableName + '''

/* ---------------------------------------------------------------------------------------------------------
Step 8: Create your ods merge
    Run the following script to create the ods merge
--------------------------------------------------------------------------------------------------------- */

----------- Run the following to automatically create your ODS merge scripts -----------
EXEC [etl].[JSONTranslator] @Step = ''Generate ODS Merges''

/* ---------------------------------------------------------------------------------------------------------
Step 9: Manual Run the ETL and validate the results
    Run the following script to kick off the loading process for all tables that spawn from the JSON source
--------------------------------------------------------------------------------------------------------- */

----------- Your ETL is all setup! Use the following script to test a full load -----------
EXEC [etl].[JSONTranslator] @Step = ''Run ETL'', @StageSchema = ''' + @StageSchema + ''', @TableName = ''' + @TableName + '''

-- Verify your results
SELECT * FROM [audit].[TaskBatchLogSummary]
-- Verify that all "IsLoaded" flags have been set to 1 (true)
SELECT * FROM [apietl].[GenericNoAuth_LiveStreams]

/*
Important notes about this process:
• The "Run ETL" script above will automatically be triggered after new JSON payloads are delivered
• If you have to re-processed a set of payloads, just reset the "IsLoaded" flag to 0 for the rows that need to be re-processed
• Extensive audit logging is available in the following tables / views:
	• SELECT * FROM [audit].[TaskLog]
		- This table holds the individual scripts executed and the details related to the execution of the scripts
		- A "Task" is a single execution of a merge, update, upsert, etc.
	• SELECT * FROM [audit].[TaskBatchLog]
		- This table contains parent/child relationships of "Batches" executed
		- A "Batch" references a set of "Tasks"
	• SELECT * FROM [audit].[TaskBatchLogSummary]
		- This view provides a convenient way to view the parent/child relationships with intented batch names
		- This view provides a rolled-up perspective of the tasks included in each batch
		- A drill-through query is provided to to allow an easy select of the tasks in each batch
	• SELECT * FROM [etl].[Task]
		- This table contains the sql scripts used for the merges and is updated via [etl].[ReloadTasks]
*/
'

GOTO Success

END

IF @Step = 'Merge to ODS'

BEGIN

SELECT
	@SQL = [RunSQL]
	,@TaskName = [TaskName]
FROM [etl].[Task]
WHERE [Target] = @TargetTable

------------------------------- RunSQL -------------------------------
EXEC [etl].[RunSQL]
	@BatchID = @BatchID
	,@TaskName = @TaskName
	,@Target = @TargetTable
	,@SQL = @SQL
GOTO Success
----------------------------------------------------------------------


END


IF @Step = 'Update IsLoaded Flag'

BEGIN

SET @SQL = '
IF	(
	SELECT SUM(CONVERT(INT,IsError))
	FROM [audit].[TaskLog]
	WHERE BatchID IN (SELECT ID FROM [audit].[TaskBatchLog] WHERE ParentID IN (SELECT ParentID FROM [audit].[TaskBatchLog] WHERE ID = ' + CONVERT(NVARCHAR(10),@BatchID) + '))
	) = 0 -- Meaning No Errors
----- Successfull Load: Flag Appropriately -----
UPDATE ' + @StageTableName + '
SET IsLoaded = 1
WHERE ETL__session_id IN
	(
	SELECT DISTINCT [ETL__session_id]
	FROM ' + @StageTableName + '
	WHERE IsLoaded = 0 AND [ETL__session_id] = ''' + @ETL__session_id + '''
	)
	AND ID = ' + ISNULL(CONVERT(NVARCHAR(10),@RawDataRowID), 'ID') + '
SET @Updated = @@ROWCOUNT
'
print @SQL
------------------------------- RunSQL -------------------------------
EXEC [etl].[RunSQL]
	@BatchID = @BatchID
	,@TaskName = 'Set IsLoaded = 1 for all relevant rows'
	,@Target = @StageTableName
	,@SQL = @SQL
GOTO Success
----------------------------------------------------------------------

END


IF @Step = 'Generate ODS Create Scripts'
BEGIN

SET @SQL = 'DECLARE @SQL NVARCHAR(MAX)'

SELECT @SQL += '
SET @SQL = (SELECT [etl].[SQLSchemaSync](''preods'',''ods'',''' + REPLACE(REPLACE(REPLACE(r.[ViewName],'[preods].',''),'[',''),']','') + ''',''type4''))
PRINT CAST(@SQL AS NTEXT)
--EXEC(@SQL)
'
FROM [etl].[JSON_Meta_Table_Configuration] tc
	CROSS APPLY
	(
		SELECT '[' + referencing_schema_name + '].[' + referencing_entity_name + ']' [ViewName]
		FROM SYS.DM_SQL_REFERENCING_ENTITIES('[' + tc.[TargetSchema] + '].[' + tc.[TargetTableName] + ']', 'OBJECT')
	) r
WHERE tc.[JSON_Meta_Table_ID] = (SELECT [JSON_Meta_Table_ID] FROM [etl].[JSON_Meta_Table] WHERE [Name] = @TableName)

------------------------------- RunSQL -------------------------------
EXEC [etl].[RunSQL]
	@BatchID = @BatchID
	,@TaskName = 'Generate ODS Layer Create Scripts'
	,@Target = ''
	,@SQL = @SQL
GOTO Success
----------------------------------------------------------------------

END


IF @Step = 'Generate ODS Merges'
BEGIN

------------------------------- RunSQL -------------------------------
EXEC [etl].[RunSQL]
	@BatchID = @BatchID
	,@TaskName = 'Generate ODS Merges'
	,@Target = '[etl].[Task]'
	,@SQL = 'EXEC [etl].[ReloadTasks]'
GOTO Success
----------------------------------------------------------------------

END



IF @Step = 'Run ETL'
BEGIN

SET @SQL = '
SELECT
	ROW_NUMBER() OVER(ORDER BY ETL__multi_query_value_for_audit, [ETL__insert_datetime]) [Order_WorkingTableLoad]
	,''' + @StageSchema  + ''' [Schema]
	,''' + @TableName + ''' [Name]
	,[ETL__session_id]
	,ID
FROM [' + @StageSchema  + '].[' + @TableName  + ']
WHERE IsLoaded = 0
--GROUP BY
--	[ETL__session_id]
'

IF OBJECT_ID('tempdb.dbo.#ETLSession','U') IS NOT NULL DROP TABLE #ETLSession
CREATE TABLE #ETLSession ([Order_WorkingTableLoad] INT,[Schema] NVARCHAR(4000) NULL,[Name] NVARCHAR(MAX),[ETL__session_id] NVARCHAR(MAX), ID INT NOT NULL)
INSERT INTO #ETLSession
EXEC(@SQL)


SET @SQL = ''

SELECT @SQL += '
EXEC [etl].[JSONTranslator]
	@Step = ''Process ETL Session''
	,@StageSchema = ''' + [Schema] + '''
	,@TableName = ''' + [Name] + '''
	,@ETL__session_id = ''' + CONVERT(NVARCHAR(100),[ETL__session_id]) + '''
	,@ParentBatchID = ' + CONVERT(NVARCHAR(10),@BatchID) + '
	,@RawDataRowID = ' + CONVERT(NVARCHAR(10),ID) + '
'
FROM #ETLSession
ORDER BY [Order_WorkingTableLoad]

--INSERT INTO @IsSuccess
EXEC(@SQL)

--IF (SELECT IsSuccess FROM @IsSuccess) = 0 GOTO Fail -- May get slower as task log grows, but not able to pull success bit from etl.RunSQL proc :(
GOTO Success

END

IF @Step = 'Process ETL Session'
BEGIN

SET @SQL = 
'
EXEC etl.JSONTranslator
	@Step = ''Create Working Table''
	,@TargetTable = ''[working].[' + @TableName + ']''
	,@ETL__session_id = ''' + @ETL__session_id + '''
	,@ParentBatchID = ' + CONVERT(NVARCHAR(10),@BatchID) + '
	,@RawDataRowID = ' + CONVERT(NVARCHAR(10),@RawDataRowID) + '
'

EXEC(@SQL)

SET @SQL = ''
SELECT @SQL += '
EXEC etl.JSONTranslator
	@Step = ''Create SRC Table''
	,@TargetTable = ''[' + tc.[TargetSchema] + '].[' + tc.[TargetTableName] + ']''
	,@ParentBatchID = ' + CONVERT(NVARCHAR(10),@BatchID) + '
'
FROM [etl].[JSON_Meta_Table] t
	JOIN [etl].[JSON_Meta_Table_Configuration] tc ON t.[JSON_Meta_Table_ID] = tc.[JSON_Meta_Table_ID]
WHERE t.[Schema] = @StageSchema AND t.[Name] = @TableName

EXEC(@SQL)


SET @SQL = ''
SELECT @SQL += '
EXEC etl.JSONTranslator
	@Step = ''Merge to ODS''
	,@TargetTable = ''' + tsk.[Target] + '''
	,@ParentBatchID = ' + CONVERT(NVARCHAR(10),@BatchID) + '
'
FROM [etl].[JSON_Meta_Table] t
	JOIN [etl].[JSON_Meta_Table_Configuration] tc ON t.[JSON_Meta_Table_ID] = tc.[JSON_Meta_Table_ID]
	CROSS APPLY
	(
	-- All Views that use the src table
	SELECT '[' + referencing_schema_name + '].[' + referencing_entity_name + ']' [ViewName]
	FROM SYS.DM_SQL_REFERENCING_ENTITIES('[' + tc.[TargetSchema] + '].[' + tc.[TargetTableName] + ']', 'OBJECT')
	) r
	JOIN [etl].[Task] tsk ON r.[ViewName] = tsk.[Source]
WHERE t.[Schema] = @StageSchema AND t.[Name] = @TableName AND tsk.[Active] = 1

EXEC(@SQL)


SET @SQL = '
EXEC etl.JSONTranslator
	@Step = ''Update IsLoaded Flag''
	,@StageSchema = ''' + @StageSchema + '''
	,@TableName = ''' + @TableName + '''
	,@ETL__session_id = ''' + @ETL__session_id + '''
	,@ParentBatchID = ' + CONVERT(NVARCHAR(10),@BatchID) + '
	,@RawDataRowID = ' + CONVERT(NVARCHAR(10),@RawDataRowID) + '
'

EXEC(@SQL)

GOTO Success

END

Success:

------------- Print Looping -------------
BEGIN
	IF LEN(@Message) < 16000
	PRINT CAST(@Message AS NTEXT)
	IF LEN(@Message) >= 16000
		BEGIN
		Declare @mmax int
		Declare @mcount int = 1
		SET @mmax = CEILING(CAST(LEN(@Message) as float) / 16000)
		WHILE @mcount <= @mmax
		BEGIN
		PRINT CAST(SUBSTRING(@Message,((@mcount-1) * 16000 + 1), 16000) AS NTEXT)
		SET @mcount += 1
		END
	END
END

UPDATE [audit].[TaskBatchLog] SET [ExecuteEnd] = (SELECT [etl].[ConvertToLocalTime](GetDate())) WHERE ID = @BatchID

--IF (SELECT SUM(CONVERT(INT,IsError)) FROM [audit].[TaskLog] WHERE BatchID = @BatchID) > 0 -- May get slower as task log grows, but not able to pull success bit from etl.RunSQL proc :(
--GOTO Fail

GOTO Finish

/*
---------------- for Troubleshooting ----------------

SELECT
	@StageSchema StageSchema
	,@TableName TableName
	,@ETL__session_id ETL__session_id
	,@TargetTable ReloadDestinationTable
	,'------'
	,@WorkingSchema WorkingSchema
	,@TargetTableName TargetTableName
	,@JSON_Meta_Table_Configuration_ID JSON_Meta_Table_Configuration_ID
	,@StageTableName StageTableName
	,@WorkingTableName WorkingTableName
	,'------'
	,@SQL [SQL]
	,@PivotSetTemplate PivotSetTemplate
	,@UnpivotList UnpivotList
	,@FinalUnpivotList FinalUnpivotList
	,@PivotList PivotList
	,@PivotSubquerySelect PivotSubquerySelect
	,@LevelOrderBy LevelOrderBy
	,@MinLevel MinLevel
	,@UnpivotWhereIn UnpivotWhereIn
	,@FlatTableColumnsForView FlatTableColumnsForView
	,@FlatTableName FlatTableName

*/

Finish:



GO
GRANT EXECUTE ON  [etl].[JSONTranslator] TO [db_SSB_IE_Permitted]
GO
