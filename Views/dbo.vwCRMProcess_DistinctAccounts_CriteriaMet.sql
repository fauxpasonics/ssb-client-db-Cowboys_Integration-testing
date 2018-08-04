SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[vwCRMProcess_DistinctAccounts_CriteriaMet]
AS
SELECT * FROM dbo.CRMProcess_DistinctAccounts
WHERE [CRMLoadCriteriaMet] = 1
GO
