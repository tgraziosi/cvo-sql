CREATE TABLE [dbo].[rpt_ccrpt]
(
[invoice_no] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[invoice_amt_net] [real] NOT NULL,
[amt_payment] [int] NOT NULL,
[cash_reciept_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[invoice_date] [int] NOT NULL,
[order_number] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[card_number] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[expiration_date] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[authorization_code] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[order_no] [int] NOT NULL,
[ext] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[transtatus] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[oflag] [int] NOT NULL,
[posted_flag] [smallint] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_ccrpt] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_ccrpt] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_ccrpt] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_ccrpt] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_ccrpt] TO [public]
GO
