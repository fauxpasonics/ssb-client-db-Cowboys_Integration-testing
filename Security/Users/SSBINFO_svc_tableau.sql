IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'SSBINFO\svc_tableau')
CREATE LOGIN [SSBINFO\svc_tableau] FROM WINDOWS
GO
CREATE USER [SSBINFO\svc_tableau] FOR LOGIN [SSBINFO\svc_tableau]
GO
