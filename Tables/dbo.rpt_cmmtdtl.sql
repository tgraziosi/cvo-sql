CREATE TABLE [dbo].[rpt_cmmtdtl]
(
[seq_by] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_ctrl_num] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_count] [int] NOT NULL,
[home_amount] [float] NOT NULL,
[hold_count] [int] NOT NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cur_precision] [smallint] NOT NULL,
[hold_amount] [float] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_cmmtdtl] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_cmmtdtl] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_cmmtdtl] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_cmmtdtl] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_cmmtdtl] TO [public]
GO
