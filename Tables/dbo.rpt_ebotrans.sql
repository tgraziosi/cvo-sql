CREATE TABLE [dbo].[rpt_ebotrans]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amount] [float] NOT NULL,
[trx_type] [smallint] NOT NULL,
[posted_flag] [smallint] NOT NULL,
[flag] [smallint] NOT NULL,
[groupby] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_ebotrans] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_ebotrans] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_ebotrans] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_ebotrans] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_ebotrans] TO [public]
GO
