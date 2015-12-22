CREATE TABLE [dbo].[rpt_arpurge]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[trx_type_desc] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_applied] [int] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_arpurge] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_arpurge] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_arpurge] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_arpurge] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_arpurge] TO [public]
GO
