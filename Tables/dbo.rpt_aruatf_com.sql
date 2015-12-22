CREATE TABLE [dbo].[rpt_aruatf_com]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[salesperson_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[salesperson_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_commission] [float] NOT NULL,
[percent_flag] [smallint] NOT NULL,
[exclusive_flag] [smallint] NOT NULL,
[split_flag] [smallint] NOT NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_aruatf_com] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_aruatf_com] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_aruatf_com] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_aruatf_com] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_aruatf_com] TO [public]
GO
