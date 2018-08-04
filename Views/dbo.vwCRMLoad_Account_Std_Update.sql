SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[vwCRMLoad_Account_Std_Update] AS

SELECT 
a.new_ssbcrmsystemacctid
, a.Name													--,b.Name
, a.address1_line1											--,b.address1_line1
, a.address1_city											--,b.address1_city
, a.address1_stateorprovince								--,b.address1_stateorprovince
, a.address1_postalcode										--,b.address1_postalcode
, a.address1_country										--,b.address1_country
, a.telephone1												--,b.telephone1
, a.accountid												--,b.accountid
, LoadType													
, a.emailaddress1											--,b.emailaddress1
FROM [dbo].[vwCRMLoad_Account_Std_Prep] a
JOIN prodcopy.vw_account b on a.accountid = b.accountid
Left JOIN (SELECT DISTINCT m.SSB_CRMSYSTEM_ACCT_ID
	FROM dbo.vw_KeyAccounts k
	JOIN dbo.vwDimCustomer_ModAcctId m ON m.DimCustomerId = k.dimcustomerid
	WHERE m.SSB_CRMSYSTEM_ACCT_ID IS NOT NULL) ka ON a.new_ssbcrmsystemacctid = ka.SSB_CRMSYSTEM_ACCT_ID
WHERE LoadType = 'Update'
AND ka.ssb_crmsystem_acct_id is NULL
AND  (HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(Lower(a.Name ))),'') )  <> HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(Lower(b.Name ))),'')) 
	OR HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(Lower(a.address1_line1 ))),'') )  <> HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(Lower(b.address1_line1 ))),'')) 
	Or HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(Lower(REPLACE(REPLACE(REPLACE(REPLACE(a.telephone1,')',''),'(',''),'-',''),' ','') ))),'') )  <> HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(Lower(REPLACE(REPLACE(REPLACE(REPLACE(b.telephone1,')',''),'(',''),'-',''),' ','') ))),'') )
	Or HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(Lower(a.emailaddress1 ))),'') )  <> HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(Lower(b.emailaddress1 ))),'')) 
	)




GO
