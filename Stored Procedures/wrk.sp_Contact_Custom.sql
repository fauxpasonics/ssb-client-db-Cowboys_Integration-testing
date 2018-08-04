SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [wrk].[sp_Contact_Custom]
AS 
-------------------------------------------------------------------------------

-- Author name:		Kaitlyn Nelson
-- Created date:	May 218
-- Purpose:			Define logic and prep data to push to CRM custom fields
--					in MS Dynamics outbound integration

-- Copyright © 2018, SSB, All Rights Reserved

-------------------------------------------------------------------------------

-- Modification History --

-- 2018-06-26:			Kaitlyn Nelson
-- Change notes:		Added logic for salesperson and serviceperson fields
-- Peer reviewed by:	Keegan Schmitt
-- Peer review notes:	Looks good
-- Peer review date:	2018-06-26
-- Deployed by:
-- Deployment date:
-- Deployment notes:

-- 2018-07-27:			Kaitlyn Nelson
-- Change notes:		Added logic for Founders prospects
-- Peer reviewed by:	Keegan Schmitt
-- Peer review notes:	
-- Peer review date:	
-- Deployed by:
-- Deployment date:
-- Deployment notes:

-- 2018-07-27:			Keegan Schmitt
-- Change notes:		Added logic for parentcustomerid and parentcustomeridtype
-- Peer reviewed by:	Kaitlyn Nelson
-- Peer review notes:	Looks good, ran successfully in dev
-- Peer review date:	2018-08-03
-- Deployed by:
-- Deployment date:
-- Deployment notes:

-------------------------------------------------------------------------------

-------------------------------------------------------------------------------

DECLARE @SeasonYear INT = 2018

MERGE INTO dbo.Contact_Custom Target
	USING dbo.Contact source
	ON source.[SSB_CRMSYSTEM_CONTACT_ID] = target.[SSB_CRMSYSTEM_CONTACT_ID]
WHEN NOT MATCHED BY TARGET THEN
INSERT ([SSB_CRMSYSTEM_ACCT_ID], [SSB_CRMSYSTEM_CONTACT_ID]) VALUES (source.[SSB_CRMSYSTEM_ACCT_ID], Source.[SSB_CRMSYSTEM_CONTACT_ID])
WHEN NOT MATCHED BY SOURCE THEN
DELETE ;

EXEC dbo.sp_CRMProcess_ConcatIDs 'Contact'



UPDATE a
SET a.new_ssbcrmsystemssidwinner = b.[SSID], a.new_ssbSSIDWinnerSourceSystem = b.SourceSystem
, a.mobilephone = b.PhoneCell, a.telephone2 = b.PhoneHome
FROM [dbo].Contact_Custom a
INNER JOIN Cowboys.dbo.[vwCompositeRecord_ModAcctID] b
	ON b.[SSB_CRMSYSTEM_CONTACT_ID] = [a].[SSB_CRMSYSTEM_CONTACT_ID]


--Prep 12 Months Data
SELECT f.RevenueTotal, f.OwedAmount, e.DimEventId, e.EventDate, e.Config_Category1, dtc.ETL__SourceSystem
, CASE WHEN dtc.ETL__SourceSystem = 'TM' THEN CAST(dtc.ETL__SSID_TM_acct_id AS NVARCHAR(100)) ELSE CAST(dtc.ETL__SSID AS NVARCHAR(100)) END AS acct_id
, CASE WHEN dtc.ETL__SourceSystem = 'TM' THEN 'Primary' ELSE NULL END AS CustomerType
INTO #temp_twelvemonthsales
FROM Cowboys.dbo.FactTicketSales_V2 f (NOLOCK)
		JOIN Cowboys.dbo.DimEvent_V2 e (NOLOCK)
			ON f.DimEventId = e.DimEventId
		JOIN Cowboys.dbo.DimTicketCustomer_V2 dtc (NOLOCK)
			ON f.DimTicketCustomerId = dtc.DimTicketCustomerId
		WHERE  e.EventDate > DATEADD(YEAR, -1, GETDATE())

-- Spend on Cowboys Events in Last 12 Months --
UPDATE a
SET a.new_ssb_spend12months_cowboysevents = x.TotalRevenue
FROM [dbo].Contact_Custom a
JOIN (
		SELECT dc.SSB_CRMSYSTEM_CONTACT_ID, SUM(tms.RevenueTotal) TotalRevenue, SUM(tms.OwedAmount) OwedAmount
		--SELECT COUNT(*)
		FROM #temp_twelvemonthsales tms
		JOIN Cowboys.dbo.vwDimCustomer_ModAcctId dc (NOLOCK)
			ON tms.ETL__SourceSystem = dc.SourceSystem
			AND tms.acct_id = CAST(dc.AccountId AS NVARCHAR(100))
					AND dc.CustomerType = tms.CustomerType
		WHERE  tms.Config_Category1 = 'Cowboys'
		GROUP BY dc.SSB_CRMSYSTEM_CONTACT_ID
	) x ON x.SSB_CRMSYSTEM_CONTACT_ID = a.SSB_CRMSYSTEM_CONTACT_ID




