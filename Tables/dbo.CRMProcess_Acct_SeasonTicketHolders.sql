CREATE TABLE [dbo].[CRMProcess_Acct_SeasonTicketHolders]
(
[SSB_CRMSYSTEM_ACCT_ID] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SeasonTicket_Years] [varchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SSIDs_List] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Distinct_Teams] [int] NULL,
[Distinct_SSIDs] [int] NULL,
[LoadDateTime] [datetime] NULL
)
GO
