SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE VIEW [dbo].[vwCRMLoad_Contact_Custom_Update]
AS

SELECT  z.[crm_id] contactid
, b.new_ssbcrmsystemssidwinner								--,c.new_ssbcrmsystemssidwinner
,b.new_ssbSSIDWinnerSourceSystem							--,c.new_ssbcrmsystemSSIDWinnerSourceSystem
--, TM_Ids [new_ssbcrmsystemarchticsids]					--,c.
, DimCustIDs new_ssbcrmsystemdimcustomerids					--,c.new_ssbcrmsystemdimcustomerids
--, b.AccountId str_number									--,c.[new_ssbcrmsystemarchticsids]
, b.AccountId [str_number]									--,c.str_number										--updateme for STR clients
, z.EmailPrimary AS emailaddress1							--,c.emailaddress1
,b.dal_ssb_seatgeekaccountid								--,c.dal_ssb_seatgeekaccountid
,b.dal_ssb_seatgeeksalesperson								--,c.dal_ssb_seatgeeksalesperson
,b.dal_ssb_seatgeekserviceperson							--,c.dal_ssb_seatgeekserviceperson
,b.dal_ssb_additionalinfo1									--,c.dal_ssb_additionalinfo1
,b.dal_ssb_additionalinfo2									--,c.dal_ssb_additionalinfo2
,b.dal_ssb_additionalinfo3									--,c.dal_ssb_additionalinfo3
,b.dal_ssb_additionalinfo4									--,c.dal_ssb_additionalinfo4
,b.dal_ssb_additionalinfo5									--,c.dal_ssb_additionalinfo5
,b.dal_ssb_secondarymarket									--,c.dal_ssb_secondarymarket
,b.dal_ssb_sthclub											--,c.dal_ssb_sthclub
,b.dal_ssb_sthreserve										--,c.dal_ssb_sthreserve
,b.dal_ssb_sthnonoption										--,c.dal_ssb_sthnonoption
,b.dal_ssb_sthlegends										--,c.dal_ssb_sthlegends
,b.dal_ssb_sthowners										--,c.dal_ssb_sthowners
,b.dal_ssb_sthfounders										--,c.dal_ssb_sthfounders
,b.dal_ssb_suiteregular										--,c.dal_ssb_suiteregular
,b.dal_ssb_suiteowners										--,c.dal_ssb_suiteowners
,b.dal_ssb_suitelegends										--,c.dal_ssb_suitelegends
,b.dal_ssb_stadiumclub										--,c.dal_ssb_stadiumclub
,b.dal_ssb_cowboysclub										--,c.dal_ssb_cowboysclub
,b.dal_ssb_cowboysfit										--,c.dal_ssb_cowboysfit
,b.dal_ssb_secondarybuyer									--,c.dal_ssb_secondarybuyer
,b.dal_ssb_secondaryseller									--,c.dal_ssb_secondaryseller
,b.dal_ssb_pglcowboys										--,c.dal_ssb_pglcowboys
,b.dal_ssb_pglother											--,c.dal_ssb_pglother
,b.new_ssb_spend12months_cowboysevents						--,c.new_ssb_spend12months_cowboysevents
,b.new_ssb_spend12months_noncowboysevents					--,c.new_ssb_spend12months_noncowboysevents
,b.new_ssb_spend12months_merch								--,c.new_ssb_spend12months_merch
,b.new_ssb_youthcamps										--,c.new_ssb_youthcamps
,b.new_ssb_fanclub											--,c.new_ssb_fanclub
,ISNULL(NULLIF(b.mobilephone,''),c.mobilephone) mobilephone	--,c.mobilephone
,ISNULL(NULLIF(b.telephone2,''),c.telephone2) telephone2	--,c.telephone2
,b.SSB_CRMSYSTEM_CONTACT_ID AS str_DWID
,b.new_ssbprimaryseatgeekid