-- Spend on Non-Cowboys Events in Last 12 Months --
UPDATE a
SET a.new_ssb_spend12months_noncowboysevents = x.TotalRevenue
FROM [dbo].Contact_Custom a
JOIN (
		SELECT dc.SSB_CRMSYSTEM_CONTACT_ID, SUM(tms.RevenueTotal) TotalRevenue, SUM(tms.OwedAmount) OwedAmount
		--SELECT COUNT(*)
		FROM #temp_twelvemonthsales tms
		JOIN Cowboys.dbo.vwDimCustomer_ModAcctId dc (NOLOCK)
			ON tms.ETL__SourceSystem = dc.SourceSystem
			AND tms.acct_id = CAST(dc.AccountId AS NVARCHAR(100))
					AND dc.CustomerType = tms.CustomerType
		WHERE  ISNULL(tms.Config_Category1,'') != 'Cowboys'
		GROUP BY dc.SSB_CRMSYSTEM_CONTACT_ID
	) x ON x.SSB_CRMSYSTEM_CONTACT_ID = a.SSB_CRMSYSTEM_CONTACT_ID



-- Merchandise Spend in Last 12 Months --

UPDATE a
SET a.new_ssb_spend12months_merch = x.PaidAmount
FROM [dbo].Contact_Custom a
JOIN (
		SELECT SSB_CRMSYSTEM_CONTACT_ID, SUM(Dollars) PaidAmount
		FROM Cowboys.[ods].[Merchandise_LineItems] l
		INNER JOIN Cowboys.dbo.vwDimCustomer_ModAcctId m
			ON m.FullName = l.Shipping_Name
			AND l.Sales_Order_Email_Address = m.EmailPrimary 
			AND m.SourceSystem = 'Merchandise'
		WHERE l.Order_Date >= DATEADD(YEAR, -1, GETDATE())
		GROUP BY m.SSB_CRMSYSTEM_CONTACT_ID
	) x ON x.SSB_CRMSYSTEM_CONTACT_ID = a.SSB_CRMSYSTEM_CONTACT_ID

-- Cowboys Fit Member --
--dal_ssb_cowboysfit
UPDATE a
SET a.dal_ssb_cowboysfit = ISNULL(x.IsCowboysFitMember, 0)
FROM dbo.Contact_Custom a (NOLOCK)
LEFT JOIN (
		SELECT dc.SSB_CRMSYSTEM_CONTACT_ID, 1 IsCowboysFitMember
		FROM Cowboys.dbo.vwDimCustomer_ModAcctId dc (NOLOCK)
		WHERE dc.SourceSystem = 'CowboysFit'
	) x ON x.SSB_CRMSYSTEM_CONTACT_ID = a.SSB_CRMSYSTEM_CONTACT_ID



-- Cowboys Club Member --
--dal_ssb_cowboysclub
UPDATE a
SET a.dal_ssb_cowboysclub = ISNULL(x.IsCowboysClubMember, 0)
FROM [dbo].Contact_Custom a
LEFT JOIN (
		SELECT dc.SSB_CRMSYSTEM_CONTACT_ID, 1 IsCowboysClubMember
		FROM Cowboys.dbo.vwDimCustomer_ModAcctId dc (NOLOCK)
		WHERE dc.SourceSystem = 'CowboysClub'
	) x ON x.SSB_CRMSYSTEM_CONTACT_ID = a.SSB_CRMSYSTEM_CONTACT_ID



-- Cowboys Fan Club Member --
-- Don't know which field this is suppoed to populate
UPDATE a
SET a.new_ssb_fanclub = ISNULL(x.IsCowboysFanClubMember, 0)
FROM dbo.Contact_Custom a (NOLOCK)
LEFT JOIN (
		SELECT dc.SSB_CRMSYSTEM_CONTACT_ID, 1 IsCowboysFanClubMember
		FROM Cowboys.dbo.vwDimCustomer_ModAcctId dc (NOLOCK)
		WHERE dc.SourceSystem = 'CowboysFanClub'
	) x ON x.SSB_CRMSYSTEM_CONTACT_ID = a.SSB_CRMSYSTEM_CONTACT_ID


-- Cowboys Youth Camps --
-- Still don't know the field
UPDATE a
SET a.new_ssb_youthcamps = ISNULL(x.IsYouthCampsMember, 0)
FROM dbo.Contact_Custom a (NOLOCK)
LEFT JOIN (
		SELECT dc.SSB_CRMSYSTEM_CONTACT_ID, 1 IsYouthCampsMember
		FROM Cowboys.dbo.vwDimCustomer_ModAcctId dc (NOLOCK)
		WHERE dc.SourceSystem = 'YouthCamps'
	) x ON x.SSB_CRMSYSTEM_CONTACT_ID = a.SSB_CRMSYSTEM_CONTACT_ID



-- Personicx Cluster --
--dal_ssb_personicxcluster
SELECT DISTINCT dc.SSB_CRMSYSTEM_CONTACT_ID, dcattrval.AttributeValue
	, RANK() OVER(PARTITION BY dc.SSB_CRMSYSTEM_CONTACT_ID ORDER BY dcattr.UpdatedDate, TRY_CAST(dcattrval.AttributeValue AS INT) DESC) xRank
INTO #ClusterRank
FROM Cowboys.dbo.vwDimCustomer_ModAcctId dc (NOLOCK)
JOIN Cowboys.dbo.DimCustomerAttributes dcattr (NOLOCK)
	ON dc.DimCustomerId = dcattr.DimCustomerID
JOIN Cowboys.dbo.DimCustomerAttributeValues dcattrval (NOLOCK)
	ON dcattr.DimCustomerAttrID = dcattrval.DimCustomerAttrID
WHERE dcattrval.AttributeName = 'PersonicxLifestageClusterCode'

