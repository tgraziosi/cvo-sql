CREATE TABLE [dbo].[mls_lb_sync_info]
(
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trx_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tran_no] [int] NULL,
[tran_ext] [int] NULL,
[line_no] [int] NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[iqty] [decimal] (20, 8) NULL,
[iqty2] [decimal] (20, 8) NULL,
[lqty] [decimal] (20, 8) NULL,
[uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__mls_lb_sync__uom__3490CFE6] DEFAULT ('EA'),
[conv_factor] [decimal] (20, 8) NULL CONSTRAINT [DF__mls_lb_sy__conv___3584F41F] DEFAULT ((1.0)),
[serial_flag] [int] NULL,
[priority] [int] NULL CONSTRAINT [DF__mls_lb_sy__prior__36791858] DEFAULT ((0)),
[row_id] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [mlslbinfo1] ON [dbo].[mls_lb_sync_info] ([part_no], [location]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [mlslbinfo2] ON [dbo].[mls_lb_sync_info] ([row_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[mls_lb_sync_info] TO [public]
GO
GRANT SELECT ON  [dbo].[mls_lb_sync_info] TO [public]
GO
GRANT INSERT ON  [dbo].[mls_lb_sync_info] TO [public]
GO
GRANT DELETE ON  [dbo].[mls_lb_sync_info] TO [public]
GO
GRANT UPDATE ON  [dbo].[mls_lb_sync_info] TO [public]
GO
