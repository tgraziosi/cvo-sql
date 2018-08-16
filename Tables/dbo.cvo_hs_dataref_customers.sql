CREATE TABLE [dbo].[cvo_hs_dataref_customers]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[account_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hs_id] [bigint] NULL,
[ship_id] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hs_addr_id] [bigint] NULL,
[hs_customer_group_id] [bigint] NULL,
[loaded_date] [datetime] NULL CONSTRAINT [DF__cvo_hs_da__loade__00FCE89E] DEFAULT (getdate()),
[last_updated] [datetime] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_hs_dataref_customers] ADD CONSTRAINT [PK__cvo_hs_dataref_c__0008C465] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
