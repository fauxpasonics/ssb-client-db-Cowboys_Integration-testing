SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
DECLARE
@Source NVARCHAR(400) = '[test].[MarketValue_Land2]'
,@Target NVARCHAR(400) = '[calc].[MarketValue_Land2]'
SELECT * FROM [etl].[SchemaCompare](@Source,@Target)
*/

CREATE FUNCTION [etl].[SchemaCompare]
(
@Source NVARCHAR(400)
,@Target NVARCHAR(400)
)

RETURNS @Results TABLE
(
[ColumnOrder] INT,
[ColumnName] NVARCHAR(500),
[IsPK] BIT,
[IsMatch] BIT
)

AS
BEGIN

INSERT @Results

SELECT
	s.ColumnOrder
	,s.ColumnName
	,t.IsPK
	,CASE
		WHEN 
			ISNULL(s.ColumnName,'') <> ISNULL(t.ColumnName,'')
			OR ISNULL(s.name,'') <> ISNULL(t.name,'')
			OR ISNULL(s.[Length],'') <> ISNULL(t.[Length],'')
			OR ISNULL(s.[Precision],'') <> ISNULL(t.[Precision],'')
			OR ISNULL(s.Scale,'') <> ISNULL(t.Scale,'')
			--OR ISNULL(s.Is_Identity,'') <> ISNULL(t.Is_Identity,'')
			--OR ISNULL(s.Is_Nullable,'') <> ISNULL(t.Is_Nullable,'')
			OR ISNULL(s.IsPK,'') <> ISNULL(t.IsPK,'')
		THEN 0 ELSE 1
	END IsMatch
FROM
	(
	SELECT *
	FROM [etl].[ObjectSchema] t
	WHERE FullTableName = @Source
	) s
	FULL OUTER JOIN
	(
	SELECT *
	FROM [etl].[ObjectSchema] t
	WHERE FullTableName = @Target
	) t
	ON REPLACE(REPLACE(REPLACE(REPLACE(s.TableName,'dirty_',''),'_Type1',''),'_Type2',''),'_Sync','') = t.TableName AND s.ColumnName = t.ColumnName
WHERE ---- Exceptions
	NOT (ISNULL(t.ColumnName,'') LIKE '%Key' AND t.ColumnOrder = 1)
	AND ISNULL(t.ColumnName,'') NOT IN ('EFF_BEG_DATE','EFF_END_DATE','ETL_CREATED_DATE','ETL_LUPDATED_DATE')
	AND NOT (ISNULL(t.SchemaName,'') = 'mdm' AND ISNULL(t.ColumnName,'') IN ('ID','CleanID','PriorityOrder','IsManualMDM','PriorityOrder'))

	--AND NOT (ISNULL(t.SchemaName,'') = 'postmdm' AND ISNULL(s.ColumnName,'') IN ('ID','CleanID','PriorityOrder','IsManualMDM','PriorityOrder','SourceSystemID'))
	AND NOT (ISNULL(s.SchemaName,'') = 'mdm' AND ISNULL(s.ColumnName,'') IN ('ID','CleanID','PriorityOrder','IsManualMDM','PriorityOrder','SourceSystemID'))

RETURN


END
GO