UPDATE a
SET a.dal_ssb_personicxcluster = cr.Cluster
FROM dbo.Contact_Custom a
JOIN (
		SELECT SSB_CRMSYSTEM_CONTACT_ID, AttributeValue Cluster
		FROM #ClusterRank (NOLOCK)
		WHERE xRank = 1
	) cr ON a.SSB_CRMSYSTEM_CONTACT_ID = cr.SSB_CRMSYSTEM_CONTACT_ID


-- SeatGeek Account ID --
-- dal_ssb_seatgeekaccountid

UPDATE dbo.Contact_Custom
SET dal_ssb_seatgeekaccountid = 
REPLACE(LEFT(AccountID, CHARINDEX('|', AccountID, 85) - 1),'|',',')
FROM dbo.Contact_Custom
WHERE LEN(AccountID) > 100;

UPDATE dbo.Contact_Custom
SET dal_ssb_seatgeekaccountid =
NULLIF(REPLACE( AccountID,'|',','),'')
FROM dbo.Contact_Custom
WHERE LEN(AccountID) < 100 OR accountid IS null;



-- SeatGeek Salesperson --
-- dal_ssb_seatgeeksalesperson
SELECT r.SSB_CRMSYSTEM_CONTACT_ID, CONCAT(dr.FirstName, ' ', dr.LastName) RepName
INTO #Reps
FROM cowboys.mdm.PrimaryFlagRanking_Contact r (NOLOCK)
JOIN cowboys.ods.SGDW_XrefSalesRepGoalClient x (NOLOCK)
	ON r.ssid = CAST(x.xsgcClientGuid AS NVARCHAR(100))
JOIN Cowboys.ods.SGDW_DimSalesRepGoals srg (NOLOCK)
	ON x.xsgcSalesRepGoalGuid = srg.dsrgGuid
JOIN Cowboys.dbo.DimRep_V2 dr (NOLOCK)
	ON srg.dsrgSalesRepGuid = dr.ETL__SSID_SG_salesrep_guid
WHERE r.sourcesystem = 'SG'
	AND r.ss_ranking = 1



SELECT DISTINCT b.SSB_CRMSYSTEM_CONTACT_ID 
	, SUBSTRING(
		(
			SELECT ', '+ a.RepName  AS [text()]
			FROM #Reps a
			WHERE a.SSB_CRMSYSTEM_CONTACT_ID = b.SSB_CRMSYSTEM_CONTACT_ID
			ORDER BY a.SSB_CRMSYSTEM_CONTACT_ID
			FOR XML PATH ('')
		), 3, 1000) [MilleniumID]
FROM #Reps b


UPDATE c
SET c.dal_ssb_seatgeeksalesperson = d.RepName
FROM dbo.Contact_Custom c (NOLOCK)
LEFT JOIN (
		SELECT DISTINCT b.SSB_CRMSYSTEM_CONTACT_ID 
			, SUBSTRING(
				(
					SELECT ', '+ a.RepName  AS [text()]
					FROM #Reps a
					WHERE a.SSB_CRMSYSTEM_CONTACT_ID = b.SSB_CRMSYSTEM_CONTACT_ID
					ORDER BY a.SSB_CRMSYSTEM_CONTACT_ID
					FOR XML PATH ('')
				), 3, 1000) RepName
		FROM #Reps b
	) d ON c.SSB_CRMSYSTEM_CONTACT_ID = d.SSB_CRMSYSTEM_CONTACT_ID	


-- SeatGeek Serviceperson --
-- dal_ssb_seatgeekserviceperson
SELECT r.SSB_CRMSYSTEM_CONTACT_ID, ef.dcefStringField2 ServicePerson, r.sourcesystem, r.ss_ranking
INTO #SGRank
FROM Cowboys.mdm.PrimaryFlagRanking_Contact r (NOLOCK)
JOIN Cowboys.ods.SGDW_DimClientExtraFields ef (NOLOCK)
	ON r.ssid = ef.dcefClientId
	AND r.SourceSystem = 'SG'
WHERE  r.ss_ranking = 1

UPDATE a
SET a.dal_ssb_seatgeekserviceperson = CAST(b.ServicePerson AS NVARCHAR(100))
FROM dbo.Contact_Custom a (NOLOCK)
JOIN #SGRank b (NOLOCK)
	ON a.SSB_CRMSYSTEM_CONTACT_ID = b.SSB_CRMSYSTEM_CONTACT_ID



-- Secondary market Buyer --
-- dal_ssb_secondarymarket
UPDATE a
SET a.dal_ssb_secondarymarket = b.TM_activity_name
FROM dbo.Contact_Custom a
LEFT JOIN (
SELECT DISTINCT ssbid.SSB_CRMSYSTEM_CONTACT_ID, f.TM_activity_name
		FROM Cowboys.dbo.FactTicketActivity_V2 f (NOLOCK)
		JOIN Cowboys.dbo.DimTicketCustomer_V2 dtc (NOLOCK)
			ON f.DimTicketCustomerId_Recipient = dtc.DimTicketCustomerId
		JOIN Cowboys.dbo.DimCustomer dc (NOLOCK)
			ON dtc.ETL__SourceSystem = dc.SourceSystem
			AND dtc.ETL__SSID_TM_acct_id = dc.AccountId
		JOIN Cowboys.dbo.dimcustomerssbid ssbid (NOLOCK)
			ON dc.DimCustomerId = ssbid.DimCustomerId) b ON b.SSB_CRMSYSTEM_CONTACT_ID = a.SSB_CRMSYSTEM_CONTACT_ID



