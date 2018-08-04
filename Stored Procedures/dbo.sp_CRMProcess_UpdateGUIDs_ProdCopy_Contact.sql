SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[sp_CRMProcess_UpdateGUIDs_ProdCopy_Contact]
AS
UPDATE b
SET [b].[new_ssbcrmsystemacctid] = a.[new_ssbcrmsystemacctid]
, [b].[new_ssbcrmsystemcontactid] = a.[new_ssbcrmsystemcontactid]
--SELECT a.* 
FROM [dbo].[vwCRMProcess_UpdateGUIDs_ProdCopyContact] a 
INNER JOIN ProdCopy.Contact b ON a.[contactid] = b.contactid
WHERE ISNULL(b.[new_ssbcrmsystemacctid],'a') <> ISNULL(a.[new_ssbcrmsystemacctid],'a')
OR ISNULL(b.[new_ssbcrmsystemcontactid],'a') <> ISNULL(a.[new_ssbcrmsystemcontactid],'a')



GO
