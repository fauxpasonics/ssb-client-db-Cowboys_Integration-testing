SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [etl].[TaskModule_StandardSet]
AS

/*
This view creates task sets to use as the source of the merge included in the etl.ReloadTasks stored procedure
Supports Task Types:
	SQL
	Truncate
	Sync
	Insert
	Update
	Upsert
	Syncsoftdelete
	Type1
	Type2
*/

/* Base Task Set With Default Configuration Rules */
WITH BaseTasks AS
(
SELECT
	a.BatchID
	,COALESCE(t.ExecutionOrder,a.ExecutionOrder) ExecutionOrder
	,CASE
		WHEN COALESCE(t.[Source],a.[Source]) LIKE '(%' THEN '(Custom Query) -> '
		WHEN COALESCE(t.[Source],a.[Source]) IS NOT NULL THEN COALESCE(t.[Source],a.[Source]) + ' -> '
		ELSE ''
	END + a.[Target] TaskMovement
	,COALESCE(t.TaskType,a.TaskType) TaskType
	,COALESCE(t.[SQL],a.[SQL]) [SQL]
	,a.[Target]
	,COALESCE(t.[Source],a.[Source]) [Source]
	,a.CustomMatchOn
	,a.ExcludeColumns
	,a.[Execute]
	,a.FailBatchOnFailure
	,a.SuppressResults
FROM
	(
	SELECT
		a.ID BatchID
		,CASE WHEN a.[ExecuteInParallel] = 1 THEN 1 ELSE ROW_NUMBER() OVER(PARTITION BY a.ID ORDER BY (SELECT 1)) END ExecutionOrder
		,a.TaskType TaskType
		,ISNULL(REPLACE([SQL],'{target}',t.SchemaName + '.' + CASE WHEN a.TaskType = 'Type2' THEN REPLACE(t.TableName, '_Hist', '') ELSE t.TableName END),NULL) [SQL]
		,t.SchemaName + '.' + t.TableName [Target]
		,ISNULL(REPLACE(a.SourceQuery,'{source}',s.SchemaName + '.' + s.TableName),s.SchemaName + '.' + s.TableName) [Source]
		,a.CustomMatchOn
		,a.ExcludeColumns
		,a.[Execute]
		,a.FailBatchOnFailure
		,a.SuppressResults
	FROM etl.Batch a
		LEFT JOIN (SELECT DISTINCT i.SchemaName,i.TableName FROM etl.InfoSchema i WHERE TableType = 'Table') t
			ON (a.TaskType IN ('sql','truncate','sync','insert','update','upsert','syncsoftdelete','type1','type2') AND '[' + a.TargetSchema + ']' = t.[SchemaName])
		LEFT JOIN (SELECT DISTINCT SchemaName,TableName FROM etl.InfoSchema) s
			ON  '[' + a.SourceSchema + ']' = s.[SchemaName] AND t.TableName = s.TableName
	WHERE a.Active = 1
		AND t.TableName NOT LIKE '[[]zz%'
		AND (
				(t.TableName IS NOT NULL 
				AND s.TableName IS NOT NULL 
				AND a.TaskType IN ('sql','sync','insert','update','upsert','type1','type2','syncsoftdelete'))
			OR 
			(
				(a.TaskType IN ('truncate','package') 
				AND t.TableName IS NOT NULL)
			)
			OR 
			(
				(a.TaskType = 'sql' 
				AND a.[SQL] IS NOT NULL)
			)
		)
	) a
	LEFT JOIN etl.Task t ON a.BatchID = t.BatchID AND a.[Target] = t.[Target]
)

/* Get Columns for tables that use 'Type1','Type2', and 'SyncSoftDelete' in order to set the Default CustomMatch and ExcludeColumns fields for the merge generator */
,CustomMatchAndExcludeColumns AS
(
SELECT bt.BatchID, i.SchemaName,i.TableName,i.ColumnName,i.IsPK,bt.[Target],bt.TaskType
FROM etl.InfoSchema i
	JOIN BaseTasks bt ON i.SchemaName + '.' + i.TableName = bt.[Source]
WHERE bt.TaskType IN ('Type1','Type2','SyncSoftDelete')
)
	
/* Create the final set that joins in the CustomMatch/ExcludeColumns */
SELECT
	bt.BatchID
	,bt.ExecutionOrder
	,CASE
		WHEN bt.TaskType IN ('sync','insert','update','upsert','syncsoftdelete','type2','type1') THEN UPPER(bt.TaskType) + ': '
		WHEN bt.TaskType IN ('truncate') THEN UPPER(bt.TaskType) + ': '
		WHEN bt.TaskType IN ('sql') THEN UPPER(bt.TaskType) + ': '
	ELSE NULL END
	+ TaskMovement TaskName
	,bt.TaskType
	,bt.[SQL]
	,bt.[Target]
	,bt.[Source]
	,COALESCE(cmatch.CustomMatchOn,bt.CustomMatchOn) CustomMatchOn
	,COALESCE(cmatch.ExcludeColumns,bt.ExcludeColumns) ExcludeColumns
	,bt.[Execute]
	,bt.FailBatchOnFailure
	,bt.SuppressResults
FROM BaseTasks bt
	LEFT JOIN
	(
	SELECT DISTINCT
		a.BatchID
		,a.[Target]
		,a.TaskType
		,REPLACE(
			(SELECT
				SUBSTRING(
				(SELECT ',' + l.ColumnName [text()]
				FROM CustomMatchAndExcludeColumns l
				WHERE a.BatchID = l.BatchID AND a.TableName = l.TableName AND a.SchemaName = l.SchemaName AND (REPLACE(l.ColumnName,']','') LIKE '%[_]K' OR IsPK = 1)
				FOR XML PATH ('')
				), 2, 10000000))
			,'_K','') CustomMatchOn
		,CASE WHEN a.TaskType = 'type2' THEN '[EFF_BEG_DATE],[EFF_END_DATE],' ELSE '' END +
		 CASE
			WHEN a.TaskType IN ('type2','type1') THEN '[ETL_CREATED_DATE],[ETL_LUPDATED_DATE]'
			WHEN a.TaskType IN ('SyncSoftDelete') THEN '[IS_DELETED],[ETL_DELETE_DATE]'
		ELSE '' END ExcludeColumns
	FROM CustomMatchAndExcludeColumns a
	) cmatch
	ON bt.BatchID = cmatch.BatchID AND bt.[Target] = cmatch.[Target]
	

GO
