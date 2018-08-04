CREATE TABLE [stg].[CRMProcess_RecentTrans_SSIDs]
(
[dimcustomerid] [int] NULL,
[SSID] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Team] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[MaxTransDate] [datetime] NULL,
[LoadDateTime] [datetime] NULL
)
GO
