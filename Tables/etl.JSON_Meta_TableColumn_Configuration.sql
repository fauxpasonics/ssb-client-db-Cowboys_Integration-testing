CREATE TABLE [etl].[JSON_Meta_TableColumn_Configuration]
(
[JSON_Meta_TableColumn_Configuration_ID] [int] NOT NULL IDENTITY(1, 1),
[JSON_Meta_Table_Configuration_ID] [int] NOT NULL,
[JSON_Meta_TableColumn_ID] [int] NULL,
[JSON_Meta_TableColumn_ID_MultiClause] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ColumnName] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Order] [int] NULL,
[DataType] [varchar] (14) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Unpivot] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Active] [bit] NOT NULL CONSTRAINT [DF__JSON_Meta__Activ__6B24EA82] DEFAULT ((1)),
[CreatedOn] [datetime] NOT NULL CONSTRAINT [DF__JSON_Meta__Creat__6C190EBB] DEFAULT ([etl].[ConvertToLocalTime](CONVERT([datetime2](0),getdate(),(0)))),
[CreatedBy] [nvarchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__JSON_Meta__Creat__6D0D32F4] DEFAULT (suser_sname()),
[LastUpdatedOn] [datetime] NOT NULL CONSTRAINT [DF__JSON_Meta__LastU__6E01572D] DEFAULT ([etl].[ConvertToLocalTime](CONVERT([datetime2](0),getdate(),(0)))),
[LastUpdatedBy] [nvarchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__JSON_Meta__LastU__6EF57B66] DEFAULT (suser_sname())
)
GO
ALTER TABLE [etl].[JSON_Meta_TableColumn_Configuration] ADD CONSTRAINT [PK__JSON_Met__FD4C32CA32AA44B6] PRIMARY KEY CLUSTERED  ([JSON_Meta_TableColumn_Configuration_ID])
GO
ALTER TABLE [etl].[JSON_Meta_TableColumn_Configuration] ADD CONSTRAINT [UQ__JSON_Met__E072269D072E6BB1] UNIQUE NONCLUSTERED  ([JSON_Meta_Table_Configuration_ID], [ColumnName])
GO
ALTER TABLE [etl].[JSON_Meta_TableColumn_Configuration] ADD CONSTRAINT [UQ__JSON_Met__F6EF95DA4A5D16E8] UNIQUE NONCLUSTERED  ([JSON_Meta_Table_Configuration_ID], [JSON_Meta_TableColumn_ID])
GO
ALTER TABLE [etl].[JSON_Meta_TableColumn_Configuration] ADD CONSTRAINT [UQ__JSON_Met__0CEADB8356E07910] UNIQUE NONCLUSTERED  ([JSON_Meta_Table_Configuration_ID], [Order])
GO
GRANT DELETE ON  [etl].[JSON_Meta_TableColumn_Configuration] TO [db_SSB_IE_Permitted]
GO
GRANT INSERT ON  [etl].[JSON_Meta_TableColumn_Configuration] TO [db_SSB_IE_Permitted]
GO
GRANT UPDATE ON  [etl].[JSON_Meta_TableColumn_Configuration] TO [db_SSB_IE_Permitted]
GO
