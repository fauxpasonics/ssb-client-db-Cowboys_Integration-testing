SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[sp_CRMProcess_SeasonTicketHolders]
AS
TRUNCATE TABLE dbo.CRMProcess_Acct_SeasonTicketHolders
TRUNCATE TABLE dbo.CRMProcess_Contact_SeasonTicketHolders

--INSERT INTO dbo.SFDCProcess_SeasonTicketHolders
--SELECT DISTINCT a.SSB_CRMSYSTEM_ACCT_ID, a.SeasonList Devils_SeasonTicket_Years, CAST(NULL AS VARCHAR(1000)) Sixers_SeasonTicket_Years, a.LoadDateTime 
--FROM stg.SeasonTicketHolders a 
--WHERE Team = 'Devils'
--Drop Table #tmpA
-- Prep Sixers Season Data

SELECT DISTINCT b.SSB_CRMSYSTEM_ACCT_ID, b.SSB_CRMSYSTEM_CONTACT_ID, Team, a.SSID, CAST(a.SeasonYear AS INT) Season, CAST(a.SeasonYear AS INT) + 1 Season1, a.LoadDate LoadDateTime
INTO #tmpA
--SELECT * 
FROM stg.CRMProcess_SeasonTicketHolders_SSIDs a
INNER JOIN  [dbo].[vwDimCustomer_ModAcctId] b ON b.SSID = a.SSID
-- DROP TABLE #tmpA
-- SELECT * FROM [#tmpA]

--****SET UP ACCOUNT LEVEL SEASON TICKET HOLDERS
SELECT SSB_CRMSYSTEM_ACCT_ID
			, STUFF((SELECT  ',' + LTRIM(STR(Season)) + '-' + LTRIM(STR(Season1))
				FROM (SELECT DISTINCT SSB_CRMSYSTEM_ACCT_ID, Team, Season, Season1 FROM #tmpA) Team
				WHERE  t2.SSB_CRMSYSTEM_ACCT_ID = Team.SSB_CRMSYSTEM_ACCT_ID
				ORDER BY Team.SSB_CRMSYSTEM_ACCT_ID, Team.Season DESC
				FOR XML PATH('')), 1, 1, '') AS SeasonList	
		   , STUFF((SELECT  ',' + SSID
				FROM (SELECT DISTINCT SSB_CRMSYSTEM_ACCT_ID, TEAM, SSID FROM #tmpA) SSIDs
				WHERE  t2.SSB_CRMSYSTEM_ACCT_ID = SSIDs.SSB_CRMSYSTEM_ACCT_ID
				ORDER BY SSIDs.SSB_CRMSYSTEM_ACCT_ID, SSIDs.Team DESC
				FOR XML PATH('')), 1, 1, '') AS SSIDList
, MAX(LoadDateTime) LoadDateTime
, COUNT(DISTINCT Team) Dist_Team
, COUNT(DISTINCT t2.SSID) Dist_SSID
INTO #tmpAcct
FROM #tmpA t2
WHERE t2.SSB_CRMSYSTEM_ACCT_ID IS NOT NULL
GROUP BY SSB_CRMSYSTEM_ACCT_ID
-- Drop Table #tmpAcct

INSERT INTO dbo.CRMProcess_Acct_SeasonTicketHolders
        ( SSB_CRMSYSTEM_ACCT_ID ,
          SeasonTicket_Years ,
          SSIDs_List ,
          Distinct_Teams ,
          Distinct_SSIDs
        )
SELECT SSB_CRMSYSTEM_ACCT_ID, [SeasonList], SSIDList, Dist_Team, Dist_SSID FROM #tmpAcct

--****SET UP CONTACT LEVEL SEASON TICKET HOLDERS
SELECT SSB_CRMSYSTEM_CONTACT_ID
			, STUFF((SELECT  ',' + LTRIM(STR(Season)) + '-' + LTRIM(STR(Season1))
				FROM (SELECT DISTINCT SSB_CRMSYSTEM_CONTACT_ID, Team, Season, Season1 FROM #tmpA) Team
				WHERE  t2.SSB_CRMSYSTEM_CONTACT_ID = Team.SSB_CRMSYSTEM_CONTACT_ID
				ORDER BY Team.SSB_CRMSYSTEM_CONTACT_ID, Team.Season DESC
				FOR XML PATH('')), 1, 1, '') AS SeasonList	
		   , STUFF((SELECT  ',' + SSID
				FROM (SELECT DISTINCT SSB_CRMSYSTEM_CONTACT_ID, TEAM, SSID FROM #tmpA) SSIDs
				WHERE  t2.SSB_CRMSYSTEM_CONTACT_ID = SSIDs.SSB_CRMSYSTEM_CONTACT_ID
				ORDER BY SSIDs.SSB_CRMSYSTEM_CONTACT_ID, SSIDs.Team DESC
				FOR XML PATH('')), 1, 1, '') AS SSIDList
, MAX(LoadDateTime) LoadDateTime
, COUNT(DISTINCT Team) Dist_Team
, COUNT(DISTINCT t2.SSID) Dist_SSID
,COUNT(DISTINCT t2.SSB_CRMSYSTEM_CONTACT_ID) Distinct_ContactIDs
INTO #tmpContact
FROM #tmpA t2
WHERE t2.SSB_CRMSYSTEM_CONTACT_ID IS NOT NULL
GROUP BY SSB_CRMSYSTEM_CONTACT_ID

INSERT INTO dbo.CRMProcess_Contact_SeasonTicketHolders
        ( SSB_CRMSYSTEM_CONTACT_ID ,
          SeasonTicket_Years ,
          SSIDs_List ,
          Distinct_Teams ,
		  Distinct_SSIDs,
		  Distinct_ContactID
        )
SELECT SSB_CRMSYSTEM_CONTACT_ID, [SeasonList], SSIDList, Dist_Team, Dist_SSID,Distinct_ContactIDs FROM #tmpContact

DROP TABLE #TmpA
DROP TABLE #TmpAcct
DROP TABLE #tmpContact






GO
