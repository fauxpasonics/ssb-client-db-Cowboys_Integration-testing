CREATE TABLE [dbo].[CRMLoad_SaveResults_Archived]
(
[UID] [int] NOT NULL IDENTITY(1, 1),
[ArchiveDate] [datetime] NULL,
[ResultCategory] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[XML_Results] [xml] NULL
)
GO
ALTER TABLE [dbo].[CRMLoad_SaveResults_Archived] ADD CONSTRAINT [PK__CRMLoad___C5B19602D4saE77378] PRIMARY KEY CLUSTERED  ([UID])
GO
