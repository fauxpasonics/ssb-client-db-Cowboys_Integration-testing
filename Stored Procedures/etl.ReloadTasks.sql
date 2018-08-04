SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
DECLARE
@ETL NVARCHAR(400) = NULL --'Update Base Data ETL'
,@ResetDefaults BIT = 0
,@DefaultActive BIT = 1
,@TaskID INT = NULL
EXEC [etl].[ReloadTasks] @ETL = @ETL, @ResetDefaults = @ResetDefaults, @DefaultActive = @DefaultActive
*/

CREATE PROC [etl].[ReloadTasks]
(@ETL NVARCHAR(400) = NULL
,@ResetDefaults BIT = 0
,@DefaultActive BIT = 1
,@TaskID INT = NULL)

AS
BEGIN

----- need to add "package" tasks to the task table in here somewhere -----

IF OBJECT_ID('tempdb.dbo.#SourceTasks','U') IS NOT NULL DROP TABLE #SourceTasks

--/*################################################### Update dev.InfoSchema to pull any changes ###################################################*/
--EXEC [dev].[ReloadInfoSchema]

/*################################################### Recurse through the batch table to get all job steps and configurations ###################################################*/
;WITH
AllETLJobSteps AS
(SELECT ParentID parent,ID
FROM etl.Batch
WHERE (BatchName = @ETL OR @ETL IS NULL) AND ParentID IS NULL
UNION ALL
SELECT parent,s.ID child
FROM AllETLJobSteps d
JOIN etl.Batch s ON d.ID = s.ParentID)

/*################################################### Get the last modified Date/Time of all tables & views ###################################################*/
,LastModified AS
(
SELECT '[' + s.name + '].[' + t.name + ']' TableName,t.modify_date ModifiedDate
FROM 
	(
	SELECT [name],[schema_id],[modify_date]FROM sys.tables
	UNION ALL
	SELECT [name],[schema_id],[modify_date] FROM sys.views
	UNION ALL
	SELECT r.ROUTINE_NAME name,s.[schema_id],r.LAST_ALTERED [modify_date]
	FROM INFORMATION_SCHEMA.ROUTINES r
		JOIN sys.schemas s ON r.ROUTINE_SCHEMA = s.name
	WHERE r.ROUTINE_TYPE = 'PROCEDURE'	
	) t
	JOIN sys.schemas s ON t.[schema_id] = s.[schema_id]
)


/*################################################### ...And create #SourceTasks to use as the source of the merge ###################################################*/
SELECT
	t.BatchID
	,t.ExecutionOrder
	,t.TaskName
	,CASE WHEN t.[Target] LIKE '%IFMS[_]%' AND t.[Target] LIKE '%ods%' THEN 'sync' ELSE t.TaskType END TaskType
	,t.[SQL]
	,t.[Target]
	,t.[Source]
	,t.CustomMatchOn
	,t.ExcludeColumns
	,t.[Execute]
	,t.FailBatchOnFailure
	,t.SuppressResults
	,@DefaultActive Active
	,CASE WHEN ISNULL(lmt.ModifiedDate,'1/1/1900') > ISNULL(lms.ModifiedDate,'1/1/1900') THEN [etl].[ConvertToLocalTime](lmt.ModifiedDate) ELSE [etl].[ConvertToLocalTime](lms.ModifiedDate) END LastUpdated
INTO #SourceTasks
FROM etl.TaskGenerator t
	LEFT JOIN LastModified lmt ON t.[Target] = lmt.TableName
	LEFT JOIN LastModified lms ON t.[Source] = lms.TableName
WHERE BatchID IN (SELECT ID FROM AllETLJobSteps)

