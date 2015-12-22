CREATE TABLE [dbo].[inv_tran]
(
[timestamp] [timestamp] NOT NULL,
[tran_id] [int] NOT NULL IDENTITY(1, 1),
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[update_ind] [int] NOT NULL CONSTRAINT [DF__inv_tran__update__483C9E19] DEFAULT ((0)),
[curr_date] [datetime] NOT NULL CONSTRAINT [DF__inv_tran__curr_d__4930C252] DEFAULT (getdate()),
[apply_date] [datetime] NULL,
[user_nm] [nvarchar] (256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__inv_tran__user_n__4A24E68B] DEFAULT (user_name()),
[host_nm] [nvarchar] (256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__inv_tran__host_n__4B190AC4] DEFAULT (host_name()),
[tran_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tran_no] [int] NOT NULL,
[tran_ext] [int] NOT NULL,
[tran_line] [int] NOT NULL,
[tran_status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tran_inv_qty] [decimal] (20, 8) NOT NULL,
[tran_uom_qty] [decimal] (20, 8) NOT NULL,
[tran_uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tran_mtrl_cost] [decimal] (20, 8) NOT NULL,
[tran_dir_cost] [decimal] (20, 8) NOT NULL,
[tran_ovhd_cost] [decimal] (20, 8) NOT NULL,
[tran_util_cost] [decimal] (20, 8) NOT NULL,
[inv_qty] [decimal] (20, 8) NOT NULL,
[inv_mtrl_cost] [decimal] (20, 8) NOT NULL,
[inv_dir_cost] [decimal] (20, 8) NOT NULL,
[inv_ovhd_cost] [decimal] (20, 8) NOT NULL,
[inv_util_cost] [decimal] (20, 8) NOT NULL,
[update_typ] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[process_typ] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[inv_cost_method] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[inv_status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[in_stock] [decimal] (20, 8) NOT NULL CONSTRAINT [DF__inv_tran__in_sto__4C0D2EFD] DEFAULT ((0.0)),
[hold_qty] [decimal] (20, 8) NOT NULL CONSTRAINT [DF__inv_tran__hold_q__4D015336] DEFAULT ((0.0)),
[cost_layer_qty] [decimal] (20, 8) NOT NULL,
[acct_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[avg_mtrl_cost] [decimal] (20, 8) NOT NULL,
[avg_dir_cost] [decimal] (20, 8) NOT NULL,
[avg_ovhd_cost] [decimal] (20, 8) NOT NULL,
[avg_util_cost] [decimal] (20, 8) NOT NULL,
[std_mtrl_cost] [decimal] (20, 8) NOT NULL,
[std_dir_cost] [decimal] (20, 8) NOT NULL,
[std_ovhd_cost] [decimal] (20, 8) NOT NULL,
[std_util_cost] [decimal] (20, 8) NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [inv_tran2] ON [dbo].[inv_tran] ([curr_date]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [inv_tran_idx1_042413] ON [dbo].[inv_tran] ([part_no], [tran_no], [tran_ext]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [PK_inv_tran] ON [dbo].[inv_tran] ([tran_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[inv_tran] TO [public]
GO
GRANT SELECT ON  [dbo].[inv_tran] TO [public]
GO
GRANT INSERT ON  [dbo].[inv_tran] TO [public]
GO
GRANT DELETE ON  [dbo].[inv_tran] TO [public]
GO
GRANT UPDATE ON  [dbo].[inv_tran] TO [public]
GO
