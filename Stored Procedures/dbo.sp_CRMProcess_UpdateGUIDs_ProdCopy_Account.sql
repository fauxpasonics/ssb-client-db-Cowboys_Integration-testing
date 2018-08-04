SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[sp_CRMProcess_UpdateGUIDs_ProdCopy_Account]
as
UPDATE b
SET [b].[new_ssbcrmsystemacctid] = a.[new_ssbcrmsystemacctid]
--SELECT a.* 
FROM [dbo].[vwCRMProcess_UpdateGUIDs_ProdCopyAccount] a 
INNER JOIN ProdCopy.vw_Account b ON a.accountid = b.accountid
WHERE ISNULL(b.[new_ssbcrmsystemacctid],'a') <> ISNULL(a.[new_ssbcrmsystemacctid],'a')



GO
