IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'SSBINFO\tfrancis')
CREATE LOGIN [SSBINFO\tfrancis] FROM WINDOWS
GO
CREATE USER [SSBINFO\tfrancis] FOR LOGIN [SSBINFO\tfrancis]
GO
