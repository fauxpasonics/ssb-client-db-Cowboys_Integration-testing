SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[vwCRMLoad_Contact_Std_Upsert] AS

SELECT new_ssbcrmsystemacctid, new_ssbcrmsystemcontactid, Prefix, FirstName, LastName, Suffix, address1_line1, address1_city,
	address1_stateorprovince, address1_postalcode, address1_country, telephone1, emailaddress1, LoadType
FROM [dbo].[vwCRMLoad_Contact_Std_Prep]
WHERE LoadType = 'Upsert'

GO
