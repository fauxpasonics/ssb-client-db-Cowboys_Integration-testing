CREATE TABLE [wrk].[customerWorkingList]
(
[DimCustomerID] [int] NOT NULL,
[SSB_CRMSYSTEM_ACCT_ID] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SSID_Winner] [nvarchar] (110) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SourceSystem] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IsPersonAccount] [int] NOT NULL,
[IsBusinessAccount] [int] NOT NULL,
[MDM_UpdatedDate] [datetime] NOT NULL,
[CRMProcess_UpdatedDate] [datetime] NOT NULL
)
GO
ALTER TABLE [wrk].[customerWorkingList] ADD CONSTRAINT [PK_customerWorkingList] PRIMARY KEY CLUSTERED  ([SSB_CRMSYSTEM_ACCT_ID])
GO
