CREATE TABLE [dbo].[CRMProcess_SourceSystem_Translation]
(
[UID] [int] NOT NULL IDENTITY(1, 1),
[MDM_SourceSystem] [varchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRM_FriendlyName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
)
GO
ALTER TABLE [dbo].[CRMProcess_SourceSystem_Translation] ADD CONSTRAINT [PK__CRMProce__C5B1960211ED7373] PRIMARY KEY CLUSTERED  ([UID])
GO
