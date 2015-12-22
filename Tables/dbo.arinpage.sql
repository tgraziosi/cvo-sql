CREATE TABLE [dbo].[arinpage]
(
[timestamp] [timestamp] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[apply_to_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[apply_trx_type] [smallint] NOT NULL,
[trx_type] [smallint] NOT NULL,
[date_applied] [int] NOT NULL,
[date_due] [int] NOT NULL,
[date_aging] [int] NOT NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[salesperson_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[territory_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[price_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_due] [float] NOT NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [arinpage_ind_0] ON [dbo].[arinpage] ([apply_to_num], [trx_type], [date_aging]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [arinpage_ind_2] ON [dbo].[arinpage] ([customer_code], [apply_to_num], [trx_type], [date_applied]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [arinpage_ind_3] ON [dbo].[arinpage] ([salesperson_code], [apply_to_num], [trx_type], [date_applied]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [arinpage_ind_4] ON [dbo].[arinpage] ([territory_code], [apply_to_num], [trx_type], [date_applied]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [arinpage_ind_1] ON [dbo].[arinpage] ([trx_ctrl_num], [trx_type], [date_aging]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arinpage] TO [public]
GO
GRANT SELECT ON  [dbo].[arinpage] TO [public]
GO
GRANT INSERT ON  [dbo].[arinpage] TO [public]
GO
GRANT DELETE ON  [dbo].[arinpage] TO [public]
GO
GRANT UPDATE ON  [dbo].[arinpage] TO [public]
GO
