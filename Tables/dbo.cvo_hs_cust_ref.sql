CREATE TABLE [dbo].[cvo_hs_cust_ref]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[account_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hs_id] [bigint] NULL,
[loaded_date] [datetime] NULL CONSTRAINT [DF__cvo_hs_cu__loade__388227B2] DEFAULT (getdate()),
[customer_group] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[last_updated] [datetime] NULL,
[ship_id] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hs_addr_id] [bigint] NULL,
[hs_customer_group_id] [bigint] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_hs_cust_ref] ADD CONSTRAINT [PK__cvo_hs_cust_ref__378E0379] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