/*################################################### Merge "Source Tasks" into the Tasks table ###################################################*/
DECLARE @RowCountBefore INT = 0, @RowCountAfter INT = 0, @Inserted INT = 0, @Updated INT = 0
SET @RowCountBefore = (SELECT COUNT(*) RowCountBefore FROM etl.Task)
DECLARE @RunDateTime DATETIME = [etl].[ConvertToLocalTime](GETDATE())
DECLARE @MergeAudit TABLE (MergeAction NVARCHAR(10))
	MERGE etl.Task t
	USING #SourceTasks s
	ON (t.[BatchID] = s.[BatchID] AND t.[Target] = s.[Target])
	WHEN MATCHED AND
		(@ResetDefaults = 1 AND (ISNULL(t.[TaskName],-1) <> ISNULL(s.[TaskName],-1) OR ISNULL(t.[SQL],-1) <> ISNULL(s.[SQL],-1) OR ISNULL(t.[Source],-1) <> ISNULL(s.[Source],-1) OR ISNULL(t.[CustomMatchOn],-1) <> ISNULL(s.[CustomMatchOn],-1) OR ISNULL(t.[ExcludeColumns],-1) <> ISNULL(s.[ExcludeColumns],-1) OR ISNULL(t.[Execute],-1) <> ISNULL(s.[Execute],-1) OR ISNULL(t.[FailBatchOnFailure],-1) <> ISNULL(s.[FailBatchOnFailure],-1) OR ISNULL(t.[SuppressResults],-1) <> ISNULL(s.[SuppressResults],-1) OR ISNULL(t.[Active],-1) <> ISNULL(s.[Active],-1)))
		OR (t.[LUPDATED_DATE] < s.[LastUpdated] AND s.[LastUpdated] IS NOT NULL) -- table or view used as source or target has been updated since the last time this proc was run
	THEN UPDATE SET t.[BatchID] = s.[BatchID], t.[ExecutionOrder] = s.[ExecutionOrder], t.[TaskName] = s.[TaskName], t.[TaskType] = s.[TaskType], t.[SQL] = s.[SQL], t.[Target] = s.[Target],t.[Source] = s.[Source], t.[CustomMatchOn] = s.[CustomMatchOn], t.[ExcludeColumns] = s.[ExcludeColumns], t.[Execute] = s.[Execute], t.[FailBatchOnFailure] = s.[FailBatchOnFailure], t.[SuppressResults] = s.[SuppressResults], t.[Active] = s.[Active], t.[LUPDATED_DATE] = @RunDateTime
	WHEN NOT MATCHED THEN INSERT ([BatchID],[ExecutionOrder],[TaskName],[TaskType],[SQL],[Target],[Source],[CustomMatchOn],[ExcludeColumns],[Execute],[FailBatchOnFailure],[SuppressResults],[Active],[CREATED_DATE],[LUPDATED_DATE])
	VALUES (s.[BatchID],s.[ExecutionOrder],s.[TaskName],s.[TaskType],s.[SQL],s.[Target],s.[Source],s.[CustomMatchOn],s.[ExcludeColumns],s.[Execute],s.[FailBatchOnFailure],s.[SuppressResults],s.[Active],@RunDateTime,@RunDateTime)
	WHEN NOT MATCHED BY SOURCE AND (t.BatchID IN (SELECT DISTINCT BatchID FROM #SourceTasks) OR t.BatchID NOT IN (SELECT ID FROM etl.Batch)) THEN UPDATE SET t.Active = 0, t.[LUPDATED_DATE] = @RunDateTime
	OUTPUT $action INTO @MergeAudit;
SET @RowCountAfter = (SELECT COUNT(*) RowCountAfter FROM etl.Task)
SELECT @Inserted = [INSERT], @Updated = [UPDATE]
FROM (SELECT NULL MergeAction, 0 [Rows] UNION ALL SELECT MergeAction, 1 [Rows] FROM @MergeAudit) p
PIVOT (COUNT(rows) FOR MergeAction IN ([INSERT],[UPDATE],[DELETE])) pvt

/*################################################### Update RunSQL tasks for newly inserted or newly changed tasks that are active ###################################################*/
UPDATE etl.Task
SET RunSQL = etl.SQLGenerator([TaskName],[TaskType],[SQL],[Target],[Source],[CustomMatchOn],[ExcludeColumns])
WHERE Active = 1 AND [LUPDATED_DATE] = @RunDateTime

UPDATE etl.Task
SET RunSQL = etl.SQLGenerator([TaskName],[TaskType],[SQL],[Target],[Source],[CustomMatchOn],[ExcludeColumns]),[LUPDATED_DATE] = @RunDateTime
WHERE ID = @TaskID
SET @Updated = @Updated + @@RowCount

SELECT
	(SELECT COUNT(*) FROM #SourceTasks) TasksAnalized
	,@RowCountBefore TaskCountBefore
	,@RowCountAfter TaskCountAfter
	,@Inserted TasksAdded
	,@Updated TasksUpdated
	,(SELECT COUNT(*) FROM etl.Task WHERE Active = 1) ActiveTaskCount
	,(SELECT COUNT(*) FROM etl.Task WHERE Active = 0) InactiveTaskCount

END


GO
