SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[sp_CRMLoad_SaveResults_Account_MSCRM]
as
--Fix Problems with SFID mapping with Contact GUID MATCH
UPDATE a
SET [a].[crm_id] = [a].[SSB_CRMSYSTEM_ACCT_ID]
--SELECT *
FROM dbo.Account a 
INNER JOIN dbo.[Account_CRMResults] b ON 
--[a].[salesforce_ID] = b.[Id] 
[a].[SSB_CRMSYSTEM_ACCT_ID] = b.[new_ssbcrmsystemacctid]
WHERE a.[crm_id] <> b.[accountid]
AND LoadType = 'Upsert'
--AND a.[crm_id] = a.[SSB_CRMSYSTEM_ACCT_ID]
--AND [a].[SSB_CRMSYSTEM_CONTACT_ID] <> b.[SSB_CRMSYSTEM_CONTACT_ID__c]

--Fix Problems with SFID mapping with SFID MATCH
UPDATE a
SET [a].[crm_id] = [a].[SSB_CRMSYSTEM_ACCT_ID]
--SELECT *
FROM dbo.[Account] a 
INNER JOIN dbo.[Account_CRMResults] b ON 
[a].[crm_id] = b.[accountid]
WHERE [a].[SSB_CRMSYSTEM_ACCT_ID] <> b.[new_ssbcrmsystemacctid]
AND LoadType = 'Upsert'
--AND b.id IN (SELECT [salesforce_ID] FROM dbo.[Contact])

-- Regular Update of SFIDs to Contact
UPDATE a
SET [a].[crm_id] = Case when b.CrmRecordId is null then a.[crm_id] else b.CrmRecordId End,
CRM_LoadDate = Getdate()
,LastCRMLoad_Error = b.[CrmErrorMessage]
,LastCRMLoad_AttemptDate = GetDate()
--SELECT b.*
FROM dbo.[Account] a
INNER JOIN dbo.[Account_CRMResults] b ON a.[SSB_CRMSYSTEM_ACCT_ID] = b.[new_ssbcrmsystemacctid]
WHERE LoadType = 'Upsert'


GO
