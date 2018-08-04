SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
 
 
 
 
CREATE VIEW [MERGEPROCESS_New].[vwMergeAccountRanks]
 
AS
 
SELECT a.SSBID
    , c.Accountid ID
    --Add in custom ranking here
    ,ROW_NUMBER() OVER(PARTITION BY SSBID ORDER BY CASE WHEN owneridname like '%SSB%' THEN 0 
														WHEN owneridname like '%STR%' THEN 1  
														ELSE 99 END DESC, c.createdon, c.Modifiedon DESC) xRank
FROM MERGEPROCESS_New.DetectedMerges a
JOIN mergeprocess_new.tmp_dimcust b 
    ON a.SSBID = b.SSB_CRMSYSTEM_ACCT_ID AND b.SourceSystem = 'crm_contact' --updateme for source system --TCF 09112017
    AND a.[ObjectType] = 'Account'
JOIN mergeprocess_new.tmp_pcaccount c
    ON b.SSID = CAST(c.accountid AS NVARCHAR(100))
    --AND c.statuscodename = 'Active'
WHERE MergeComplete = 0;
 

 
 
GO