--Prep for STH Club, Reserve and Non-Option
SELECT DISTINCT dtc.DimTicketCustomerId, ssbid.SSB_CRMSYSTEM_CONTACT_ID, pl.PriceLevelName, pt.PriceTypeName, dtc.ETL__SourceSystem
INTO #PrepSTHClubReserveNonOption
		FROM Cowboys.dbo.FactTicketSales_V2 f (NOLOCK)
		INNER JOIN Cowboys.dbo.DimTicketCustomer_V2 dtc (NOLOCK)
			ON f.DimTicketCustomerId = dtc.DimTicketCustomerId
		INNER JOIN Cowboys.dbo.DimCustomer dc (NOLOCK)
			ON dtc.ETL__SourceSystem = dc.SourceSystem
			AND dtc.ETL__SSID = dc.SSID
		INNER JOIN Cowboys.dbo.dimcustomerssbid ssbid (NOLOCK)
			ON dc.DimCustomerId = ssbid.DimCustomerId
		JOIN Cowboys.dbo.DimPriceLevel_V2 pl (NOLOCK)
			ON f.DimPriceLevelId = pl.DimPriceLevelId
		JOIN Cowboys.dbo.DimPriceType_V2 pt (NOLOCK)
			ON f.DimPriceTypeId = pt.DimPriceTypeId
			WHERE dtc.ETL__SourceSystem = 'SG'

SELECT t.PriceLevelName, t.PriceTypeName, COUNT(DISTINCT t.SSB_CRMSYSTEM_CONTACT_ID) 
FROM #PrepSTHClubReserveNonOption t
JOIN Cowboys.dbo.FactTicketSales_V2 f ON f.DimTicketCustomerId = t.DimTicketCustomerId AND f.ETL__SourceSystem = t.ETL__SourceSystem
JOIN Cowboys.dbo.DimSeason_V2 ds ON ds.DimSeasonId = f.DimSeasonId
WHERE ds.SeasonYear >= 2017 AND PriceTypeName NOT LIKE '%Parking%' AND PriceTypeName NOT LIKE '%COMP%'
GROUP BY t.PriceLevelName, t.PriceTypeName
ORDER BY t.PriceLevelName, t.PriceTypeName



-- STH Club Buyer --
-- dal_ssb_sthclub
UPDATE a
SET a.dal_ssb_sthclub = b.IsClubSTH
FROM dbo.Contact_Custom a
LEFT JOIN (
		SELECT DISTINCT SSB_CRMSYSTEM_CONTACT_ID, 1 AS IsClubSTH
		--SSB_CRMSYSTEM_CONTACT_ID, 1 AS IsClubSTH
		--SELECT COUNT(DISTINCT SSB_CRMSYSTEM_CONTACT_ID)
		FROM #PrepSTHClubReserveNonOption
		JOIN Cowboys.dbo.FactTicketSales_V2 fts ON fts.DimTicketCustomerId = #PrepSTHClubReserveNonOption.DimTicketCustomerId
		JOIN Cowboys.dbo.DimSeason_V2 ds ON fts.DimSeasonId = ds.DimSeasonId
		WHERE PriceLevelName IN ('A', 'B', 'C', 'D')
			AND PriceTypeName NOT LIKE '%optum%' AND PriceTypeName NOT LIKE '%Parking%' AND PriceTypeName NOT LIKE '%COMP%' AND ds.DimSeasonId IN  (331, 339)
	) b ON a.SSB_CRMSYSTEM_CONTACT_ID = b.SSB_CRMSYSTEM_CONTACT_ID

SELECT * FROM Cowboys.dbo.DimSeason_v2 WHERE seasonyear = 2018

-- STH Reserve Buyer --
-- dal_ssb_sthreserve
UPDATE a
SET a.dal_ssb_sthreserve = b.IsReserveSTH
FROM dbo.Contact_Custom a
LEFT JOIN (
		SELECT DISTINCT SSB_CRMSYSTEM_CONTACT_ID, 1 AS IsReserveSTH
		--SELECT COUNT(DISTINCT SSB_CRMSYSTEM_CONTACT_ID)
		FROM #PrepSTHClubReserveNonOption
		JOIN Cowboys.dbo.FactTicketSales_V2 fts ON fts.DimTicketCustomerId = #PrepSTHClubReserveNonOption.DimTicketCustomerId
		JOIN Cowboys.dbo.DimSeason_V2 ds ON fts.DimSeasonId = ds.DimSeasonId
		WHERE PriceLevelName IN ('E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N')
			AND PriceTypeName NOT LIKE '%FAA%' AND PriceTypeName NOT LIKE '%Parking%' AND PriceTypeName NOT LIKE '%COMP%' AND ds.DimSeasonId IN  (331, 339)
	) b ON a.SSB_CRMSYSTEM_CONTACT_ID = b.SSB_CRMSYSTEM_CONTACT_ID


-- STH Non Option --
-- dal_ssb_sthnonoption
UPDATE a
SET a.dal_ssb_sthnonoption = b.IsNonOptionSTH
FROM dbo.Contact_Custom a
LEFT JOIN (
		SELECT DISTINCT SSB_CRMSYSTEM_CONTACT_ID, 1 AS IsNonOptionSTH
		--SELECT COUNT(DISTINCT SSB_CRMSYSTEM_CONTACT_ID)
		FROM #PrepSTHClubReserveNonOption
		JOIN Cowboys.dbo.FactTicketSales_V2 fts ON fts.DimTicketCustomerId = #PrepSTHClubReserveNonOption.DimTicketCustomerId
		JOIN Cowboys.dbo.DimSeason_V2 ds ON fts.DimSeasonId = ds.DimSeasonId
		WHERE PriceLevelName IN ('O', 'P') AND PriceTypeName NOT LIKE '%Parking%' AND PriceTypeName NOT LIKE '%COMP%' AND ds.DimSeasonId IN  (331, 339)
	) b ON a.SSB_CRMSYSTEM_CONTACT_ID = b.SSB_CRMSYSTEM_CONTACT_ID


