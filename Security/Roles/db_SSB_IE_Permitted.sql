CREATE ROLE [db_SSB_IE_Permitted]
AUTHORIZATION [dbo]
GO
EXEC sp_addrolemember N'db_SSB_IE_Permitted', N'SSBINFO\SSB IE Sec'
GO
