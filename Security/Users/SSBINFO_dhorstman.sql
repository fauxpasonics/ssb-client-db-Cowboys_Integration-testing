IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'SSBINFO\dhorstman')
CREATE LOGIN [SSBINFO\dhorstman] FROM WINDOWS
GO
CREATE USER [SSBINFO\dhorstman] FOR LOGIN [SSBINFO\dhorstman]
GO