--Prep data for STH Legends, STH Owner, STH Founder, STH Suite Reg, Suite Owner, Suite Legends
--SELECT DISTINCT dc.SSB_CRMSYSTEM_CONTACT_ID, e.EventDate, PriceTypeName	, dtc.ETL__SourceSystem
--into #PrepforSTHLegOwnerFounderSuite
--		FROM Cowboys.dbo.FactTicketSales_V2 f (NOLOCK)
--		JOIN Cowboys.dbo.DimPriceType_V2 pt (NOLOCK)
--			ON f.DimPriceTypeId = pt.DimPriceTypeId
--		JOIN Cowboys.dbo.DimEvent_V2 e (NOLOCK)
--			ON f.DimEventId = e.DimEventId
--		JOIN Cowboys.dbo.DimTicketCustomer_V2 dtc (NOLOCK)
--			ON f.DimTicketCustomerId = dtc.DimTicketCustomerId
--		JOIN Cowboys.dbo.vwDimCustomer_ModAcctId dc (NOLOCK)
--			ON dtc.ETL__SourceSystem = dc.SourceSystem
--			AND dtc.ETL__SSID = dc.SSID
--		INNER JOIN Cowboys.ods.SGDW_DimClients sgdw 
--			ON dc.AccountId = sgdw.dcClientCode
--			AND sgdw.dcClientGUID = f.ETL__SSID_SG_client_guid
--		WHERE e.EventDate >= DATEADD(YEAR, -1, GETDATE())
--			AND dtc.ETL__SourceSystem = 'SG'



-- STH Legends --
-- dal_ssb_sthlegends
UPDATE a
SET a.dal_ssb_sthlegends = b.IsOptumSTH
FROM dbo.Contact_Custom a
LEFT JOIN (
		SELECT DISTINCT SSB_CRMSYSTEM_CONTACT_ID, 1 IsOptumSTH
		FROM #PrepSTHClubReserveNonOption
	--	JOIN Cowboys.dbo.FactTicketSales_V2 fts ON fts.DimTicketCustomerId = #PrepSTHClubReserveNonOption.DimTicketCustomerId
	--	JOIN Cowboys.dbo.DimSeason_V2 ds ON fts.DimSeasonId = ds.DimSeasonId
		WHERE  PriceTypeName LIKE '%optum%'
			AND PriceTypeName NOT LIKE '%Suite%'
	) b ON a.SSB_CRMSYSTEM_CONTACT_ID = b.SSB_CRMSYSTEM_CONTACT_ID


-- STH Owners --
-- dal_ssb_sthowners
UPDATE a
SET a.dal_ssb_sthowners = b.IsOwnersSTH
FROM dbo.Contact_Custom a
LEFT JOIN (
		SELECT DISTINCT SSB_CRMSYSTEM_CONTACT_ID, 1 IsOwnersSTH
		FROM #PrepSTHClubReserveNonOption
		WHERE  PriceTypeName LIKE '%owner%'
			AND PriceTypeName NOT LIKE '%Suite%'
	) b ON a.SSB_CRMSYSTEM_CONTACT_ID = b.SSB_CRMSYSTEM_CONTACT_ID


-- STH Founders --
-- dal_ssb_sthfounders
UPDATE a
SET a.dal_ssb_sthfounders = b.IsFoundersSTH
FROM dbo.Contact_Custom a
LEFT JOIN (
		SELECT DISTINCT SSB_CRMSYSTEM_CONTACT_ID, 1 IsFoundersSTH
		FROM #PrepSTHClubReserveNonOption
		WHERE  PriceTypeName LIKE '%FAA%'
			AND PriceTypeName NOT LIKE '%Suite%'
	) b ON a.SSB_CRMSYSTEM_CONTACT_ID = b.SSB_CRMSYSTEM_CONTACT_ID


-- Suite Regular --
-- dal_ssb_suiteregular
UPDATE a
SET a.dal_ssb_suiteregular = b.IsRegularSuiteBuyer
FROM dbo.Contact_Custom a
LEFT JOIN (
		SELECT DISTINCT SSB_CRMSYSTEM_CONTACT_ID, 1 IsRegularSuiteBuyer
		FROM #PrepSTHClubReserveNonOption
		WHERE  PriceTypeName IN ('NEW Suite', 'NEW Suite SRO', 'RENEWAL Suite', 'RENEWAL Suite SRO')
	) b ON a.SSB_CRMSYSTEM_CONTACT_ID = b.SSB_CRMSYSTEM_CONTACT_ID


-- Suite Owners --
-- dal_ssb_suiteowners
UPDATE a
SET a.dal_ssb_suiteowners = ISNULL(b.IsOwnersSuiteBuyer, 0)
FROM dbo.Contact_Custom a
LEFT JOIN (
		SELECT DISTINCT SSB_CRMSYSTEM_CONTACT_ID, 1 IsOwnersSuiteBuyer
		FROM #PrepSTHClubReserveNonOption
		WHERE PriceTypeName IN ('NEW Suite AI', 'RENEWAL Suite AI')
	) b ON a.SSB_CRMSYSTEM_CONTACT_ID = b.SSB_CRMSYSTEM_CONTACT_ID


