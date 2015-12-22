CREATE TABLE [dbo].[inv_cost_history]
(
[timestamp] [timestamp] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ins_del_flag] [int] NOT NULL,
[tran_code] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tran_no] [int] NOT NULL,
[tran_ext] [int] NOT NULL,
[tran_line] [int] NOT NULL,
[tran_date] [datetime] NOT NULL,
[tran_age] [datetime] NOT NULL,
[unit_cost] [decimal] (20, 8) NOT NULL,
[quantity] [decimal] (20, 8) NOT NULL,
[inv_cost_bal] [decimal] (20, 8) NOT NULL,
[direct_dolrs] [decimal] (20, 8) NOT NULL,
[ovhd_dolrs] [decimal] (20, 8) NOT NULL,
[labor] [decimal] (20, 8) NOT NULL,
[util_dolrs] [decimal] (20, 8) NOT NULL,
[account] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_cost] [decimal] (20, 8) NOT NULL,
[audit] [int] NOT NULL,
[tot_mtrl_cost] [decimal] (20, 8) NULL,
[tot_dir_cost] [decimal] (20, 8) NULL,
[tot_ovhd_cost] [decimal] (20, 8) NULL,
[tot_util_cost] [decimal] (20, 8) NULL,
[tot_labor_cost] [decimal] (20, 8) NULL,
[lot_ser] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__inv_cost___lot_s__1F3A8886] DEFAULT ('')
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [invcosth_m2] ON [dbo].[inv_cost_history] ([audit]) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [costhist1] ON [dbo].[inv_cost_history] ([part_no], [location]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [invcosth_m4] ON [dbo].[inv_cost_history] ([tran_no], [tran_code], [account]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [invcosth_m3] ON [dbo].[inv_cost_history] ([tran_no], [tran_ext], [tran_line]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[inv_cost_history] TO [public]
GO
GRANT SELECT ON  [dbo].[inv_cost_history] TO [public]
GO
GRANT INSERT ON  [dbo].[inv_cost_history] TO [public]
GO
GRANT DELETE ON  [dbo].[inv_cost_history] TO [public]
GO
GRANT UPDATE ON  [dbo].[inv_cost_history] TO [public]
GO