--,CASE WHEN  HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(b.new_ssbcrmsystemssidwinner)),'') )  <> HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST(c.new_ssbcrmsystemssidwinner AS VARCHAR(MAX)))),'')) 					 then 1 else 0 end as new_ssbcrmsystemssidwinner
--,CASE WHEN  HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(b.[new_ssbSSIDWinnerSourceSystem])),'') )  <> HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST(c.new_ssbcrmsystemSSIDWinnerSourceSystem AS VARCHAR(MAX)))),''))  then 1 else 0 end as new_ssbcrmsystemSSIDWinnerSourceSystem
----,CASE WHEN  HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(b.DimCustIDs)),'') )  <> HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST(c.new_ssbcrmsystemdimcustomerids AS VARCHAR(MAX)))),'')) 								 then 1 else 0 end as new_ssbcrmsystemdimcustomerids
--,CASE WHEN  HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(b.AccountId)),'') )  <> HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST(c.str_number AS VARCHAR(MAX)))),''))													 then 1 else 0 end as str_number
--,CASE WHEN  ISNULL(b.dal_ssb_seatgeekaccountid,'') != ISNULL(c.dal_ssb_seatgeekaccountid,'')								 then 1 else 0 end as dal_ssb_seatgeekaccountid
--,CASE WHEN  ISNULL(b.dal_ssb_seatgeeksalesperson,'') != ISNULL(c.dal_ssb_seatgeeksalesperson,'')							 then 1 else 0 end as dal_ssb_seatgeeksalesperson
--,CASE WHEN  ISNULL(b.dal_ssb_seatgeekserviceperson,'') != ISNULL(c.dal_ssb_seatgeekserviceperson,'')						 then 1 else 0 end as dal_ssb_seatgeekserviceperson
--,CASE WHEN  ISNULL(b.dal_ssb_additionalinfo1,'') != ISNULL(c.dal_ssb_additionalinfo1,'')									 then 1 else 0 end as dal_ssb_additionalinfo1
--,CASE WHEN  ISNULL(b.dal_ssb_additionalinfo2,'') != ISNULL(c.dal_ssb_additionalinfo2,'')									 then 1 else 0 end as dal_ssb_additionalinfo2
--,CASE WHEN  ISNULL(b.dal_ssb_additionalinfo3,'') != ISNULL(c.dal_ssb_additionalinfo3,'')									 then 1 else 0 end as dal_ssb_additionalinfo3
--,CASE WHEN  ISNULL(b.dal_ssb_additionalinfo4,'') != ISNULL(c.dal_ssb_additionalinfo4,'')									 then 1 else 0 end as dal_ssb_additionalinfo4
--,CASE WHEN  ISNULL(b.dal_ssb_additionalinfo5,'') != ISNULL(c.dal_ssb_additionalinfo5,'')									 then 1 else 0 end as dal_ssb_additionalinfo5
--,CASE WHEN  ISNULL(b.dal_ssb_secondarymarket,'') != ISNULL(c.dal_ssb_secondarymarket,'')									 then 1 else 0 end as dal_ssb_secondarymarket
--,CASE WHEN  ISNULL(b.dal_ssb_sthclub,'') != ISNULL(c.dal_ssb_sthclub,'')													 then 1 else 0 end as dal_ssb_sthclub
--,CASE WHEN  ISNULL(b.dal_ssb_sthreserve,'') != ISNULL(c.dal_ssb_sthreserve,'')												 then 1 else 0 end as dal_ssb_sthreserve
--,CASE WHEN  ISNULL(b.dal_ssb_sthnonoption,'') != ISNULL(c.dal_ssb_sthnonoption,'')											 then 1 else 0 end as dal_ssb_sthnonoption
--,CASE WHEN  ISNULL(b.dal_ssb_sthlegends,'') != ISNULL(c.dal_ssb_sthlegends,'')												 then 1 else 0 end as dal_ssb_sthlegends
--,CASE WHEN  ISNULL(b.dal_ssb_sthowners,'') != ISNULL(c.dal_ssb_sthowners,'')												 then 1 else 0 end as dal_ssb_sthowners
--,CASE WHEN  ISNULL(b.dal_ssb_sthfounders,'') != ISNULL(c.dal_ssb_sthfounders,'')											 then 1 else 0 end as dal_ssb_sthfounders
--,CASE WHEN  ISNULL(b.dal_ssb_suiteregular,'') != ISNULL(c.dal_ssb_suiteregular,'')											 then 1 else 0 end as dal_ssb_suiteregular
--,CASE WHEN  ISNULL(b.dal_ssb_suiteowners,'') != ISNULL(c.dal_ssb_suiteowners,'')											 then 1 else 0 end as dal_ssb_suiteowners
--,CASE WHEN  ISNULL(b.dal_ssb_suitelegends,'') != ISNULL(c.dal_ssb_suitelegends,'')											 then 1 else 0 end as dal_ssb_suitelegends
--,CASE WHEN  ISNULL(b.dal_ssb_stadiumclub,'') != ISNULL(c.dal_ssb_stadiumclub,'')											 then 1 else 0 end as dal_ssb_stadiumclub
--,CASE WHEN  ISNULL(b.dal_ssb_cowboysclub,'') != ISNULL(c.dal_ssb_cowboysclub,'')											 then 1 else 0 end as dal_ssb_cowboysclub
--,CASE WHEN  ISNULL(b.dal_ssb_cowboysfit,'') != ISNULL(c.dal_ssb_cowboysfit,'')												 then 1 else 0 end as dal_ssb_cowboysfit
--,CASE WHEN  ISNULL(b.dal_ssb_secondarybuyer,'') != ISNULL(c.dal_ssb_secondarybuyer,'')										 then 1 else 0 end as dal_ssb_secondarybuyer
--,CASE WHEN  ISNULL(b.dal_ssb_secondaryseller,'') != ISNULL(c.dal_ssb_secondaryseller,'')									 then 1 else 0 end as dal_ssb_secondaryseller
--,CASE WHEN  ISNULL(b.dal_ssb_pglcowboys,'') != ISNULL(c.dal_ssb_pglcowboys,'')												 then 1 else 0 end as dal_ssb_pglcowboys
--,CASE WHEN  ISNULL(b.dal_ssb_pglother,'') != ISNULL(c.dal_ssb_pglother,'')													 then 1 else 0 end as dal_ssb_pglother
--,CASE WHEN  ISNULL(CAST(b.new_ssb_spend12months_cowboysevents AS INT),0) != ISNULL(c.new_ssb_spend12months_cowboysevents,0)		 then 1 else 0 end as new_ssb_spend12months_cowboysevents
--,CASE WHEN  ISNULL(CAST(b.new_ssb_spend12months_noncowboysevents AS INT),0) != ISNULL(c.new_ssb_spend12months_noncowboysevents,0)		 then 1 else 0 end as new_ssb_spend12months_noncowboysevents
--,CASE WHEN  ISNULL(CAST(b.new_ssb_spend12months_merch AS INT),0) != ISNULL(c.new_ssb_spend12months_merch,0)		 then 1 else 0 end as new_ssb_spend12months_merch
--,CASE WHEN  ISNULL(b.new_ssb_youthcamps,0) != ISNULL(c.new_ssb_youthcamps,0)												 then 1 else 0 end as new_ssb_youthcamps
--,CASE WHEN  ISNULL(b.new_ssb_fanclub,0) != ISNULL(c.new_ssb_fanclub,0)														 then 1 else 0 end as new_ssb_fanclub
--,CASE WHEN  ISNULL(NULLIF(b.mobilephone,''),c.mobilephone) != ISNULL(c.mobilephone,'')														 then 1 else 0 end as mobilephone
--,CASE WHEN  ISNULL(NULLIF(b.telephone2,''),c.telephone2) != ISNULL(c.telephone2,'')															 then 1 else 0 end as telephone2

