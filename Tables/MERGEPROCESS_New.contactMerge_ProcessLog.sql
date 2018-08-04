CREATE TABLE [MERGEPROCESS_New].[contactMerge_ProcessLog]
(
[donotbulkemail] [bit] NULL,
[donotemail] [bit] NULL,
[donotbulkpostalmail] [bit] NULL,
[donotfax] [bit] NULL,
[donotphone] [bit] NULL,
[donotpostalmail] [bit] NULL,
[donotsendmm] [bit] NULL,
[targetid] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[subordinateid] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CoalesceNonEmptyValues] [int] NULL,
[ErrorCode] [int] NULL,
[ErrorColumn] [int] NULL,
[CrmErrorMessage] [nvarchar] (2048) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ProcessDate] [datetime] NULL
)
GO
