CREATE TABLE [dbo].[cvo_crm_leads_main]
(
[lead_id] [int] NOT NULL IDENTITY(1, 1),
[run_id] [int] NULL,
[addr_key] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[account_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[territory] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lead_date] [datetime] NULL CONSTRAINT [DF__cvo_crm_l__lead___2B8753F0] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_crm_leads_main] ADD CONSTRAINT [PK__cvo_crm_leads_ma__2A932FB7] PRIMARY KEY CLUSTERED  ([lead_id]) ON [PRIMARY]
GO
