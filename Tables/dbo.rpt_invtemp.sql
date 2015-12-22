CREATE TABLE [dbo].[rpt_invtemp]
(
[trx_ctrl_num] [char] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_ctrl_num] [char] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[order_ctrl_num] [char] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_gross] [float] NOT NULL,
[src] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_doc] [int] NOT NULL,
[customer_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_invtemp] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_invtemp] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_invtemp] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_invtemp] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_invtemp] TO [public]
GO
