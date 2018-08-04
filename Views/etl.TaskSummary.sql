SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [etl].[TaskSummary]
AS

SELECT *, 'EXEC etl.Run @ETLTaskName = ''' + TaskName + '''' ExecuteTask
FROM (SELECT t.*,1 IsActive FROM etl.Task t) a


GO
