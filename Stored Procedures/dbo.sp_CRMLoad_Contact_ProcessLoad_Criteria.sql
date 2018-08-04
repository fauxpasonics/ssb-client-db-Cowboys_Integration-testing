SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[sp_CRMLoad_Contact_ProcessLoad_Criteria]
AS 

-- Assign CRM IDs in dbo.Account
--EXEC dbo.sp_CRMProcess_CRMID_Assign_Account

TRUNCATE TABLE dbo.[CRMLoad_Contact_ProcessLoad_Criteria]

INSERT INTO dbo.[CRMLoad_Contact_ProcessLoad_Criteria]
        ( [SSB_CRMSYSTEM_CONTACT_ID] ,
          LoadType
        )
SELECT [SSB_CRMSYSTEM_CONTACT_ID]
, CASE WHEN 1=1 --b.accountid IS NULL 
AND [SSB_CRMSYSTEM_CONTACT_ID] = [crm_id] THEN 'Upsert' ELSE 'Update' END LoadType
FROM dbo.Contact  
--LEFT JOIN ProdCopy.[vw_Account] b ON a.[SSB_CRMSYSTEM_ACCT_ID] = b.[new_ssbcrmsystemacctid]



DELETE 
--SELECT * 
FROM dbo.CRMLoad_Contact_ProcessLoad_Criteria 
WHERE SSB_CRMSYSTEM_Contact_ID IN (
	SELECT SSB_CRMSYSTEM_Contact_ID FROM dbo.vwDimCustomer_ModAcctId a
		WHERE SSB_CRMSYSTEM_Contact_ID IN (SELECT DISTINCT SSB_CRMSYSTEM_Contact_ID FROM dbo.vwDimCustomer_ModAcctId WHERE SourceSystem LIKE '%CRM_Account%') --updateme
	GROUP BY SSB_CRMSYSTEM_Contact_ID
HAVING COUNT(DISTINCT SourceSystem) = 1
) 
AND LoadType = 'Upsert'


DELETE a
FROM dbo.CRMLoad_Contact_ProcessLoad_Criteria a
JOIN dbo.Contact b ON a.SSB_CRMSYSTEM_Contact_ID = b.SSB_CRMSYSTEM_Contact_ID
WHERE (ISNULL(firstname,'')  + ISNULL(lastname,'')  = ''
	OR  ISNULL(AddressPrimaryStreet,'') +  ISNULL(EmailPrimary,'') = '')
AND LoadType = 'Upsert' 

GO
