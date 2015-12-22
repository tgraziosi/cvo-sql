CREATE TABLE [dbo].[ardncsdt]
(
[dunn_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_due] [int] NULL,
[invoice_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[salesperson_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lower_sep_day] [int] NULL,
[upper_sep_day] [int] NULL,
[dunning_level] [smallint] NOT NULL,
[amt_extra] [float] NULL,
[amt_due] [float] NOT NULL,
[amt_paid] [float] NOT NULL,
[amt_extra_projected] [float] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [ardncsdt_1] ON [dbo].[ardncsdt] ([customer_code], [invoice_num], [dunning_level]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [ardncsdt_0] ON [dbo].[ardncsdt] ([dunn_ctrl_num], [customer_code], [invoice_num]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[ardncsdt] TO [public]
GO
GRANT SELECT ON  [dbo].[ardncsdt] TO [public]
GO
GRANT INSERT ON  [dbo].[ardncsdt] TO [public]
GO
GRANT DELETE ON  [dbo].[ardncsdt] TO [public]
GO
GRANT UPDATE ON  [dbo].[ardncsdt] TO [public]
GO
