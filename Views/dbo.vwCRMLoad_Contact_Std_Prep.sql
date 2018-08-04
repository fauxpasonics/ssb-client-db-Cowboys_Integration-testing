SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[vwCRMLoad_Contact_Std_Prep]
AS 
SELECT --updateme - hashes
	  a.[SSB_CRMSYSTEM_ACCT_ID] new_ssbcrmsystemacctid
	  , a.[SSB_CRMSYSTEM_CONTACT_ID] new_ssbcrmsystemcontactid
	  , a.[Prefix]
      , a.[FirstName]
	  , a.[LastName]
	  , a.[Suffix]
      ,a.[AddressPrimaryStreet] address1_line1
      ,a.[AddressPrimaryCity] address1_city
      ,a.[AddressPrimaryState] address1_stateorprovince
      ,a.[AddressPrimaryZip] address1_postalcode
      ,a.[AddressPrimaryCountry] address1_country
      ,a.[Phone] telephone1
      ,a.[crm_id] contactid
	  , a.EmailPrimary emailaddress1
	  ,c.[LoadType]	  
	  ,HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(Lower(a.FirstName))),'')) as Hash_FirstName						--	DCH 2017-02-19
	  ,HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(Lower(a.LastName))),'')) as Hash_LastName						--	DCH 2017-02-19 
	  ,HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(Lower(a.Suffix))),'')) as Hash_Suffix 							--	DCH 2017-02-19
	  ,HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(Lower(a.AddressPrimaryStreet))),'')) as Hash_Address1_Line1 		--	DCH 2017-02-19
	  ,HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(Lower(REPLACE(REPLACE(REPLACE(REPLACE(a.Phone,')',''),'(',''),'-',''),' ','')))),'')) as Hash_Telephone1					--	DCH 2017-02-19
	  ,HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(Lower(a.EmailPrimary))),'')) as Hash_EmailAddress1 		--	DCH 2017-02-19
  FROM [dbo].Contact a 
INNER JOIN dbo.[CRMLoad_Contact_ProcessLoad_Criteria] c ON [c].[SSB_CRMSYSTEM_CONTACT_ID] = [a].[SSB_CRMSYSTEM_CONTACT_ID]


GO
