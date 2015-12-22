CREATE TABLE [dbo].[rpt_ardncsdt]
(
[dunning_level] [smallint] NOT NULL,
[dunn_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[invoice_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_due] [datetime] NOT NULL,
[amt_due] [float] NOT NULL,
[amt_paid] [float] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_ardncsdt] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_ardncsdt] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_ardncsdt] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_ardncsdt] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_ardncsdt] TO [public]
GO
