CREATE TABLE [dbo].[icv_orders]
(
[order_no] [int] NOT NULL,
[ext] [int] NOT NULL,
[icv_booked] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[icv_credit] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cc_status] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cr_adj_status] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cr_adj_error] [int] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [_WA_Sys_ext_3D5594DF] ON [dbo].[icv_orders] ([ext]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [_WA_Sys_icv_booked_3D5594DF] ON [dbo].[icv_orders] ([icv_booked]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [_WA_Sys_order_no_3D5594DF] ON [dbo].[icv_orders] ([order_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[icv_orders] TO [public]
GO
GRANT SELECT ON  [dbo].[icv_orders] TO [public]
GO
GRANT INSERT ON  [dbo].[icv_orders] TO [public]
GO
GRANT DELETE ON  [dbo].[icv_orders] TO [public]
GO
GRANT UPDATE ON  [dbo].[icv_orders] TO [public]
GO
