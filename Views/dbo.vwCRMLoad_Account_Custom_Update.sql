SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[vwCRMLoad_Account_Custom_Update]
AS

SELECT  z.[crm_id] accountid							 
, b.new_ssbcrmsystemSSIDWinner							 -- ,c.new_ssbcrmsystemSSIDWinner
, b.new_ssbcrmsystemSSIDWinnerSourceSystem				 -- ,c.new_ssbcrmsystemSSIDWinnerSourceSystem
--, TM_Ids [new_ssbcrmsystemarchticsids]				 -- ,c.
, b.DimCustIDs new_ssbcrmsystemdimcustomerids			 -- ,c.new_ssbcrmsystemdimcustomerids
, b.AccountId str_number								 -- ,c.[str_number]
-- SELECT *
-- SELECT COUNT(*) 
FROM dbo.[Account_Custom] b 
INNER JOIN dbo.Account z ON b.SSB_CRMSYSTEM_Acct_ID = z.[SSB_CRMSYSTEM_Acct_ID]
LEFT JOIN  prodcopy.vw_Account c ON z.[crm_id] = c.AccountID
----INNER JOIN dbo.CRMLoad_Acct_ProcessLoad_Criteria pl ON b.SSB_CRMSYSTEM_Acct_ID = pl.SSB_CRMSYSTEM_Acct_ID
Left JOIN (SELECT DISTINCT m.SSB_CRMSYSTEM_ACCT_ID
	FROM dbo.vw_KeyAccounts k
	JOIN dbo.vwDimCustomer_ModAcctId m ON m.DimCustomerId = k.dimcustomerid
	WHERE m.SSB_CRMSYSTEM_ACCT_ID IS NOT NULL) ka ON z.SSB_CRMSYSTEM_ACCT_ID = ka.SSB_CRMSYSTEM_ACCT_ID
WHERE z.[SSB_CRMSYSTEM_Acct_ID] <> z.[crm_id]
AND ka.ssb_crmsystem_acct_id is NULL
AND  (1=2
	OR HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(b.new_ssbcrmsystemSSIDWinner)),'') )  <> HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST(c.new_ssbcrmsystemssidwinner AS VARCHAR(MAX)))),'')) 
	OR HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(b.new_ssbcrmsystemSSIDWinnerSourceSystem)),'') )  <> HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST(c.new_ssbcrmsystemSSIDWinnerSourceSystem AS VARCHAR(MAX)))),'')) 
	OR HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(b.DimCustIDs)),'') )  <> HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST(c.new_ssbcrmsystemdimcustomerids AS VARCHAR(MAX)))),'')) 
	OR HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(b.AccountId)),'') )  <> HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST(c.str_number AS VARCHAR(MAX)))),''))
	--OR HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(b.TM_Ids)),'') )  <> HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST(c.[new_ssbcrmsystemarchticsids] AS VARCHAR(MAX)))),''))
	)
GO
