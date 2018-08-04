SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[sp_CRMProcess_CRMID_Assign_Account]
AS

/*remove salesforce_ids that are not in prodcopy - wait 1 day to be sure they get picked up by prodcopy*/
UPDATE a
SET crm_id = a.SSB_CRMSYSTEM_ACCT_ID
--SELECT COUNT(*)
FROM dbo.account a

LEFT JOIN prodcopy.vw_Account b
ON a.[crm_id] = b.[accountid]
WHERE b.[accountid] IS NULL

UPDATE a
SET [crm_id] = b.accountid
--SELECT COUNT(*)
FROM dbo.account a
INNER JOIN prodcopy.vw_account b ON a.SSB_CRMSYSTEM_ACCT_ID = b.[new_ssbcrmsystemacctid]
LEFT JOIN (SELECT crm_id FROM dbo.account WHERE crm_id <> [SSB_CRMSYSTEM_ACCT_ID]) c ON b.accountid = c.[crm_id]
WHERE ISNULL(a.[crm_id], '') != b.accountid
AND c.[crm_id] IS NULL


UPDATE a
SET crm_ID =  b.ssid 
--SELECT COUNT(*)
FROM dbo.account a
INNER JOIN dbo.vwCompositeRecord_ModAcctID b ON a.SSB_CRMSYSTEM_ACCT_ID = b.[SSB_CRMSYSTEM_ACCT_ID]
LEFT JOIN (SELECT crm_id FROM dbo.account WHERE crm_id <> [SSB_CRMSYSTEM_ACCT_ID]) c ON b.ssid = c.[crm_id]
WHERE b.SourceSystem = 'CRM_Account' AND ISNULL(a.crm_id, '') != b.ssid --updateme
AND c.[crm_id] IS NULL 

GO
