CREATE TABLE [stg].[tbl_CRMProcess_ConcatIDs]
(
[GUID] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ConcatIDs1] [varchar] (8000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ConcatIDs2] [varchar] (8000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ConcatIDs3] [varchar] (8000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ConcatIDs4] [varchar] (8000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ConcatIDs5] [varchar] (8000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[DimCust_ConcatIDs] [varchar] (8000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[LastProcess_DateTime] [datetime] NULL CONSTRAINT [DF__tbl_CRMPr__LastP__571DF1D5] DEFAULT (getdate())
)
GO
ALTER TABLE [stg].[tbl_CRMProcess_ConcatIDs] ADD CONSTRAINT [PK__tbl_CRMP__43A3E834242E17B6] PRIMARY KEY CLUSTERED  ([GUID])
GO
