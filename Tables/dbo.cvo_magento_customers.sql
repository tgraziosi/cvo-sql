CREATE TABLE [dbo].[cvo_magento_customers]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[magento_id] [int] NULL,
[fname] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lname] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[email] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pass_hash] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[account_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[registration_date] [datetime] NULL,
[synced_date] [datetime] NULL,
[activated_date] [datetime] NULL,
[isActive] [tinyint] NULL CONSTRAINT [DF__cvo_magen__isAct__38B896C0] DEFAULT ((0)),
[notes] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[phone_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_magento_customers] ADD CONSTRAINT [PK__cvo_magento_cust__37C47287] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_magento_cust_active] ON [dbo].[cvo_magento_customers] ([magento_id], [isActive]) ON [PRIMARY]
GO