-- Suite Legends --
-- dal_ssb_suitelegends
UPDATE a
SET a.dal_ssb_suitelegends = ISNULL(b.IsOptumSuiteBuyer, 0)
FROM dbo.Contact_Custom a
LEFT JOIN (
		SELECT DISTINCT SSB_CRMSYSTEM_CONTACT_ID, 1 IsOptumSuiteBuyer
		FROM #PrepSTHClubReserveNonOption
		WHERE PriceTypeName IN ('NEW Suite AI Optum', 'NEW Suite AI Optum SRO', 'RENEWAL Suite AI Optum SRO', 'RENEWAL Suite AI Optum')
	) b ON a.SSB_CRMSYSTEM_CONTACT_ID = b.SSB_CRMSYSTEM_CONTACT_ID


--Prep Stadium Club and PGL
SELECT DISTINCT dc.SSB_CRMSYSTEM_CONTACT_ID, 	e.Config_Category3 , e.Config_Category1 ,DimTicketTypeId
INTO #PrepSCandPGL
		FROM Cowboys.dbo.FactTicketSales_V2 f (NOLOCK)
		JOIN Cowboys.dbo.DimEvent_V2 e (NOLOCK)
			ON f.DimEventId = e.DimEventId
		JOIN Cowboys.dbo.DimTicketCustomer_V2 dtc (NOLOCK)
			ON f.DimTicketCustomerId = dtc.DimTicketCustomerId
		JOIN Cowboys.dbo.vwDimCustomer_ModAcctId dc (NOLOCK)
			ON dtc.ETL__SourceSystem = dc.SourceSystem
			AND dtc.ETL__SSID_TM_acct_id = dc.AccountId
		WHERE e.EventDate >= DATEADD(YEAR, -1, GETDATE())
		

-- Stadium Club --
-- dal_ssb_stadiumclub
UPDATE a
SET a.dal_ssb_stadiumclub = ISNULL(b.IsStadiumClubBuyer, 0)
FROM dbo.Contact_Custom a
LEFT JOIN (
		SELECT DISTINCT SSB_CRMSYSTEM_CONTACT_ID, 1 IsStadiumClubBuyer
		FROM #PrepSCandPGL
		WHERE DimTicketTypeId = 8
	) b ON a.SSB_CRMSYSTEM_CONTACT_ID = b.SSB_CRMSYSTEM_CONTACT_ID


-- Secondary Buyer --
-- dal_ssb_secondarybuyer

UPDATE a
SET a.dal_ssb_secondarybuyer = ISNULL(b.Buyer, 0)
FROM dbo.Contact_Custom a
LEFT JOIN (
SELECT DISTINCT ssbid.SSB_CRMSYSTEM_CONTACT_ID, 1 Buyer
		FROM Cowboys.dbo.FactTicketActivity_V2 f (NOLOCK)
		JOIN Cowboys.dbo.DimTicketCustomer_V2 dtc (NOLOCK)
			ON f.DimTicketCustomerId_Recipient = dtc.DimTicketCustomerId
		JOIN Cowboys.dbo.DimCustomer dc (NOLOCK)
			ON dtc.ETL__SourceSystem = dc.SourceSystem
			AND dtc.ETL__SSID_TM_acct_id = dc.AccountId
		JOIN Cowboys.dbo.dimcustomerssbid ssbid (NOLOCK)
			ON dc.DimCustomerId = ssbid.DimCustomerId) b ON b.SSB_CRMSYSTEM_CONTACT_ID = a.SSB_CRMSYSTEM_CONTACT_ID

-- Secondary Seller --
-- dal_ssb_secondaryseller

UPDATE a
SET a.dal_ssb_secondaryseller = ISNULL(b.Seller, 0)
FROM dbo.Contact_Custom a
LEFT JOIN (
SELECT DISTINCT ssbid.SSB_CRMSYSTEM_CONTACT_ID, 1 seller
		FROM Cowboys.dbo.FactTicketActivity_V2 f (NOLOCK)
		JOIN Cowboys.dbo.DimTicketCustomer_V2 dtc (NOLOCK)
			ON f.DimTicketCustomerId = dtc.DimTicketCustomerId
		JOIN Cowboys.dbo.DimCustomer dc (NOLOCK)
			ON dtc.ETL__SourceSystem = dc.SourceSystem
			AND dtc.ETL__SSID_TM_acct_id = dc.AccountId
		JOIN Cowboys.dbo.dimcustomerssbid ssbid (NOLOCK)
			ON dc.DimCustomerId = ssbid.DimCustomerId) b ON b.SSB_CRMSYSTEM_CONTACT_ID = a.SSB_CRMSYSTEM_CONTACT_ID

-- PGL Cowboys --
-- dal_ssb_pglcowboys
UPDATE a
SET a.dal_ssb_pglcowboys = ISNULL(b.CowboysPGL, 0)
FROM dbo.Contact_Custom a
LEFT JOIN (
		SELECT DISTINCT SSB_CRMSYSTEM_CONTACT_ID, 1 CowboysPGL
		FROM #PrepSCandPGL
		WHERE Config_Category3 = 'PGL' AND Config_Category1 = 'Cowboys'
	) b ON a.SSB_CRMSYSTEM_CONTACT_ID = b.SSB_CRMSYSTEM_CONTACT_ID


