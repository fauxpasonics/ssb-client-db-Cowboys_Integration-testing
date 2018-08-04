CREATE TABLE [dbo].[Contact_CRMResults]
(
[FirstName] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LastName] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Prefix] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Suffix] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LoadType] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[new_ssbcrmsystemacctid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[new_ssbcrmsystemcontactid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address1_line1] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address1_city] [nvarchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address1_stateorprovince] [nvarchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address1_postalcode] [nvarchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address1_country] [nvarchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[telephone1] [nvarchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CrmRecordId] [uniqueidentifier] NULL,
[IsNew] [bit] NULL,
[ErrorCode] [int] NULL,
[ErrorColumn] [int] NULL,
[CrmErrorMessage] [nvarchar] (2048) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[contactid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ResultDateTime] [datetime] NULL CONSTRAINT [DF__Contact_C__Resul__55F4C372] DEFAULT (getdate())
)
GO
