SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create VIEW [dbo].[vwCRMProcess_UpdateGUIDs_ProdCopyAccount]
AS

SELECT DISTINCT  b.SSID accountid, b.SSB_CRMSYSTEM_ACCT_ID [new_ssbcrmsystemacctid]
--, REPLACE(REPLACE(c.[new_ssbcrmsystemcontactid],'{',''),'}','')
FROM dbo.vwDimCustomer_ModAcctId b
INNER JOIN ProdCopy.vw_account c WITH(NOLOCK) ON b.SSID = CAST(c.accountid AS VARCHAR(50))
WHERE c.[new_ssbcrmsystemacctid] IS NULL OR c.[new_ssbcrmsystemacctid] <> b.[SSB_CRMSYSTEM_ACCT_ID]


GO
