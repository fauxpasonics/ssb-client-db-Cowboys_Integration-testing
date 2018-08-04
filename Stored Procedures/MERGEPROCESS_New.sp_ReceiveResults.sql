SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
 
create PROC [MERGEPROCESS_New].[sp_ReceiveResults]
 
AS
 
 
--  update winning record
UPDATE A
SET A.MergeComplete = CASE WHEN c.ErrorMessage IS NULL THEN 1 ELSE 0 end,
    A.MergeComment = CASE WHEN c.ErrorMessage IS NULL THEN CONCAT('Merge completed on ',C.ProcessDate,' by SSB.')
                        WHEN C.ErrorMessage LIKE '%Does Not Exist%' OR C.ErrorMessage LIKE '%is deactive%'
                                    THEN CONCAT('Merge not possible, entity is deleted. Attempted on: ',C.ProcessDate,'') END
FROM MERGEPROCESS_New.DetectedMerges A
JOIN MERGEPROCESS_New.[Queue] B
    ON A.PK_MergeID = B.FK_MergeID
    AND A.[ObjectType] = B.ObjectType
JOIN [MERGEPROCESS_New].[ReceiveResults] C
    ON C.subordinateid = B.Losing_ID 
    AND c.targetid = b.Winning_ID
    AND c.ObjectType = b.ObjectType --Need to add ObjectType constant to SSIS Package
 
 
--NEW CODE for Force Merge Functionality --TCF 09112017
UPDATE MERGEPROCESS_New.ForceMerge
SET Complete = 1, CompletedDate = GETDATE(), CompletionNotes = 'Successfully Completed'
FROM  MERGEPROCESS_New.ForceMerge a
INNER JOIN MERGEPROCESS_New.[Queue] B
ON B.FK_MergeID = a.FK_MergeID
INNER JOIN MERGEPROCESS_New.DetectedMerges dm
ON dm.PK_MergeID = b.FK_MergeID
JOIN [MERGEPROCESS_New].[ReceiveResults] C
    ON C.subordinateid = B.Losing_ID 
    AND c.targetid = b.Winning_ID
    AND c.ObjectType = b.ObjectType 
WHERE c.ErrorMessage IS NULL
AND a.Complete = 0
AND dm.NumRecords = 2

UPDATE MERGEPROCESS_New.ForceMerge
SET Complete = 1, CompletedDate = GETDATE(), CompletionNotes = 'Force Expired without Merging'
FROM MERGEPROCESS_New.ForceMerge 
WHERE Complete = 0 AND CreatedDate < GETDATE() - 14
;





GO
