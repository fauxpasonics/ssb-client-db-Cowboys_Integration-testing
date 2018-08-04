SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[sp_CRMLoad_SaveResults_Contact_MSCRM]
as
--Fix Problems with SFID mapping with Contact GUID MATCH
UPDATE a
SET [a].[crm_id] = [a].[SSB_CRMSYSTEM_CONTACT_ID]
--SELECT *
FROM dbo.Contact a 
INNER JOIN dbo.[Contact_CRMResults] b ON [a].[SSB_CRMSYSTEM_CONTACT_ID] = b.[new_ssbcrmsystemcontactid]
WHERE a.[crm_id] <> b.[contactid]
--AND a.[crm_id] = a.[SSB_CRMSYSTEM_ACCT_ID]
--[a].[SSB_CRMSYSTEM_CONTACT_ID] <> b.[SSB_CRMSYSTEM_CONTACT_ID__c]

--Fix Problems with SFID mapping with SFID MATCH
UPDATE a
SET [a].[crm_id] = [a].[SSB_CRMSYSTEM_CONTACT_ID]
--SELECT *
FROM dbo.Contact a 
INNER JOIN dbo.[Contact_CRMResults] b ON [a].[crm_id] = b.[contactid]
WHERE [a].[SSB_CRMSYSTEM_CONTACT_ID] <> b.[new_ssbcrmsystemcontactid]
--AND b.id IN (SELECT [salesforce_ID] FROM dbo.[Contact])

-- Regular Update of SFIDs to Contact
UPDATE a
SET [a].[crm_id] = Case when ISNULL(b.[contactid],[b].[CrmRecordId]) is null then a.[crm_id] else ISNULL(b.[contactid],[b].[CrmRecordId]) End,
CRM_LoadDate = Getdate()
,LastCRMLoad_Error = b.[CrmErrorMessage]
,LastCRMLoad_AttemptDate = GetDate()
--SELECT DISTINCT a.[SSB_CRMSYSTEM_CONTACT_ID], Case when b.id is null then a.[crm_id] else b.id END, b.*
FROM dbo.[Contact] a
INNER JOIN dbo.[Contact_CRMResults] b ON a.[SSB_CRMSYSTEM_CONTACT_ID] = b.[new_ssbcrmsystemcontactid]
WHERE [b].[LoadType] = 'Upsert'
--AND [ResultDateTime] = '2016-03-29 21:58:56.510'

GO