-- PGL Other --
-- dal_ssb_pglother
UPDATE a
SET a.dal_ssb_pglother = ISNULL(b.NonCowboysPGL, 0)
FROM dbo.Contact_Custom a
LEFT JOIN (
		SELECT DISTINCT SSB_CRMSYSTEM_CONTACT_ID, 1 NonCowboysPGL
		FROM #PrepSCandPGL
		WHERE Config_Category3 = 'PGL' AND Config_Category1 <> 'Cowboys'
	) b ON a.SSB_CRMSYSTEM_CONTACT_ID = b.SSB_CRMSYSTEM_CONTACT_ID

DROP TABLE #PrepSTHClubReserveNonOption


-- Cowboys Founders Prospects --
SELECT DISTINCT ssbid.SSB_CRMSYSTEM_CONTACT_ID
INTO #Section210Or235Buyers
FROM Cowboys.dbo.FactTicketSales_V2 f (NOLOCK)
JOIN Cowboys.dbo.DimEvent_V2 e (NOLOCK)
	ON f.DimEventId = e.DimEventId
JOIN Cowboys.dbo.DimSeat_V2 s (NOLOCK)
	ON f.DimSeatId_Start = s.DimSeatId
JOIN Cowboys.dbo.DimTicketCustomer_V2 dtc (NOLOCK)
	ON f.DimTicketCustomerId = dtc.DimTicketCustomerId
LEFT JOIN Cowboys.dbo.DimCustomer dcsg (NOLOCK)
	ON dtc.ETL__SourceSystem = dcsg.SourceSystem
	AND dtc.ETL__SSID = dcsg.ssid
	AND dcsg.SourceSystem = 'SG'
LEFT JOIN Cowboys.dbo.DimCustomer dctm (NOLOCK)
	ON dtc.ETL__SourceSystem = dctm.SourceSystem
	AND dtc.ETL__SSID = CAST(dctm.AccountId AS NVARCHAR(255))
	AND dctm.CustomerType = 'Primary'
	AND dctm.SourceSystem = 'TM'
JOIN Cowboys.dbo.DimCustomerssbid ssbid (NOLOCK)
	ON COALESCE(dctm.DimCustomerId, dcsg.DimCustomerId) = ssbid.DimCustomerId
WHERE (s.SectionName LIKE '%210%' OR s.SectionName LIKE '%235%')
	AND e.Config_Category1 = 'Cowboys'

SELECT DISTINCT ssbid.SSB_CRMSYSTEM_CONTACT_ID
INTO #CurrentSTH
FROM Cowboys.dbo.FactTicketSales_V2 f (NOLOCK)
JOIN Cowboys.dbo.DimSeason_V2 s (NOLOCK)
	ON f.DimSeasonId = s.DimSeasonId
JOIN Cowboys.dbo.DimTicketCustomer_V2 dtc (NOLOCK)
	ON f.DimTicketCustomerId = dtc.DimTicketCustomerId
JOIN Cowboys.dbo.DimCustomer dcsg (NOLOCK)
	ON dtc.ETL__SourceSystem = dcsg.SourceSystem
	AND dtc.ETL__SSID = dcsg.ssid
	AND dcsg.SourceSystem = 'SG'
JOIN Cowboys.dbo.DimCustomerssbid ssbid (NOLOCK)
	ON dcsg.DimCustomerId = ssbid.DimCustomerId
WHERE s.SeasonYear = '2018'
	AND f.DimTicketTypeId = 1

SELECT DISTINCT ssbid.SSB_CRMSYSTEM_CONTACT_ID
INTO #BigSpender
FROM Cowboys.dbo.FactTicketSales_V2 f (NOLOCK)
JOIN Cowboys.dbo.DimTicketCustomer_V2 dtc (NOLOCK)
	ON f.DimTicketCustomerId = dtc.DimTicketCustomerId
LEFT JOIN Cowboys.dbo.DimCustomer dcsg (NOLOCK)
	ON dtc.ETL__SourceSystem = dcsg.SourceSystem
	AND dtc.ETL__SSID = dcsg.ssid
	AND dcsg.SourceSystem = 'SG'
LEFT JOIN Cowboys.dbo.DimCustomer dctm (NOLOCK)
	ON dtc.ETL__SourceSystem = dctm.SourceSystem
	AND dtc.ETL__SSID = CAST(dctm.AccountId AS NVARCHAR(255))
	AND dctm.CustomerType = 'Primary'
	AND dctm.SourceSystem = 'TM'
JOIN Cowboys.dbo.DimCustomerssbid ssbid (NOLOCK)
	ON COALESCE(dctm.DimCustomerId, dcsg.DimCustomerId) = ssbid.DimCustomerId
WHERE f.RevenueTotal >= 1000

UPDATE a
SET a.new_ssb_foundersprospect_cowboys = ISNULL(b.IsProspect, 0)
FROM dbo.Contact_Custom a
LEFT JOIN (
		SELECT DISTINCT s.SSB_CRMSYSTEM_CONTACT_ID, 1 IsProspect
		FROM #Section210Or235Buyers s
		JOIN #BigSpender bs
			ON s.SSB_CRMSYSTEM_CONTACT_ID = bs.SSB_CRMSYSTEM_CONTACT_ID
		LEFT JOIN #CurrentSTH sth
			ON s.SSB_CRMSYSTEM_CONTACT_ID = sth.SSB_CRMSYSTEM_CONTACT_ID
		WHERE sth.SSB_CRMSYSTEM_CONTACT_ID IS NULL
	) b ON a.SSB_CRMSYSTEM_CONTACT_ID = b.SSB_CRMSYSTEM_CONTACT_ID


