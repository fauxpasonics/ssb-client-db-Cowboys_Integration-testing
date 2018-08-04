SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create PROCEDURE [dbo].[sp_CRMLoad_SaveResults_XML]
@ResultCategory VARCHAR(50)
AS

--EXEC dbo.sp_CRMLoad_SaveResults 'Account_Std'
--TRUNCATE TABLE dbo.[CRMLoad_SaveResults_Archived]
DECLARE @XML XML	

IF @ResultCategory = 'Account_Std'
SET @XML = (SELECT * FROM dbo.[Account_CRMResults] FOR XML RAW('Account_Std'), ELEMENTS, ROOT('Root'))

IF @ResultCategory = 'Account_Custom'
SET @XML = (SELECT * FROM dbo.[Account_Custom_CRMResults] FOR XML RAW('Account_Custom'), ELEMENTS, ROOT('Root'))

IF @ResultCategory = 'Contact_Std'
SET @XML = (SELECT * FROM dbo.[Contact_CRMResults] FOR XML RAW('Contact_Std'), ELEMENTS, ROOT('Root'))

IF @ResultCategory = 'Contact_Custom'
SET @XML = (SELECT * FROM dbo.[Contact_Custom_CRMResults] FOR XML RAW('Contact_Custom'), ELEMENTS, ROOT('Root'))

IF @ResultCategory = 'Lead_Std'
SET @XML = (SELECT * FROM dbo.[Lead_CRMResults] FOR XML RAW('Lead_Std'), ELEMENTS, ROOT('Root'))

IF @ResultCategory = 'Lead_Custom'
SET @XML = (SELECT * FROM dbo.[Lead_Custom_CRMResults] FOR XML RAW('Lead_Custom'), ELEMENTS, ROOT('Root'))

INSERT INTO dbo.CRMLoad_SaveResults_Archived
SELECT GETDATE() ArchiveDate, @ResultCategory ResultCategory, @XML XML_Results



--DECLARE @XML XML
--DECLARE @docHandle int
--DECLARE @xmlDocument nvarchar(4000)
--SET @XML = (SELECT * FROM dbo.[Account_CRMResults] Account_Std FOR XML RAW('Account_Std'), ELEMENTS, ROOT('Root')) --PATH('Account_Std'), ROOT('Root'))
----SELECT TOP 1 XML_Results FROM dbo.[CRMLoad_SaveResults_Archived])

--exec sp_xml_preparedocument @docHandle out, @xml, '<row xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"/>'

--SELECT * FROM OPENXML(@docHandle, '/Root/Account_Std',1)
--WITH
--(
--[SSB_CRMSYSTEM_ACCT_ID__c] [varchar] (50) ,
--[Name] [nvarchar] (300) ,
--[BillingStreet] [nvarchar] (500) ,
--[BillingCity] [nvarchar] (200) ,
--[BillingState] [nvarchar] (200) ,
--[BillingCountry] [nvarchar] (200) ,
--[Phone] [nvarchar] (25) ,
--[BillingPostalCode] [nvarchar] (25) ,
--[SalesForceId] [nvarchar] (18) ,
--[RowResult] [nvarchar] (10) ,
--[ErrorCode] [int] ,
--[ErrorColumn] [int] ,
--[ErrorDescription] [nvarchar] (1024) ,
--[ResultDateTime] [datetime] 
--) 

--EXEC sp_xml_removedocument @docHandle




GO
