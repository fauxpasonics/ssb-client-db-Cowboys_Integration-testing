CREATE TABLE [dbo].[CRMProcess_Contact_SeasonTicketHolders]
(
[SSB_CRMSYSTEM_CONTACT_ID] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SeasonTicket_Years] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SSIDs_List] [varchar] (8000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Distinct_Teams] [int] NULL,
[Distinct_SSIDs] [int] NULL,
[LoadDateTime] [datetime] NULL,
[Distinct_ContactID] [int] NULL
)
GO