-- College Football Founders Prospects --
SELECT DISTINCT ssbid.SSB_CRMSYSTEM_CONTACT_ID
INTO #SectionBuyers
FROM Cowboys.dbo.FactTicketSales_V2 f (NOLOCK)
JOIN Cowboys.dbo.DimEvent_V2 e (NOLOCK)
	ON f.DimEventId = e.DimEventId
JOIN Cowboys.dbo.DimSeat_V2 s (NOLOCK)
	ON f.DimSeatId_Start = s.DimSeatId
JOIN Cowboys.dbo.DimTicketCustomer_V2 dtc (NOLOCK)
	ON f.DimTicketCustomerId = dtc.DimTicketCustomerId
LEFT JOIN Cowboys.dbo.DimCustomer dcsg (NOLOCK)
	ON dtc.ETL__SourceSystem = dcsg.SourceSystem
	AND dtc.ETL__SSID = dcsg.ssid
	AND dcsg.SourceSystem = 'SG'
LEFT JOIN Cowboys.dbo.DimCustomer dctm (NOLOCK)
	ON dtc.ETL__SourceSystem = dctm.SourceSystem
	AND dtc.ETL__SSID = CAST(dctm.AccountId AS NVARCHAR(255))
	AND dctm.CustomerType = 'Primary'
	AND dctm.SourceSystem = 'TM'
JOIN Cowboys.dbo.DimCustomerssbid ssbid (NOLOCK)
	ON COALESCE(dctm.DimCustomerId, dcsg.DimCustomerId) = ssbid.DimCustomerId
WHERE (s.SectionName LIKE '%210%' OR s.SectionName LIKE '%235%' OR s.SectionName LIKE '%132%'
	OR s.SectionName LIKE '%133%' OR s.SectionName LIKE '%134%' OR s.SectionName LIKE '%135%'
	OR s.SectionName LIKE '%136%' OR s.SectionName LIKE '%137%' OR s.SectionName LIKE '%138%'
	OR s.SectionName LIKE '%139%')
	AND e.Config_Category2 = 'Football (College)'

SELECT DISTINCT ssbid.SSB_CRMSYSTEM_CONTACT_ID
INTO #CollegeBigSpender
FROM Cowboys.dbo.FactTicketSales_V2 f (NOLOCK)
JOIN Cowboys.dbo.DimTicketCustomer_V2 dtc (NOLOCK)
	ON f.DimTicketCustomerId = dtc.DimTicketCustomerId
LEFT JOIN Cowboys.dbo.DimCustomer dcsg (NOLOCK)
	ON dtc.ETL__SourceSystem = dcsg.SourceSystem
	AND dtc.ETL__SSID = dcsg.ssid
	AND dcsg.SourceSystem = 'SG'
LEFT JOIN Cowboys.dbo.DimCustomer dctm (NOLOCK)
	ON dtc.ETL__SourceSystem = dctm.SourceSystem
	AND dtc.ETL__SSID = CAST(dctm.AccountId AS NVARCHAR(255))
	AND dctm.CustomerType = 'Primary'
	AND dctm.SourceSystem = 'TM'
JOIN Cowboys.dbo.DimCustomerssbid ssbid (NOLOCK)
	ON COALESCE(dctm.DimCustomerId, dcsg.DimCustomerId) = ssbid.DimCustomerId
WHERE f.RevenueTotal >= 500

UPDATE a
SET a.new_ssb_foundersprospect_collegefootball = ISNULL(b.IsProspect, 0)
FROM dbo.Contact_Custom a
LEFT JOIN (
		SELECT DISTINCT s.SSB_CRMSYSTEM_CONTACT_ID, 1 IsProspect
		FROM #SectionBuyers s
		JOIN #CollegeBigSpender bs
			ON s.SSB_CRMSYSTEM_CONTACT_ID = bs.SSB_CRMSYSTEM_CONTACT_ID
	) b ON a.SSB_CRMSYSTEM_CONTACT_ID = b.SSB_CRMSYSTEM_CONTACT_ID



--ParentCustomerID and ParentCustomerIdType --
;WITH Accounts
AS (
	SELECT c.SSB_CRMSYSTEM_CONTACT_ID, ssb.ssid
		, ROW_NUMBER() OVER (PARTITION BY c.SSB_CRMSYSTEM_CONTACT_ID ORDER BY ssb.SSB_CRMSYSTEM_PRIMARY_FLAG, ssb.SSCreatedDate) accountrank
	FROM dbo.Contact c
	INNER JOIN dbo.vwDimCustomer_ModAcctId ssb
		ON ssb.SSB_CRMSYSTEM_ACCT_ID = c.SSB_CRMSYSTEM_ACCT_ID
		AND ssb.SourceSystem = 'crm_account'
) 

UPDATE cc
SET cc.parentcustomerid = a.SSID
	, cc.parentcustomeridtype = 'account'
FROM dbo.Contact_Custom cc 
INNER JOIN Accounts a
	ON a.SSB_CRMSYSTEM_CONTACT_ID = cc.SSB_CRMSYSTEM_CONTACT_ID
;

UPDATE cc --Override SSBID with anything that is already in CRM
SET parentcustomerid = pc.parentcustomerid
	, parentcustomeridtype = pc.parentcustomeridtype
FROM dbo.contact_custom cc
INNER JOIN dbo.contact c
	ON c.SSB_CRMSYSTEM_CONTACT_ID = cc.SSB_CRMSYSTEM_CONTACT_ID
INNER JOIN Prodcopy.vw_Contact pc
	ON pc.contactid = c.crm_id
WHERE pc.parentcustomeridname IS NOT NULL;


EXEC dbo.sp_CRMLoad_Contact_ProcessLoad_Criteria;

GO
