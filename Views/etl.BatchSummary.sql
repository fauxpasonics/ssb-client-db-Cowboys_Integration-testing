SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [etl].[BatchSummary]
AS

WITH rcte AS
(
SELECT
	ID
	,ParentID
	,BatchName
	,0 Depth
	,CONVERT(NVARCHAR(MAX), ID) Sort
	,SortOrder
FROM etl.Batch
WHERE ParentID IS NULL
UNION ALL
SELECT
	pc.ID
	,pc.ParentID
	,pc.BatchName
	,Depth = rcte.Depth + 1
	,Sort = rcte.Sort + CONVERT(NVARCHAR(MAX), COALESCE(pc.SortOrder,pc.ID))
	,COALESCE(pc.SortOrder,pc.ID) SortOrder
FROM rcte
	JOIN etl.Batch pc ON rcte.ID = pc.ParentID
WHERE pc.Active = 1
)

SELECT
	ROW_NUMBER() OVER(ORDER BY r.Sort) Sort
	,bl.ParentID
	,r.ID
	,r.BatchNameIndent BatchName
	--,'EXEC etl.Run @ETLBatchName = ''' + r.BatchName + '''' ExecuteBatch
	,'SELECT * FROM etl.TaskSummary WHERE BatchID = ' + CONVERT(VARCHAR(100),bl.ID) ViewTasks
	,NULLIF(SUM(CASE WHEN l.Active = 1 THEN 1 ELSE 0 END),0) ActiveTasks
	,NULLIF(SUM(CASE WHEN l.Active = 0 THEN 1 ELSE 0 END),0) InActiveTasks
FROM
	(SELECT
		ID
		,REPLICATE('    ',rcte.Depth) + CASE WHEN rcte.Depth > 0 THEN '- ' ELSE '' END + rcte.BatchName BatchNameIndent
		,rcte.BatchName
		,rcte.Sort
	FROM rcte) r
	JOIN etl.Batch bl ON r.ID = bl.ID
	LEFT JOIN etl.Task l ON bl.ID = l.BatchID
GROUP BY
	bl.ParentID
	,r.ID
	,r.BatchNameIndent
	,r.BatchName
	,bl.ID
	,bl.BatchName
	,r.Sort




GO
