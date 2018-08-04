CREATE TABLE [stg].[CRMProcess_SeasonTicketHolders_SSIDs]
(
[Team] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SSID] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SeasonYear] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SeasonYr] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LoadDate] [datetime] NULL CONSTRAINT [DF_CRMProcess_SeasonTicketHolders_SSIDs_LoadDate] DEFAULT (getdate())
)
GO
ALTER TABLE [stg].[CRMProcess_SeasonTicketHolders_SSIDs] ADD CONSTRAINT [PK_CRMProcess_SeasonTicketHolders_SSIDs] PRIMARY KEY CLUSTERED  ([SSID], [SeasonYear])
GO