-- SELECT *
-- SELECT COUNT(*) 
FROM dbo.[Contact_Custom] b 
INNER JOIN dbo.Contact z ON b.SSB_CRMSYSTEM_CONTACT_ID = z.[SSB_CRMSYSTEM_CONTACT_ID]
LEFT JOIN  prodcopy.vw_contact c ON z.[crm_id] = c.contactID
--INNER JOIN dbo.CRMLoad_Contact_ProcessLoad_Criteria pl ON b.SSB_CRMSYSTEM_CONTACT_ID = pl.SSB_CRMSYSTEM_CONTACT_ID
LEFT JOIN dbo.vw_KeyAccounts k ON k.ssbid = z.SSB_CRMSYSTEM_CONTACT_ID
WHERE z.[SSB_CRMSYSTEM_CONTACT_ID] <> z.[crm_id]
AND k.ssbid IS NULL
AND  (1=2
	OR HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(b.new_ssbcrmsystemssidwinner)),'') )  <> HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST(c.new_ssbcrmsystemssidwinner AS VARCHAR(MAX)))),'')) 
	OR HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(b.[new_ssbSSIDWinnerSourceSystem])),'') )  <> HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST(c.new_ssbcrmsystemSSIDWinnerSourceSystem AS VARCHAR(MAX)))),'')) 
	--OR HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(b.DimCustIDs)),'') )  <> HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST(c.new_ssbcrmsystemdimcustomerids AS VARCHAR(MAX)))),'')) 
	OR HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(b.AccountId)),'') )  <> HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST(c.str_number AS VARCHAR(MAX)))),''))
