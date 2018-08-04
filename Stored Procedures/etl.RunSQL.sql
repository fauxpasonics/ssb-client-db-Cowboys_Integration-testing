SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [etl].[RunSQL]
(
@SQL NVARCHAR(MAX)
,@BatchID INT
,@TaskName NVARCHAR(MAX)
,@Target NVARCHAR(MAX)
)
AS

DECLARE @ID INT
DECLARE @TransactionName VARCHAR(1000)
DECLARE @IsError BIT = 0

-- Log the task
INSERT INTO [audit].[TaskLog] ([BatchID],[TaskName],[Target],[SQL],[User],[ExecuteStart])
SELECT
	@BatchID
	,@TaskName
	,@Target
	,@SQL
	,SYSTEM_USER
	,(SELECT [etl].[ConvertToLocalTime](GetDate()))

SET @ID = SCOPE_IDENTITY()

SET @SQL = '
------------------------- ' + @TaskName + ' -------------------------
DECLARE @RowCountBefore INT = 0,@RowCountAfter INT = 0,@Inserted INT = 0,@Updated INT = 0,@Deleted INT = 0,@Truncated INT = 0
' + CASE WHEN EXISTS (SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE @Target = '[' + [TABLE_SCHEMA] + '].[' + [TABLE_NAME] + ']') THEN 'SET @RowCountBefore = (SELECT COUNT(*) FROM ' + @Target + ')
' ELSE '' END + @SQL

IF @SQL = '' OR @SQL IS NULL UPDATE [audit].[TaskLog] SET IsError = 1, ErrorMessage = 'Empty SQL Statement: Nothing was executed' WHERE ID = @ID

BEGIN TRY

SET @SQL += '
UPDATE [audit].[TaskLog]
SET IsCommitted = 1
	,RowCountBefore = @RowCountBefore
	,Inserted = ISNULL(@Inserted,0)
	,Updated = ISNULL(@Updated,0)
	,Deleted = ISNULL(@Deleted,0)
	,Truncated = ISNULL(@Truncated,0)
WHERE ID = ' + CONVERT(VARCHAR(10),@ID)

	EXEC(@SQL)

IF OBJECT_ID(@Target,'U') IS NOT NULL
BEGIN
	SET @SQL = 'UPDATE [audit].[TaskLog] SET RowCountAfter = (SELECT COUNT(*) FROM ' + @Target + ') WHERE ID = ' + CONVERT(VARCHAR(10),@ID)
	EXEC(@SQL)
END

	UPDATE [audit].[TaskLog] SET ExecuteEnd = (SELECT [etl].[ConvertToLocalTime](GetDate())) WHERE ID = @ID
	--SELECT CONVERT(BIT,1) IsSuccess
END TRY
BEGIN CATCH
	SET @IsError = 1
	DECLARE @ERROR_MESSAGE NVARCHAR(MAX) = ERROR_MESSAGE()
	DECLARE @ERROR_SEVERITY NVARCHAR(MAX) = ERROR_SEVERITY()
	DECLARE @ERROR_STATE NVARCHAR(MAX) = ERROR_STATE()

	UPDATE [audit].[TaskLog] SET IsError = 1, ErrorMessage = ERROR_MESSAGE(), ErrorSeverity = ERROR_SEVERITY(), ErrorState = ERROR_STATE(), [ExecuteEnd] = (SELECT [etl].[ConvertToLocalTime](GetDate())) WHERE ID = @ID;
	RAISERROR (@ERROR_MESSAGE,@ERROR_SEVERITY,@ERROR_STATE)
	--SELECT CONVERT(BIT,0) IsSuccess
END CATCH


GO
