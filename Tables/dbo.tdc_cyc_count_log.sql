CREATE TABLE [dbo].[tdc_cyc_count_log]
(
[team_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[userid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cyc_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[child_serial_no] [int] NULL,
[adm_actual_qty] [decimal] (20, 8) NULL,
[tdc_actual_qty] [decimal] (20, 8) NULL,
[count_qty] [decimal] (20, 8) NULL,
[count_date] [datetime] NULL,
[cycle_date] [datetime] NULL,
[post_qty] [decimal] (20, 8) NULL,
[post_pcs_qty] [decimal] (20, 8) NULL,
[post_ver] [int] NULL,
[post_pcs_ver] [int] NULL,
[update_user] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[update_date] [datetime] NOT NULL CONSTRAINT [DF__tdc_cyc_c__updat__08F4AAFE] DEFAULT (getdate())
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_cyc_count_log] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_cyc_count_log] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_cyc_count_log] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_cyc_count_log] TO [public]
GO
