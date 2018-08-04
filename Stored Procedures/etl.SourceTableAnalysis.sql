SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [etl].[SourceTableAnalysis]
(@SourceTable NVARCHAR(100))
AS

-------------- CLEAR OUT META AND META CONFIG TABLES --------------
DECLARE @Table NVARCHAR(100) = @SourceTable
DECLARE @MetaID INT = (SELECT TOP 1 JSON_Meta_Table_ID FROM etl.JSON_Meta_Table WHERE [Name] = @Table)
DECLARE @ID INT = (SELECT TOP 1 JSON_Meta_Table_Configuration_ID FROM etl.JSON_Meta_Table_Configuration WHERE JSON_Meta_Table_ID = @MetaID)

DECLARE @SQL NVARCHAR(MAX) = ''
DECLARE @SQLD NVARCHAR(MAX) = ''

SET @SQL = '
SELECT * FROM etl.JSON_Meta_TableColumn WHERE JSON_Meta_Table_ID = ' + CONVERT(NVARCHAR(10),@MetaID) + '
SELECT * FROM etl.JSON_Meta_Table_Configuration WHERE JSON_Meta_Table_ID = ' + CONVERT(NVARCHAR(10),@MetaID) + '
SELECT * FROM etl.JSON_Meta_TableColumn_Configuration WHERE JSON_Meta_Table_Configuration_ID = ' + CONVERT(NVARCHAR(10),@ID) + '
'

SET @SQLD = '
DELETE FROM etl.JSON_Meta_TableColumn WHERE JSON_Meta_Table_ID = ' + CONVERT(NVARCHAR(10),@MetaID) + '
DELETE FROM etl.JSON_Meta_Table_Configuration WHERE JSON_Meta_Table_ID = ' + CONVERT(NVARCHAR(10),@MetaID) + '
DELETE FROM etl.JSON_Meta_TableColumn_Configuration WHERE JSON_Meta_Table_Configuration_ID = ' + CONVERT(NVARCHAR(10),@ID) + '
'

SELECT @SQL += 'SELECT * FROM [' + TABLE_SCHEMA + '].[' + TABLE_NAME + ']
'
,@SQLD += 'DROP TABLE [' + TABLE_SCHEMA + '].[' + TABLE_NAME + ']
'
FROM INFORMATION_SCHEMA.TABLES
WHERE
	TABLE_TYPE = 'BASE TABLE'
	AND TABLE_SCHEMA <> 'stg'
	AND TABLE_NAME IN (SELECT TargetTableName FROM etl.JSON_Meta_Table_Configuration WHERE JSON_Meta_Table_ID = @MetaID)

PRINT CAST(@SQL + '

!!!! DELETE SCRIPTS !!!!' + @SQLD AS NTEXT)

GO
