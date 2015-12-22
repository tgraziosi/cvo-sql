CREATE TABLE [dbo].[apinppdt]
(
[timestamp] [timestamp] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[sequence_id] [int] NOT NULL,
[apply_to_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[apply_trx_type] [smallint] NOT NULL,
[amt_applied] [float] NOT NULL,
[amt_disc_taken] [float] NOT NULL,
[line_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[void_flag] [smallint] NOT NULL,
[payment_hold_flag] [smallint] NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vo_amt_applied] [float] NULL,
[vo_amt_disc_taken] [float] NULL,
[gain_home] [float] NULL,
[gain_oper] [float] NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cross_rate] [float] NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [apinppdt_ind_1] ON [dbo].[apinppdt] ([apply_to_num], [vendor_code], [apply_trx_type]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [apinppdt_ind_2] ON [dbo].[apinppdt] ([trx_ctrl_num], [trx_type], [org_id]) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [apinppdt_ind_0] ON [dbo].[apinppdt] ([trx_ctrl_num], [trx_type], [sequence_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apinppdt] TO [public]
GO
GRANT SELECT ON  [dbo].[apinppdt] TO [public]
GO
GRANT INSERT ON  [dbo].[apinppdt] TO [public]
GO
GRANT DELETE ON  [dbo].[apinppdt] TO [public]
GO
GRANT UPDATE ON  [dbo].[apinppdt] TO [public]
GO
