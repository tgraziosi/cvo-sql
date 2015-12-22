CREATE TABLE [dbo].[cvo_cust_designation_codes_audit]
(
[Item] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[code] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Audit_Date] [smalldatetime] NULL,
[User_ID] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ColumnChange] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ColumnDataFrom] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ColumnDataTo] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ID] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [id_idx] ON [dbo].[cvo_cust_designation_codes_audit] ([ID]) ON [PRIMARY]
GO
