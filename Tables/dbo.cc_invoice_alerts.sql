CREATE TABLE [dbo].[cc_invoice_alerts]
(
[number_days] [int] NOT NULL,
[date_type] [smallint] NOT NULL,
[date_created] [int] NOT NULL,
[created_by] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_applied] [int] NOT NULL,
[date_doc] [int] NOT NULL,
[date_due] [int] NOT NULL,
[date_aging] [int] NOT NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[balance] [float] NOT NULL,
[workload_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [cc_invoice_alerts_idx1] ON [dbo].[cc_invoice_alerts] ([date_created], [trx_ctrl_num], [workload_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cc_invoice_alerts] TO [public]
GO
GRANT SELECT ON  [dbo].[cc_invoice_alerts] TO [public]
GO
GRANT INSERT ON  [dbo].[cc_invoice_alerts] TO [public]
GO
GRANT DELETE ON  [dbo].[cc_invoice_alerts] TO [public]
GO
GRANT UPDATE ON  [dbo].[cc_invoice_alerts] TO [public]
GO
