SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 

create VIEW [MERGEPROCESS_New].[vw_Cust_Account_ColumnLogic]
AS
SELECT  ID AS targetid ,
        Losing_ID AS subordinateid ,            
        1 AS CoalesceNonEmptyValues, --New Kingsway feature to bring values from loser where winning record is null
        --1 as PerformParentingChecks  -- New Kingsway feature where parents must be the same in order to merge. NOT NEEDED by Default. Just a placeholder                  
        CAST(SUBSTRING(donotbulkemail, 2, 1) AS BIT) donotbulkemail ,
        CAST(SUBSTRING(donotemail, 2, 1) AS BIT) donotemail ,
        CAST(SUBSTRING(aa.donotbulkpostalmail, 2, 1) AS BIT) donotbulkpostalmail,
        CAST(SUBSTRING(aa.donotfax, 2, 1) AS BIT) donotfax,
        CAST(SUBSTRING(donotphone, 2, 1) AS BIT) donotphone ,
        CAST(SUBSTRING(donotpostalmail, 2, 1) AS BIT) donotpostalmail ,
        CAST(SUBSTRING(donotsendmm, 2, 1) AS BIT) donotsendmm
FROM    ( SELECT    Winning_ID AS ID ,
                    Losing_ID AS Losing_ID ,                    
                    MAX(CASE WHEN dta.xtype = 'Winner'
                                  AND ISNULL(donotbulkemail,0) <> 0
                             THEN '2' + CAST(donotbulkemail AS VARCHAR(10))
                             WHEN dta.xtype = 'Loser'
                                  AND ISNULL(donotbulkemail,0) <> 0
                             THEN '1' + CAST(donotbulkemail AS VARCHAR(10))
                        END) donotbulkemail ,
                    MAX(CASE WHEN dta.xtype = 'Winner'
                                  AND ISNULL(donotemail,0) <> 0
                             THEN '2' + CAST(donotemail AS VARCHAR(10))
                             WHEN dta.xtype = 'Loser'
                                  AND ISNULL(donotemail,0) <> 0
                             THEN '1' + CAST(donotemail AS VARCHAR(10))
                        END) donotemail ,
                    MAX(CASE WHEN dta.xtype = 'Winner'
                                  AND ISNULL(donotbulkpostalmail,0) <> 0
                             THEN '2' + CAST(donotbulkpostalmail AS VARCHAR(10))
                             WHEN dta.xtype = 'Loser'
                                  AND ISNULL(donotbulkpostalmail,0) <> 0
                             THEN '1' + CAST(donotbulkpostalmail AS VARCHAR(10))
                        END) donotbulkpostalmail ,
                    MAX(CASE WHEN dta.xtype = 'Winner'
                                  AND ISNULL(donotfax,0)  <> 0
                             THEN '2' + CAST(donotfax AS VARCHAR(10))
                             WHEN dta.xtype = 'Loser'
                                  AND ISNULL(donotfax,0) <> 0
                             THEN '1' + CAST(donotfax AS VARCHAR(10))
                        END) donotfax ,
                    MAX(CASE WHEN dta.xtype = 'Winner'
                                  AND ISNULL(donotphone,0) <> 0
                             THEN '2' + CAST(donotphone AS VARCHAR(10))
                             WHEN dta.xtype = 'Loser'
                                  AND ISNULL(donotphone,0) <> 0
                             THEN '1' + CAST(donotphone AS VARCHAR(10))
                        END) donotphone ,
                    MAX(CASE WHEN dta.xtype = 'Winner'
                                  AND ISNULL(donotpostalmail,0)  <> 0
                             THEN '2' + CAST(dta.donotpostalmail AS VARCHAR(10))
                             WHEN dta.xtype = 'Loser'
                                  AND ISNULL(dta.donotpostalmail,0) <> 0
                             THEN '1' + CAST(dta.donotpostalmail AS VARCHAR(10))
                        END) donotpostalmail ,
                    MAX(CASE WHEN dta.xtype = 'Winner'
                                  AND ISNULL(dta.donotsendmm,0) <> 0
                             THEN '2' + CAST(dta.donotsendmm AS VARCHAR(10))
                             WHEN dta.xtype = 'Loser'
                                  AND ISNULL(dta.donotsendmm,0) <> 0
                             THEN '1' + CAST(dta.donotsendmm AS VARCHAR(10))
                        END) donotsendmm
 
          FROM      ( SELECT    *
                      FROM      ( SELECT    'Winner' xtype ,
                                            a.Winning_ID ,
                                            a.Losing_ID ,                   
                                            b.*
                                  FROM      [MERGEPROCESS_New].[Queue] a
                                            JOIN mergeprocess_new.tmp_pcaccount b ON a.Winning_ID = b.accountid
                                            --where fk_mergeid < 1000
                                  UNION ALL
                                  SELECT    'Loser' xtype ,
                                            a.Winning_ID ,
                                            a.Losing_ID ,                   
                                            b.*
                                  FROM      [MERGEPROCESS_New].[Queue] a
                                            JOIN mergeprocess_new.tmp_pcaccount b ON a.Losing_ID = b.accountid
                                             
                                ) x
                    ) dta
          GROUP BY  Winning_ID ,
                    Losing_ID                               
        ) aa
 
 
;
 
 
 
 
GO
