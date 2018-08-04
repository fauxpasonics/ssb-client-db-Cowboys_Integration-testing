SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [etl].[InfoSchema]
AS

---------------- Tables and Views ----------------
SELECT
	o.TableType
	,'[' + DB_NAME() + '].[' + s.name + '].[' + o.name + ']' FullTableName
	,'[' + DB_NAME() + ']' DatabaseName
	,'[' + o.name + ']' TableName
	,'[' + s.name + ']' SchemaName
	,c.column_id OrdinalPosition
	,'[' + c.name + ']' ColumnName
	,UPPER('[' + t.name + ']' + CASE WHEN t.name IN ('char','varchar','nchar','nvarchar') THEN '(' + CASE WHEN c.max_length = -1 THEN 'MAX' ELSE CONVERT(VARCHAR(4),CASE WHEN t.name IN ('nchar','nvarchar') THEN  c.max_length / 2 ELSE c.max_length END) END +')' WHEN t.name IN ('decimal','numeric') THEN '('+ CONVERT(VARCHAR(4),c.precision) + ',' + CONVERT(VARCHAR(4),c.Scale) + ')' ELSE '' END) DataType
	,ISNULL(i.is_primary_key,0) IsPK
	,i.name PKName
	,CASE WHEN fk.FKName IS NOT NULL THEN 1 ELSE 0 END IsHasFK
	,fk.FKName
	,fk.FKReferencedFullTableName
	,fk.FKReferencedColumnName
	,c.is_identity IsIdentity
	,cd.[text] DefaultColumnValue
FROM
	(
	SELECT [Object_ID],Name,[schema_id],'Table' TableType FROM sys.tables
	UNION ALL
	SELECT [Object_ID],Name,[schema_id],'View' TableType FROM sys.views
	) o
	JOIN sys.schemas s
		ON o.[schema_id] = s.[schema_id]
		--AND s.name IN	(
		--				SELECT DISTINCT SourceSchema SchemaName FROM etl.Batch WHERE Active = 1 AND SourceSchema IS NOT NULL AND TaskType <> 'package' UNION
		--				SELECT DISTINCT TargetSchema SchemaName FROM etl.Batch WHERE Active = 1 AND TargetSchema IS NOT NULL AND TaskType <> 'package'
						------ modules ----
						--SELECT 'mdm' UNION
						--SELECT 'postmdm' UNION
						--SELECT 'predw' UNION
						--SELECT 'dw' UNION
						--SELECT 'app'
		--				)
	JOIN sys.columns c ON o.[Object_ID] = c.[Object_ID]
	JOIN sys.types t ON c.user_type_id = t.user_type_id
	LEFT JOIN sys.index_columns ic ON ic.[object_id] = c.[object_id] AND ic.column_id = c.column_id AND index_id = 1
	LEFT JOIN (SELECT * FROM sys.indexes WHERE is_primary_key = 1) i ON ic.[object_id] = i.[object_id] AND ic.index_id = i.index_id
	LEFT JOIN
	(
	SELECT so.id,sc.name,sm.[text]
	FROM sys.sysobjects so
		JOIN sys.syscolumns sc ON sc.id = so.id
		JOIN sys.syscomments sm ON sm.id = sc.cdefault
	WHERE so.xtype = 'U'
	) cd ON o.[Object_ID] = cd.id AND c.Name = cd.name
	LEFT JOIN
	(
	SELECT
		fkc.parent_object_id TableObjectID
		,c.name ColumnName
		,'[' + fk.name+ ']' FKName
		,'[' + DB_NAME() + '].[' + s.name + '].[' + tr.name + ']' FKReferencedFullTableName
		,'[' + cr.name + ']' FKReferencedColumnName
	FROM
		sys.foreign_key_columns fkc
		JOIN sys.tables tr ON fkc.referenced_object_id = tr.[object_id]
		JOIN sys.schemas s ON tr.[schema_id] = s.[schema_id]
		JOIN sys.columns c ON fkc.parent_object_id = c.[object_id] AND fkc.parent_column_id = c.column_id
		JOIN sys.columns cr ON fkc.referenced_object_id = cr.[object_id] AND fkc.referenced_column_id = cr.column_id
		JOIN sys.foreign_keys fk ON fkc.constraint_object_id = fk.[object_id]
	) fk ON o.[Object_ID] = fk.TableObjectID AND c.name = fk.ColumnName

UNION ALL

---------------- Procedures ----------------
SELECT
	'Procedure' TableType
	,'[' + DB_NAME() + '].[' + s.name + '].[' + p.name + ']' FullTableName
	,'[' + DB_NAME() + ']' DatabaseName
	,'[' + p.name + ']' TableName
	,'[' + s.name + ']' SchemaName
	,r.column_ordinal OrdinalPosition
	,'[' + r.name + ']' ColumnName
	,UPPER(r.system_type_name) DataType
	,NULL IsPK
	,NULL PKName
	,NULL IsHasFK
	,NULL FKName
	,NULL FKReferencedFullTableName
	,NULL FKReferencedColumnName
	,NULL IsIdentity
	,NULL DefaultColumnValue
FROM sys.procedures p
	JOIN sys.schemas s
		ON p.[schema_id] = s.[schema_id]
		AND s.name IN	(
						SELECT DISTINCT SourceSchema SchemaName FROM etl.Batch WHERE Active = 1 AND SourceSchema IS NOT NULL AND TaskType <> 'package' UNION
						SELECT DISTINCT TargetSchema SchemaName FROM etl.Batch WHERE Active = 1 AND TargetSchema IS NOT NULL AND TaskType <> 'package' UNION
						---- modules ----
						SELECT 'mdm' UNION
						SELECT 'postmdm' UNION
						SELECT 'predw' UNION
						SELECT 'dw'
						)
	CROSS APPLY sys.dm_exec_describe_first_result_set_for_object(p.object_id, 0) r
WHERE error_type_desc IS NULL

GO
