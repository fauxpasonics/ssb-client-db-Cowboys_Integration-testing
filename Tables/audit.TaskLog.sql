CREATE TABLE [audit].[TaskLog]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[BatchID] [int] NOT NULL,
[Created] [datetime] NULL CONSTRAINT [DF__TaskLog__Created__48CFD27E] DEFAULT ([etl].[ConvertToLocalTime](CONVERT([datetime2](0),getdate(),(0)))),
[User] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TaskName] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Target] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SQL] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ExecuteStart] [datetime] NULL,
[ExecuteEnd] [datetime] NULL,
[ExecutionRuntimeSeconds] AS (CONVERT([float],datediff(second,[ExecuteStart],[ExecuteEnd]),(0))),
[RowCountBefore] [int] NULL CONSTRAINT [DF__TaskLog__RowCoun__49C3F6B7] DEFAULT ((0)),
[RowCountAfter] [int] NULL CONSTRAINT [DF__TaskLog__RowCoun__4AB81AF0] DEFAULT ((0)),
[Inserted] [int] NULL CONSTRAINT [DF__TaskLog__Inserte__4BAC3F29] DEFAULT ((0)),
[Updated] [int] NULL CONSTRAINT [DF__TaskLog__Updated__4CA06362] DEFAULT ((0)),
[Deleted] [int] NULL CONSTRAINT [DF__TaskLog__Deleted__4D94879B] DEFAULT ((0)),
[Truncated] [int] NULL CONSTRAINT [DF__TaskLog__Truncat__4E88ABD4] DEFAULT ((0)),
[IsCommitted] [bit] NULL CONSTRAINT [DF__TaskLog__IsCommi__4F7CD00D] DEFAULT ((0)),
[IsError] [bit] NULL CONSTRAINT [DF__TaskLog__IsError__5070F446] DEFAULT ((0)),
[ErrorMessage] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ErrorSeverity] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ErrorState] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
)
GO
ALTER TABLE [audit].[TaskLog] ADD CONSTRAINT [PK__TaskLog__3214EC2742B4215B] PRIMARY KEY CLUSTERED  ([ID])
GO
