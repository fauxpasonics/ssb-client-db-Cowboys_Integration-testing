SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
 
CREATE PROC [MERGEPROCESS_New].[QueueMerges] --Cowboys
--Exec  [MERGEPROCESS_New].[QueueMerges] 'Cowboys'
    @Client VARCHAR(100) 
AS
--Declare @Client VARCHAR(100) ='Raiders'
--DECLARE @Account VARCHAR(100) = (SELECT CASE WHEN @client = 'Predators' THEN 'CRM_Account' ELSE CONCAT(@client,' CRM Account' ) END);
DECLARE @Contact VARCHAR(100) = (SELECT CASE WHEN @client = 'Cowboys' THEN 'CRM_Contact' ELSE CONCAT(@client,' CRM Contact' ) END ); --updateme
DECLARE @Account VARCHAR(100) = (SELECT CASE WHEN @client = 'Cowboys' THEN 'CRM_Account' ELSE CONCAT(@client,' CRM Account' ) END ); --updateme
--WITH only2Acct as
TRUNCATE TABLE MERGEPROCESS_New.Queue 
INSERT INTO MERGEPROCESS_New.Queue
 
SELECT PK_MergeID, b.[ObjectType],  MAX(CASE WHEN xRank =1 THEN CAST(c.ID AS VARCHAR(100)) END) AS Winner, MAX(CASE WHEN xRank =2 THEN CAST(c.ID AS VARCHAR(100)) END) AS Loser 
FROM mergeprocess_new.tmp_dimcust a 
JOIN MERGEPROCESS_New.DetectedMerges b ON a.SSB_CRMSYSTEM_ACCT_ID = b.SSBID AND SourceSystem = @Account
JOIN MERGEPROCESS_New.vwMergeAccountRanks c ON a.SSID = CAST(c.ID AS VARCHAR(100))
WHERE --(AutoMerge = 1 OR (AutoMerge = 0 AND Approved = 1))
--So there already is some approval, but it looks like it sticks around forever. I'm not sure that I like this. 
--It also doesn't allow you to approve more than a pair of 2. The 2 was placed in there as a failsafe so that if everything magically got merged in MDM, we wouldn't merge downstream. I like this.
--I think this should read ((AutoMerge = 1 and NumRecords = 2) OR Approved = 1) if we decide to keep it as is.
((AutoMerge = 1 and NumRecords = 2) OR Approved = 1)
AND b.[ObjectType] = 'Account'
AND MergeComplete = 0 
GROUP BY PK_MergeID,b.[ObjectType]
HAVING MAX(CASE WHEN xRank =1 THEN CAST(c.ID AS VARCHAR(100)) END) IS NOT NULL AND  MAX(CASE WHEN xRank =2 THEN CAST(c.ID AS VARCHAR(100)) END) IS NOT NULL
 
UNION ALL
 
SELECT PK_MergeID, b.[ObjectType],  MAX(CASE WHEN xRank =1 THEN CAST(c.ID AS VARCHAR(100)) END) AS Winner, MAX(CASE WHEN xRank =2 THEN CAST(c.ID AS VARCHAR(100)) END) AS Loser  
FROM mergeprocess_new.tmp_dimcust a 
JOIN MERGEPROCESS_New.DetectedMerges b ON a.SSB_CRMSYSTEM_Contact_ID = b.SSBID AND SourceSystem = @Contact
JOIN MERGEPROCESS_New.vwMergeContactRanks c ON a.SSID = CAST(c.ID AS VARCHAR(100))
WHERE ((AutoMerge = 1 and NumRecords = 2) OR Approved = 1)
    AND b.[ObjectType] = 'Contact'
    AND MergeComplete = 0 
GROUP BY PK_MergeID,b.[ObjectType]
HAVING MAX(CASE WHEN xRank =1 THEN CAST(c.ID AS VARCHAR(100)) END) IS NOT NULL AND  MAX(CASE WHEN xRank =2 THEN CAST(c.ID AS VARCHAR(100)) END) IS NOT NULL
 
 
 
 
GO
