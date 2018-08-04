SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [etl].[TaskGenerator]
AS

SELECT * FROM etl.TaskModule_StandardSet
--UNION ALL
--SELECT * FROM etl.TaskModule_MDM
--UNION ALL
--SELECT * FROM etl.TaskModule_Package
--UNION ALL
--SELECT * FROM etl.TaskModule_Procedure
--UNION ALL
--SELECT * FROM etl.TaskModule_DW


GO
