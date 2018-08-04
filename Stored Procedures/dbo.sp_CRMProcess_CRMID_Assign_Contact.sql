SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[sp_CRMProcess_CRMID_Assign_Contact]
AS

SELECT crm_id, COUNT(*) count
INTO #Dupes
FROM dbo.Contact
GROUP BY crm_id
HAVING COUNT(*) > 1

UPDATE dbo.contact
SET crm_id = c.SSB_CRMSYSTEM_CONTACT_ID
FROM dbo.Contact c
INNER JOIN #Dupes d
ON d.crm_id = c.crm_id

UPDATE a
SET crm_Id = a.SSB_CRMSYSTEM_CONTACT_ID
FROM dbo.contact a
LEFT JOIN prodcopy.contact b
ON a.crm_id = b.contactid
WHERE b.contactid IS NULL OR b.statecode = 1;

select crm.SSB_CRMSYSTEM_CONTACT_ID, crm.crm_id
INTO #WrongCRMID
FROM dbo.contact c
INNER JOIN cowboys.mdm.PrimaryFlagRanking_Contact r
ON c.SSB_CRMSYSTEM_CONTACT_ID = r.SSB_CRMSYSTEM_CONTACT_ID AND r.SourceSystem = 'crm_contact' AND r.ss_ranking = 1
INNER JOIN dbo.contact crm ON crm.crm_id = r.SSID
WHERE crm.SSB_CRMSYSTEM_CONTACT_ID != c.SSB_CRMSYSTEM_CONTACT_ID

UPDATE dbo.contact
SET crm_id = c.SSB_CRMSYSTEM_CONTACT_ID
FROM dbo.contact c
INNER JOIN #WrongCRMID w
ON w.crm_id = c.crm_id

--update crm_ids based on source system ranking
UPDATE a
SET [crm_id] =  r.ssid 
-- SELECT COUNT(*) 
FROM dbo.contact a
INNER JOIN cowboys.mdm.PrimaryFlagRanking_Contact r
ON a.SSB_CRMSYSTEM_CONTACT_ID = r.SSB_CRMSYSTEM_CONTACT_ID AND r.SourceSystem = 'crm_contact' AND r.ss_ranking = 1
LEFT JOIN (SELECT crm_id FROM dbo.contact WHERE crm_id <> [SSB_CRMSYSTEM_CONTACT_ID]) c ON r.ssid = c.[crm_id]
WHERE  a.[crm_id] != r.ssid --updateme
 AND c.[crm_id] IS NULL 


UPDATE a
SET a.crm_id = b.contactid
-- SELECT COUNT(*)
FROM dbo.contact a
INNER JOIN prodcopy.vw_contact b ON a.SSB_CRMSYSTEM_contact_ID = b.new_ssbcrmsystemcontactid
LEFT JOIN (SELECT [crm_id] FROM dbo.contact WHERE crm_id <> [SSB_CRMSYSTEM_CONTACT_ID]) c ON b.contactid = c.crm_id
WHERE ISNULL(a.[crm_id], '') != b.contactid 
AND c.crm_id IS NULL	
AND b.statecode = 0
---and b.id = '0033800002JUEoUAAX'


UPDATE a
SET [crm_id] =  b.ssid 
-- SELECT COUNT(*) 
FROM dbo.contact a
INNER JOIN dbo.[vwDimCustomer_ModAcctId] b ON a.SSB_CRMSYSTEM_contact_ID = b.SSB_CRMSYSTEM_contact_ID
LEFT JOIN (SELECT crm_id FROM dbo.contact WHERE crm_id <> [SSB_CRMSYSTEM_CONTACT_ID]) c ON b.ssid = c.[crm_id]
WHERE b.SourceSystem = 'CRM_Contact' AND a.[crm_id] != b.ssid --updateme
 AND c.[crm_id] IS NULL ;


GO
