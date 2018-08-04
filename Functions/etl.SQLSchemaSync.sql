SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
DECLARE
@SourceSchema NVARCHAR(400) = 'src'
,@TargetSchema NVARCHAR(400) = 'ods'
,@TableName NVARCHAR(400) = 'Question'
,@TransformationType NVARCHAR(100) = 'type4'

DECLARE @SQL NVARCHAR(MAX) = (SELECT [etl].[SQLSchemaSync](@SourceSchema,@TargetSchema,@TableName,@TransformationType))
PRINT CAST(@SQL AS NTEXT)
-- EXEC (@SQL)
*/

CREATE FUNCTION [etl].[SQLSchemaSync]
(@SourceSchema NVARCHAR(400)
,@TargetSchema NVARCHAR(400)
,@TableName NVARCHAR(400)
,@TransformationType NVARCHAR(400))

RETURNS NVARCHAR(MAX)

AS
BEGIN

DECLARE @SQL NVARCHAR(MAX) = ''
DECLARE @Source NVARCHAR(MAX) = '[' + @SourceSchema + '].[' + @TableName + ']'
DECLARE @Target NVARCHAR(MAX) = REPLACE(REPLACE(REPLACE(REPLACE('[' + @TargetSchema + '].[' + @TableName + ']','[mdm].[dirty_','[mdm].['),'_Type1',''),'_Type2',''),'_Sync','')
DECLARE @TargetSchemaExists BIT = (SELECT CASE WHEN (SELECT COUNT(*) FROM sys.schemas WHERE name = @TargetSchema) > 0 THEN 1 ELSE 0 END)
DECLARE @TargetTableExists BIT = (SELECT CASE WHEN @Target IN (SELECT '[' + s.name + '].[' + t.name + ']' TableName FROM sys.tables t JOIN sys.schemas s ON t.[schema_id] = s.[schema_id]) THEN 1 ELSE 0 END)
DECLARE @TargetTableColumnsMatch BIT = (SELECT ISNULL(MIN(CONVERT(INT,IsMatch)),0) IsMatch FROM [etl].[SchemaCompare](@Source,@Target))

DECLARE @TaskTypeInTableName NVARCHAR(100) = CASE WHEN @Source LIKE '%_Type1' + CHAR(93) THEN 'Type1' WHEN @Source LIKE '%_Type2' + CHAR(93) THEN 'Type2' WHEN @Source LIKE '%_Sync' + CHAR(93) THEN 'FactSync' ELSE NULL END
DECLARE @TaskType NVARCHAR(100) = (SELECT ISNULL(@TaskTypeInTableName,(SELECT TaskType FROM etl.Task WHERE Active = 1 AND [Source] = @Source)))
--DECLARE @TrackCreatedUpdated BIT = CASE WHEN REPLACE(REPLACE(@Target,'[',''),']','') LIKE 'dw.Fact%' OR @TaskType IN ('Type1','Type2','Type4') THEN 1 ELSE 0 END

DECLARE @Tracking NVARCHAR(MAX) = '
/*
Source = '						+ ISNULL(CONVERT(NVARCHAR(100),@Source),'NULL') + '
Target = '						+ ISNULL(CONVERT(NVARCHAR(100),@Target),'NULL') + '
TransformationType = '			+ ISNULL(CONVERT(NVARCHAR(100),@TransformationType),'NULL') + '
TargetSchemaExists = '			+ ISNULL(CONVERT(NVARCHAR(100),@TargetSchemaExists),'NULL') + '
TargetTableExists = '			+ ISNULL(CONVERT(NVARCHAR(100),@TargetTableExists),'NULL') + '
TargetTableColumnsMatch = '		+ ISNULL(CONVERT(NVARCHAR(100),@TargetTableColumnsMatch),'NULL') + '
TaskTypeInTableName = '			+ ISNULL(CONVERT(NVARCHAR(100),@TaskTypeInTableName),'NULL') + '
TaskType = '					+ ISNULL(CONVERT(NVARCHAR(100),@TaskType),'NULL') + '
*/

'

IF @TargetSchemaExists = 0
BEGIN
	SET @SQL = 'TO DO' -- CREATE SCHEMA Scalar Function
END

IF @TargetTableColumnsMatch = 0
BEGIN

	IF @TransformationType = 'Type4' SELECT @SQL =
		[etl].[SQLSchemaSync_Type4] (@SourceSchema,@TargetSchema,@TableName,@TargetTableExists,@TargetTableColumnsMatch)

	IF @TransformationType IN ('Insert','Update','Upsert','Sync') SELECT @SQL =
		[etl].[SQLSchemaSync_Standard] (@SourceSchema,@TargetSchema,@TableName,@TargetTableExists,@TargetTableColumnsMatch)

END

RETURN-- @Tracking +
 @SQL

END
GO
