SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[vwCRMProcess_DistinctContacts_CriteriaMet]
AS
SELECT * FROM dbo.CRMProcess_DistinctContacts
WHERE [CRMLoadCriteriaMet] = 1
GO
