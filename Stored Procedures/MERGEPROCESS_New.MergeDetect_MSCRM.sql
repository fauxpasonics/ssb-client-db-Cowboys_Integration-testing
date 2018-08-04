SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
 
CREATE PROC [MERGEPROCESS_New].[MergeDetect_MSCRM] --'Cowboys'
    @Client VARCHAR(100) 
AS
Declare @Date Date = (select cast(getdate() as date));
DECLARE @Account VARCHAR(100) = (SELECT CASE WHEN @client = 'Cowboys' THEN 'CRM_Account' ELSE CONCAT(@client,' PC_SFDC Account' ) END);--updateme
DECLARE @Contact VARCHAR(100) = (SELECT CASE WHEN @client = 'Cowboys' THEN 'CRM_Contact' ELSE CONCAT(@client,' PC_SFDC Account' ) END);--updateme
 
WITH MergeAccount AS (
SELECT a.SSB_CRMSYSTEM_ACCT_ID, COUNT(1) CountAccounts, MAX(CASE WHEN b.SSB_CRMSYSTEM_ACCT_ID IS NOT NULL THEN 1 ELSE 0 END) Key_Related
FROM dbo.vwDimCustomer_ModAcctID a
LEFT JOIN (
	SELECT m.SSB_CRMSYSTEM_ACCT_ID
	FROM dbo.vw_KeyAccounts k
	JOIN dbo.vwDimCustomer_ModAcctId m ON m.DimCustomerId = k.dimcustomerid
	WHERE m.SSB_CRMSYSTEM_ACCT_ID IS NOT NULL	
) b ON a.SSB_CRMSYSTEM_ACCT_ID = b.SSB_CRMSYSTEM_ACCT_ID
JOIN prodcopy.vw_account c                          
    ON a.SSID = c.accountid                         
    AND a.SourceSystem = @Account                   
WHERE a.SourceSystem = @Account
AND c.merged = 0                                    
AND c.statecode = 0                  
AND a.SSB_CRMSYSTEM_ACCT_ID IS NOT null           
GROUP BY a.SSB_CRMSYSTEM_ACCT_ID
HAVING COUNT(1) > 1), 
 
 MergeContact AS (
SELECT a.SSB_CRMSYSTEM_CONTACT_ID, COUNT(1) CountContacts, MAX(CASE WHEN k.SSBID IS NOT NULL THEN 1 ELSE 0 END) Key_Related
FROM dbo.vwDimCustomer_ModAcctID a 
LEFT JOIN dbo.vw_KeyAccounts k
ON k.ssbid = a.SSB_CRMSYSTEM_CONTACT_ID
--Had to use the below for Coyotes. Trying above in place of it
--LEFT JOIN (
--    SELECT CAST(cc.contactid AS VARCHAR(100)) ID
--    FROM prodcopy.Contact cc
--    JOIN dbo.vw_KeyAccounts bb
--        ON bb.ssid = CAST(cc.contactid AS NVARCHAR(100))
--    AND cc.merged = 0                                   
--    AND cc.statecode = 0                                
--    ) b     
--    ON a.SSID = b.ID
WHERE SourceSystem = @Contact
AND a.SSB_CRMSYSTEM_CONTACT_ID IS NOT null
GROUP BY a.SSB_CRMSYSTEM_CONTACT_ID
HAVING COUNT(1) > 1)
 


 
MERGE  MERGEPROCESS_New.DetectedMerges  AS tar
USING ( SELECT 'Account' [ObjectType], SSB_CRMSYSTEM_ACCT_ID SSBID, CASE WHEN CountAccounts = 2 AND Key_Related = 0 THEN 1 ELSE 0 END AutoMerge, @Date DetectedDate, CountAccounts NumRecords FROM MergeAccount
        UNION ALL
        SELECT 'Contact' [ObjectType], SSB_CRMSYSTEM_Contact_ID SSBID, CASE WHEN CountContacts = 2 AND Key_Related = 0 THEN 1 ELSE 0 END AutoMerge, @Date DetectedDate, CountContacts NumRecords FROM MergeContact) AS sour
    ON tar.[ObjectType] = sour.[ObjectType]
    AND tar.SSBID = sour.SSBID
