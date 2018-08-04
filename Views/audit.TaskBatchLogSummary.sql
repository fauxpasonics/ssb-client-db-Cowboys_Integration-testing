SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [audit].[TaskBatchLogSummary]
AS

WITH rcte AS
(SELECT
	ID
	,ParentID
	,Step
	,RunSQL
	,0 Depth
	,CONVERT(NVARCHAR(MAX), ID) Sort
FROM [audit].[TaskBatchLog] WITH (NOLOCK)
WHERE ParentID IS NULL
UNION ALL
SELECT
	pc.ID
	,pc.ParentID
	,pc.Step
	,pc.RunSQL
	,rcte.Depth + 1 Depth
	,rcte.Sort + CONVERT(NVARCHAR(MAX), pc.ID) Sort
FROM rcte
	JOIN [audit].[TaskBatchLog] pc WITH (NOLOCK) ON rcte.ID = pc.ParentID)


SELECT
	ROW_NUMBER() OVER(ORDER BY r.ID) Sort
	--,r.ID
	,r.Step
	,r.RunSQL
	,bl.CreatedBy
	,bl.ExecuteStart
	,bl.ExecuteEnd
	,bl.ExecutionRuntimeSeconds Seconds
	,RIGHT('0' + CAST(CONVERT(INT,bl.ExecutionRuntimeSeconds) / 3600 AS VARCHAR),2) + ':' +
	RIGHT('0' + CAST((CONVERT(INT,bl.ExecutionRuntimeSeconds) / 60) % 60 AS VARCHAR),2) + ':' +
	RIGHT('0' + CAST(CONVERT(INT,bl.ExecutionRuntimeSeconds) % 60 AS VARCHAR),2) [HH:MM:SS]
	,ISNULL(CONVERT(VARCHAR(100),NULLIF(COUNT(l.ID),0)),'') Attempted
	,ISNULL(CONVERT(VARCHAR(100),NULLIF(SUM(CONVERT(INT,l.IsError)),0)),'') Errored
	,ISNULL(CONVERT(VARCHAR(100),NULLIF(SUM(CONVERT(INT,l.IsCommitted)),0)),'') [Committed]
	,ISNULL(CONVERT(VARCHAR(100),SUM(l.RowCountBefore)),'') RowCountBefore
	,ISNULL(CONVERT(VARCHAR(100),SUM(l.RowCountAfter)),'') RowCountAfter
	,ISNULL(CONVERT(VARCHAR(100),NULLIF(SUM(l.Inserted),0)),'') Inserted
	,ISNULL(CONVERT(VARCHAR(100),NULLIF(SUM(l.Updated),0)),'') Updated
	,ISNULL(CONVERT(VARCHAR(100),NULLIF(SUM(l.Deleted),0)),'') Deleted
	,ISNULL(CONVERT(VARCHAR(100),NULLIF(SUM(l.Truncated),0)),'') Truncated
	,'SELECT * FROM [audit].TaskLog WITH (NOLOCK) WHERE BatchID = ' + CONVERT(VARCHAR(100),bl.ID) ViewExecutions
FROM (SELECT Sort,ID,REPLICATE('    ',rcte.Depth) + CASE WHEN rcte.Depth > 0 THEN '- ' ELSE '' END + rcte.Step Step, RunSQL FROM rcte) r
	JOIN [audit].[TaskBatchLog] bl WITH (NOLOCK) ON r.ID = bl.ID
	LEFT JOIN [audit].[TaskLog] l WITH (NOLOCK) ON bl.ID = l.BatchID
GROUP BY
	r.ID
	,r.Step
	,r.RunSQL
	,bl.ID
	,bl.Step
	,bl.RunSQL
	,bl.CreatedBy
	,bl.ExecuteStart
	,bl.ExecuteEnd
	,bl.ExecutionRuntimeSeconds
GO
