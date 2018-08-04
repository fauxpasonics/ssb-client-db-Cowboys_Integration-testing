CREATE ROLE [db_svcLogi]
AUTHORIZATION [dbo]
GO
EXEC sp_addrolemember N'db_svcLogi', N'SSBINFO\svc_tableau'
GO
EXEC sp_addrolemember N'db_svcLogi', N'svcLogi'
GO
