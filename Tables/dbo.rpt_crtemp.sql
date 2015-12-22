CREATE TABLE [dbo].[rpt_crtemp]
(
[trx_ctrl_num] [char] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_ctrl_num] [char] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_desc] [char] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[payment_code] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_payment] [float] NOT NULL,
[src] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_doc] [int] NOT NULL,
[customer_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[source_trx_ctrl_num] [char] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_crtemp] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_crtemp] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_crtemp] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_crtemp] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_crtemp] TO [public]
GO
