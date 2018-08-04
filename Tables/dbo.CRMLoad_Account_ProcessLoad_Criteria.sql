CREATE TABLE [dbo].[CRMLoad_Account_ProcessLoad_Criteria]
(
[SSB_CRMSYSTEM_ACCT_ID] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[LoadType] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
)
GO
ALTER TABLE [dbo].[CRMLoad_Account_ProcessLoad_Criteria] ADD CONSTRAINT [PK_CRMLoad_Account_ProcessLoad_Criteria] PRIMARY KEY CLUSTERED  ([SSB_CRMSYSTEM_ACCT_ID])
GO
