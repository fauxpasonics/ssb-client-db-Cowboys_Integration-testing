CREATE TABLE [etl].[CRMProcess_SeasonTicketHolders]
(
[SSID] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SeasonYear] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SeasonYr] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Team] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
)
GO
ALTER TABLE [etl].[CRMProcess_SeasonTicketHolders] ADD CONSTRAINT [PK_CRMProcess_SeasonTicketHolders] PRIMARY KEY CLUSTERED  ([SSID], [SeasonYear])
GO
