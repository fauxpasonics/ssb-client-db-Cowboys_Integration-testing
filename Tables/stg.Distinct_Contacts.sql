CREATE TABLE [stg].[Distinct_Contacts]
(
[SSB_CRMSYSTEM_ACCT_ID] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SSB_CRMSYSTEM_CONTACT_ID] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[MaxTransDate] [datetime] NULL,
[STH] [int] NULL,
[CRM] [int] NULL
)
GO
ALTER TABLE [stg].[Distinct_Contacts] ADD CONSTRAINT [PK_Distinct_Contacts] PRIMARY KEY CLUSTERED  ([SSB_CRMSYSTEM_CONTACT_ID])
GO