WHEN MATCHED  AND (tar.DetectedDate <> sour.DetectedDate 
                OR sour.NumRecords <> tar.NumRecords
                OR sour.AutoMerge <> tar.AutoMerge
                OR 0 <> tar.Mergecomplete) THEN UPDATE
    SET DetectedDate = @Date
    ,NumRecords = sour.NumRecords
    ,AutoMerge = sour.AutoMerge
    ,Mergecomplete = 0
    ,tar.MergeComment = NULL
WHEN NOT MATCHED THEN INSERT
    ([ObjectType]
    ,SSBID
    ,AutoMerge
    ,DetectedDate
    ,NumRecords)
VALUES(
     sour.[ObjectType]
    ,sour.SSBID
    ,sour.AutoMerge
    ,sour.DetectedDate
    ,sour.NumRecords)
WHEN NOT MATCHED BY SOURCE THEN UPDATE
    SET MergeComment = CASE WHEN tar.Mergecomplete = 1 AND tar.MergeComment IS NULL THEN 'Merge Detection - Merge Successfully completed'
                            WHEN tar.mergeComplete = 0 AND tar.MergeComment IS NULL THEN 'Merge Detection - Merge not completed, but not longer detected' END,
        tar.AutoMerge = 0 
    ;
 
 
--NEW CODE for Force Merge Functionality --TCF 09112017
UPDATE MERGEPROCESS_New.DetectedMerges SET Approved = 1
FROM MERGEPROCESS_New.DetectedMerges dm
INNER JOIN MERGEPROCESS_New.ForceMerge fm
ON dm.PK_MergeID = fm.FK_MergeID AND ISNULL(fm.complete,0) = 0 AND fm.CreatedDate > GETDATE() - 14
WHERE ISNULL(Approved,0) != 1
 
 
 

--Materializing Tables for future use in process
IF OBJECT_ID('mergeprocess_new.tmp_pcaccount', 'U') IS NOT NULL 
DROP TABLE mergeprocess_new.tmp_pcaccount; 

IF OBJECT_ID('mergeprocess_new.tmp_pccontact', 'U') IS NOT NULL 
DROP TABLE mergeprocess_new.tmp_pccontact;

IF OBJECT_ID('mergeprocess_new.tmp_dimcust', 'U') IS NOT NULL 
DROP TABLE mergeprocess_new.tmp_dimcust;

select * into mergeprocess_new.tmp_dimcust 
from dbo.vwdimcustomer_modacctid  where SSB_CRMSYSTEM_ACCT_ID in (
select SSB_CRMSYSTEM_ACCT_ID from dbo.vwdimcustomer_modacctid where sourcesystem = @Account group by SSB_CRMSYSTEM_ACCT_ID having count(*) > 1 )
and sourcesystem = @Account
UNION
select * 
from dbo.vwdimcustomer_modacctid  where ssb_crmsystem_contact_id in (
select ssb_crmsystem_contact_id from dbo.vwdimcustomer_modacctid where sourcesystem = @Contact group by ssb_crmsystem_contact_id having count(*) > 1 )
and sourcesystem = @Contact

create nonclustered index ix_tmp_dimcust_acct on mergeprocess_new.tmp_dimcust (sourcesystem, ssb_crmsystem_acct_id)
create nonclustered index ix_tmp_dimcust_contact on mergeprocess_new.tmp_dimcust (sourcesystem, ssb_crmsystem_contact_id)
create nonclustered index ix_tmp_dimcust_ssid on mergeprocess_new.tmp_dimcust (sourcesystem, ssid)


select pcc.* into mergeprocess_new.tmp_pccontact from mergeprocess_new.tmp_dimcust dc
inner join prodcopy.vw_contact pcc on dc.ssid = CAST(pcc.contactid AS NVARCHAR(100))
where dc.sourcesystem = @Contact

SELECT pca.* into mergeprocess_new.tmp_pcaccount from mergeprocess_new.tmp_dimcust dc
inner join prodcopy.vw_account pca with (nolock) on dc.ssid = CAST(pca.accountid AS NVARCHAR(100))
where dc.sourcesystem = @Account


create nonclustered index ix_tmp_pcaccount on mergeprocess_new.tmp_pcaccount (accountid)
create nonclustered index ix_tmp_pccontact on mergeprocess_new.tmp_pccontact (contactid)


 
 
 
 
GO
