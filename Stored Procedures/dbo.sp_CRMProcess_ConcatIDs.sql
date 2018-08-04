SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[sp_CRMProcess_ConcatIDs]
@ObjectType VARCHAR(50)
AS

-------------------------------------------------------------------------------

-- Author name:		Tommy Francis
-- Created date:	May 2018
-- Purpose:			Create strings of concatenated IDs for use in CRM custo
--					field outbound push

-- Copyright © 2018, SSB, All Rights Reserved

-------------------------------------------------------------------------------

-- Modification History --

-- 2018-06-26:		Kaitlyn Nelson
-- Change notes:	Changed string delimiters to '|' instead of ',' at the
--					Cowboys' request.

-- Peer reviewed by:	Scott Sales
-- Peer review notes:	New pipe delimiter works just fine. These procs tend to
--						be a heavy hitters, and I never figured out a way to speed
--						them up. Only comment I have is maybe adding a space
--						between the pipe for the ids to read a bit easier. Everything
--						else looks to be in working fashion. (KN - not doing this,
--						as Cowboys requested no space)
-- Peer review date:	2018-06-26

-- Deployed by:
-- Deployment date:
-- Deployment notes:

-------------------------------------------------------------------------------

-------------------------------------------------------------------------------

--DECLARE @ObjectType varchar(50) SET @ObjectType = 'Account'


/*
EXEC [dbo].[sp_CRMProcess_ConcatIDs] 'Account'
Select * from wrk.customerWorkingList
EXEC [dbo].[sp_CRMProcess_ConcatIDs] 'Contact'
Select * from stg.Contact
*/

SELECT CASE WHEN @ObjectType = 'Account' THEN ssb_crmsystem_contactacct_id
		ELSE [SSB_CRMSYSTEM_CONTACT_ID] END GUID
	, CAST(DimCustomerId AS VARCHAR(100)) AS DimCustomerID
	, CAST(SSID AS VARCHAR(50)) AS SSID
	, a.SourceSystem
INTO #SGpDimCustIDs
--DROP table #SGpDimCustIDs
FROM            dbo.DimCustomerssbid AS a
WHERE        (1 = 1) 
	--AND a.SourceSystem NOT LIKE 'Lead_%'
	--AND SSID = '68:857237'
	--AND a.[SSB_CRMSYSTEM_CONTACT_ID] = '4EAEED5A-E90E-4733-9AD5-07B1AF6E9724'
	AND (a.[SSB_CRMSYSTEM_ACCT_ID] IN (SELECT SSB_CRMSYSTEM_ACCT_ID FROM DBO.vwCRMProcess_DistinctAccounts_CriteriaMet)
		OR a.[SSB_CRMSYSTEM_CONTACT_ID] IN (SELECT SSB_CRMSYSTEM_CONTACT_ID FROM DBO.vwCRMProcess_DistinctContacts_CriteriaMet))
	--AND [a].[SSB_CRMSYSTEM_ACCT_ID] = '7509A514-BB5F-42E7-8891-2EB8A1399ED3'
	AND SourceSystem NOT LIKE '%SFDC%' AND SourceSystem NOT LIKE '%CRM%' --updateme
	-- AND a.SSB_CRMSYSTEM_ACCT_PRIMARY_FLAG = 0

-- DROP TABLE #SGpDimCustIDs
-- SELECT * FROM #SGpDimCustIDs


TRUNCATE TABLE stg.tbl_CRMProcess_NonWinners

INSERT INTO [stg].tbl_CRMProcess_NonWinners ([GUID], [DimCustomerID], [SourceSystem], [SSID], CustomID1, Primary_Flag)

SELECT GUID, a.DimCustomerID, a.[SourceSystem], CAST(a.SSID as varchar(50)) AS SSID, b.AccountId CustomID1, SSB_CRMSYSTEM_ACCT_PRIMARY_FLAG AS Primary_Flag
FROM #SGpDimCustIDs a 
INNER JOIN dbo.[vwDimCustomer_ModAcctId] b
	ON [b].[DimCustomerId] = [a].[DimCustomerID]