--updateme only for STR clients--	OR HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(b.AccountId)),'') )  <> HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST(c.[str_number] AS VARCHAR(MAX)))),''))
	OR ISNULL(b.dal_ssb_seatgeekaccountid,'') != ISNULL(c.dal_ssb_seatgeekaccountid,'')
	OR ISNULL(b.dal_ssb_seatgeeksalesperson,'') != ISNULL(c.dal_ssb_seatgeeksalesperson,'')
	OR ISNULL(b.dal_ssb_seatgeekserviceperson,'') != ISNULL(c.dal_ssb_seatgeekserviceperson,'')
	OR ISNULL(b.dal_ssb_additionalinfo1,'') != ISNULL(c.dal_ssb_additionalinfo1,'')
	OR ISNULL(b.dal_ssb_additionalinfo2,'') != ISNULL(c.dal_ssb_additionalinfo2,'')
	OR ISNULL(b.dal_ssb_additionalinfo3,'') != ISNULL(c.dal_ssb_additionalinfo3,'')
	OR ISNULL(b.dal_ssb_additionalinfo4,'') != ISNULL(c.dal_ssb_additionalinfo4,'')
	OR ISNULL(b.dal_ssb_additionalinfo5,'') != ISNULL(c.dal_ssb_additionalinfo5,'')
	OR ISNULL(b.dal_ssb_secondarymarket,'') != ISNULL(c.dal_ssb_secondarymarket,'')
	OR ISNULL(b.dal_ssb_sthclub,'') != ISNULL(c.dal_ssb_sthclub,'')
	OR ISNULL(b.dal_ssb_sthreserve,'') != ISNULL(c.dal_ssb_sthreserve,'')
	OR ISNULL(b.dal_ssb_sthnonoption,'') != ISNULL(c.dal_ssb_sthnonoption,'')
	OR ISNULL(b.dal_ssb_sthlegends,'') != ISNULL(c.dal_ssb_sthlegends,'')
	OR ISNULL(b.dal_ssb_sthowners,'') != ISNULL(c.dal_ssb_sthowners,'')
	OR ISNULL(b.dal_ssb_sthfounders,'') != ISNULL(c.dal_ssb_sthfounders,'')
	OR ISNULL(b.dal_ssb_suiteregular,'') != ISNULL(c.dal_ssb_suiteregular,'')
	OR ISNULL(b.dal_ssb_suiteowners,'') != ISNULL(c.dal_ssb_suiteowners,'')
	OR ISNULL(b.dal_ssb_suitelegends,'') != ISNULL(c.dal_ssb_suitelegends,'')
	OR ISNULL(b.dal_ssb_stadiumclub,'') != ISNULL(c.dal_ssb_stadiumclub,'')
	OR ISNULL(b.dal_ssb_cowboysclub,'') != ISNULL(c.dal_ssb_cowboysclub,'')
	OR ISNULL(b.dal_ssb_cowboysfit,'') != ISNULL(c.dal_ssb_cowboysfit,'')
	OR ISNULL(b.dal_ssb_secondarybuyer,'') != ISNULL(c.dal_ssb_secondarybuyer,'')
	OR ISNULL(b.dal_ssb_secondaryseller,'') != ISNULL(c.dal_ssb_secondaryseller,'')
	OR ISNULL(b.dal_ssb_pglcowboys,'') != ISNULL(c.dal_ssb_pglcowboys,'')
	OR ISNULL(b.dal_ssb_pglother,'') != ISNULL(c.dal_ssb_pglother,'')
	OR ISNULL(CAST(b.new_ssb_spend12months_cowboysevents AS INT),0) != ISNULL(c.new_ssb_spend12months_cowboysevents,0)
	OR ISNULL(CAST(b.new_ssb_spend12months_noncowboysevents AS INT),0) != ISNULL(c.new_ssb_spend12months_noncowboysevents,0)
	OR ISNULL(CAST(b.new_ssb_spend12months_merch AS INT),0) != ISNULL(c.new_ssb_spend12months_merch,0)
	OR ISNULL(b.new_ssb_youthcamps,0) != ISNULL(c.new_ssb_youthcamps,0)
	OR ISNULL(b.new_ssb_fanclub,0) != ISNULL(c.new_ssb_fanclub,0)
	OR ISNULL(NULLIF(b.mobilephone,''),c.mobilephone) != ISNULL(c.mobilephone,'')
	OR ISNULL(NULLIF(b.telephone2,''),c.telephone2) != ISNULL(c.telephone2,'')
	--OR ISNULL(b.SSB_CRMSYSTEM_CONTACT_ID,'') != ISNULL(c.str_dwid,'')
	OR ISNULL(b.new_ssbprimaryseatgeekid,'') != ISNULL(c.new_ssbprimaryseatgeekid,'')

	)
	

GO
