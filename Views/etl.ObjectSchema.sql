SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [etl].[ObjectSchema]
AS

SELECT *
FROM
	(
	SELECT
		 CONVERT(NVARCHAR(400),SCHEMA_NAME(t.[schema_id])) SchemaName
		,CONVERT(NVARCHAR(400),t.Name) TableName
		,CONVERT(NVARCHAR(400),'[' + SCHEMA_NAME(t.[schema_id]) + '].[' + t.Name + ']') FullTableName
		,CONVERT(INT,c.column_id) ColumnOrder
		,CONVERT(NVARCHAR(400),
		CASE
			WHEN c.Name LIKE '%[_]K' THEN LEFT(c.Name,LEN(c.Name) - 2)
			WHEN c.Name LIKE '%[_]BK' THEN LEFT(c.Name,LEN(c.Name) - 3)
		 ELSE c.Name END) ColumnName
		,CONVERT(NVARCHAR(400),st.Name) Name
		,CONVERT(INT,c.Max_Length) [Length]
		,CONVERT(INT,c.[Precision]) [Precision]
		,CONVERT(INT,c.Scale) Scale
		,CONVERT(BIT,c.Is_Identity) Is_Identity
		,CONVERT(BIT,c.Is_Nullable) Is_Nullable
		,CONVERT(BIT,CASE WHEN c.Name LIKE '%[_]K' THEN 1 ELSE CASE WHEN pk.ColumnName IS NULL THEN 0 ELSE 1 END END) IsPK
		,CONVERT(BIT,pko.IsDescPK) IsDescPK
		,col.DataType
		,col.Nullable
	FROM
		(
		SELECT
			[Object_ID]
			,Name
			,[schema_id]
			,'Table' TableType
		FROM sys.tables
		UNION ALL
		SELECT
			[Object_ID]
			,Name
			,[schema_id]
			,'View' TableType
		FROM sys.views
		) t
		JOIN sys.schemas s ON t.[schema_id] = s.[schema_id]
		JOIN sys.columns c ON t.[Object_ID] = c.[Object_ID]
		JOIN
		(
		SELECT
			TABLE_SCHEMA TableSchema
			,TABLE_NAME TableName
			,ORDINAL_POSITION OrdinalPosition
			,column_name ColumnName
			,REPLACE(REPLACE(REPLACE(c.DATA_TYPE + ISNULL('(' + CAST(c.CHARACTER_MAXIMUM_LENGTH AS VARCHAR(30)) + ')','') + CASE WHEN c.DATA_TYPE IN ('NUMERIC','DECIMAL') THEN ISNULL('(' + CAST(c.NUMERIC_PRECISION AS VARCHAR(30)) + ',' + CAST(c.NUMERIC_SCALE AS VARCHAR(30)) + ')','') ELSE '' END + ' ','text(2147483647)','varchar(max)'),'(-1)','(max)'),'XML(MAX)','XML') DataType
			,ISNULL(CASE WHEN c.IS_NULLABLE = 'NO' THEN 'NOT ' ELSE NULL END,'') + 'NULL' Nullable
		FROM INFORMATION_SCHEMA.COLUMNS c
		) col ON s.Name = col.TableSchema AND t.Name = col.TableName AND c.Name = col.ColumnName
		JOIN (SELECT * FROM systypes WHERE xtype <> 243) st ON st.xUserType = c.user_type_id
		LEFT JOIN
			(
			SELECT Tab.CONSTRAINT_SCHEMA SchemaName,Tab.TABLE_NAME TableName,Col.Column_Name ColumnName, Col.CONSTRAINT_NAME ConstraintName
			FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS Tab
				JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE Col
				ON Col.Constraint_Name = Tab.Constraint_Name AND Col.Table_Name = Tab.Table_Name AND Constraint_Type = 'PRIMARY KEY'
			) pk
		ON s.name = pk.SchemaName AND t.Name = pk.TableName AND c.Name = pk.ColumnName
		LEFT JOIN
			(
			SELECT i.name ConstraintName,ic.column_id,ic.is_descending_key IsDescPK
			FROM sys.indexes i
				JOIN sys.index_columns ic ON i.object_id = ic.object_id
			) pko
		ON pk.ConstraintName = pko.ConstraintName AND pko.column_id = c.column_id
	
	UNION ALL

	SELECT
		CONVERT(NVARCHAR(400),s.name) SchemaName
		,CONVERT(NVARCHAR(400),p.name) TableName
		,CONVERT(NVARCHAR(400),'[' + s.name + '].[' + p.name + ']') FullTableName
		,CONVERT(INT,r.column_ordinal) ColumnOrder
		,CONVERT(NVARCHAR(400),CASE
			WHEN r.name LIKE '%[_]K' THEN LEFT(r.name,LEN(r.name) - 2)
			WHEN r.name LIKE '%[_]BK' THEN LEFT(r.name,LEN(r.name) - 3)
		 ELSE r.name END) ColumnName
		,CONVERT(NVARCHAR(400),LEFT(r.system_type_name,CHARINDEX('(',r.system_type_name + '(')-1)) Name
		,CONVERT(INT,r.max_length) [Length]
		,CONVERT(INT,r.[precision]) [Precision]
		,CONVERT(INT,r.scale) Scale
		,CONVERT(BIT,is_identity_column) Is_Identity
		,CONVERT(BIT,r.is_nullable) Is_Nullable
		,CONVERT(BIT,CASE WHEN r.Name LIKE '%[_]K' THEN 1 ELSE 0 END) IsPK
		,CONVERT(BIT,NULL) IsDescPK
		,NULL DataType
		,'NULL' Nullable
	FROM sys.procedures p
		JOIN sys.schemas s ON p.[schema_id] = s.[schema_id]
		CROSS APPLY sys.dm_exec_describe_first_result_set_for_object(p.object_id, 1) r
	WHERE is_hidden = 0
		--AND p.name = 'DATA_ReturnsFundDetails'
	) a
WHERE TableName NOT LIKE 'zz%' AND ColumnName NOT LIKE 'ETL[_]%'
GO
