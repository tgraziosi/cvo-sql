CREATE TABLE [dbo].[cvo_inv_upd_util]
(
[user_spid] [int] NULL,
[sku] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[obsolete_str] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[obsolete] [smallint] NULL,
[web_sellable] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pom_date_str] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pom_date] [datetime] NULL,
[release_date_str] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[release_date] [datetime] NULL,
[watch] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[backorder_date_str] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[backorder_date] [datetime] NULL,
[process_flag] [int] NULL CONSTRAINT [DF__cvo_inv_u__proce__4EDE78B7] DEFAULT ((0)),
[error_flag] [int] NULL CONSTRAINT [DF__cvo_inv_u__error__4FD29CF0] DEFAULT ((0)),
[line_message] [varchar] (2500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_inv_u__line___50C6C129] DEFAULT ('')
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_inv_upd_util] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_inv_upd_util] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_inv_upd_util] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_inv_upd_util] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_inv_upd_util] TO [public]
GO
