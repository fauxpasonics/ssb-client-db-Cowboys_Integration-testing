SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create VIEW [dbo].[vwCRMProcess_UpdateGUIDs_ProdCopyContact]
AS

SELECT DISTINCT b.SSID contactid, b.SSB_CRMSYSTEM_ACCT_ID [new_ssbcrmsystemacctid], b.SSB_CRMSYSTEM_CONTACT_ID [new_ssbcrmsystemcontactid]
--, REPLACE(REPLACE(c.[new_ssbcrmsystemcontactid],'{',''),'}','')
FROM dbo.vwDimCustomer_ModAcctId b
INNER JOIN ProdCopy.vw_Contact c WITH(NOLOCK) ON b.SSID = CAST(c.contactid AS VARCHAR(50))
WHERE c.[new_ssbcrmsystemcontactid] IS NULL OR c.[new_ssbcrmsystemcontactid] <> b.[SSB_CRMSYSTEM_CONTACT_ID]


GO
