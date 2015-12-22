CREATE TABLE [dbo].[rpt_aprptcdh]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[invoice_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[invoice_date] [datetime] NULL,
[voucher_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[voucher_date_due] [datetime] NULL,
[amt_paid] [float] NOT NULL,
[amt_disc_taken] [float] NOT NULL,
[amt_net] [float] NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[payment_type] [smallint] NOT NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[curr_precision] [smallint] NOT NULL,
[voucher_internal_memo] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[comment_line] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[voucher_classify] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_link] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_aprptcdh] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_aprptcdh] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_aprptcdh] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_aprptcdh] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_aprptcdh] TO [public]
GO