WHERE 1=1
	--AND [a].[SSB_CRMSYSTEM_ACCT_ID] = '7509A514-BB5F-42E7-8891-2EB8A1399ED3'

TRUNCATE TABLE stg.[tbl_CRMProcess_ConcatIDs]

INSERT INTO stg.tbl_CRMProcess_ConcatIDs ([GUID], ConcatIDs1, ConcatIDs2, ConcatIDs3, ConcatIDs4, ConcatIDs5, DimCust_ConcatIDs)
SELECT [GUID]
	, ISNULL(LEFT(STUFF((
							SELECT  CONCAT('|', SSID)  AS [text()]
							FROM stg.tbl_CRMProcess_NonWinners SG
							WHERE SG.[GUID] = z.[GUID]
								AND SG.[SourceSystem] = 'SG'
							ORDER BY SSID
							FOR XML PATH('')
						), 1, 1, ''),8000),'') AS ConcatIDs1
	, ISNULL(LEFT(STUFF((
							SELECT  CONCAT('|', CustomID1)  AS [text()]
							FROM (
									SELECT CustomID1,[GUID], MAX(CAST(Primary_Flag as int)) Primary_Flag 
									FROM stg.tbl_CRMProcess_NonWinners
									WHERE [SourceSystem] = 'SG'
									GROUP by CustomID1,[GUID]
								) acct
							WHERE acct.[GUID] = z.[GUID] 
							ORDER BY Primary_Flag desc, CONCAT('|', CustomID1)
							FOR XML PATH('')
						), 1, 1, ''),8000),'') AS ConcatIDs2
	, '' ConcatIDs3
	, '' ConcatIDs4
	, '' ConcatIDs5
	, LEFT(STUFF((
					SELECT CONCAT('|', DimCustomerID)  AS [text()]
					FROM #SGpDimCustIDs DimCust
					WHERE DimCust.GUID = z.GUID
					ORDER BY [DimCustomerID]
					FOR XML PATH('')
				), 1, 1, '' ),8000) as DimCustID_LoserString
--INTO #SGpA
FROM (
		SELECT DISTINCT [GUID]
		FROM stg.tbl_CRMProcess_NonWinners
		--WHERE GUID IN ('000001EC-E616-49AE-981A-A9B82F293D8B')
	) z

--Drop Table #LoserSSIDs
--SELECT * FROM #SGpA Where Len(ConcatIDs1) > 8000
--SELECT * FROM stg.[tbl_CRMProcess_ConcatIDs] WHERE GUID = '4EAEED5A-E90E-4733-9AD5-07B1AF6E9724'

IF @ObjectType = 'Account'
UPDATE a
SET TM_Ids = ISNULL(LTRIM([b].[ConcatIDs1]),'')
	, [AccountId] = ISNULL(LTRIM([b].[ConcatIDs2]),'')
	, DimCustIDs = ISNULL(LTRIM([b].[DimCust_ConcatIDs]),'')
	--, GP_Ids = ISNULL(LTRIM([b].[DimCust_ConcatIDs]),'')
	-- SELECT b.* 
FROM dbo.Account_Custom a
INNER JOIN stg.[tbl_CRMProcess_ConcatIDs] b
	ON a.SSB_CRMSYSTEM_ACCT_ID = b.[GUID]

IF @ObjectType = 'Contact'
UPDATE a
SET TM_Ids = ISNULL(LTRIM([b].[ConcatIDs1]),'')
	, [AccountId] = ISNULL(LTRIM([b].[ConcatIDs2]),'')
	, DimCustIDs = ISNULL(LTRIM([b].[DimCust_ConcatIDs]),'')
	--, GP_Ids = ISNULL(LTRIM([b].[DimCust_ConcatIDs]),'')
	-- SELECT b.* 
FROM dbo.[Contact_Custom] a
INNER JOIN stg.[tbl_CRMProcess_ConcatIDs] b
	ON a.[SSB_CRMSYSTEM_CONTACT_ID] = b.[GUID]

GO
