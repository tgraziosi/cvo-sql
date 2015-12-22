CREATE TABLE [dbo].[tdc_pkg_master]
(
[pkg_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pkg_usage_type_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pkg_class_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pkg_group_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[weight] [float] NULL,
[dim_uom] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dim_int_x] [float] NULL,
[dim_int_y] [float] NULL,
[dim_int_z] [float] NULL,
[dim_int_c] [float] NULL,
[dim_ext_x] [float] NULL,
[dim_ext_y] [float] NULL,
[dim_ext_z] [float] NULL,
[dim_ext_c] [float] NULL,
[cost_currency] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pm_cost_udef_a] [money] NULL,
[pm_cost_udef_b] [money] NULL,
[pm_cost_udef_c] [money] NULL,
[pm_cost_udef_d] [money] NULL,
[pm_int_udef_e] [float] NULL,
[pm_int_udef_f] [float] NULL,
[pm_udef_a] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pm_udef_b] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pm_udef_c] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pm_udef_d] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pm_udef_e] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[last_modified_date] [datetime] NOT NULL,
[modified_by] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_pkg_master] ADD CONSTRAINT [PK__tdc_pkg_master__2B14B8D8] PRIMARY KEY CLUSTERED  ([pkg_code]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_pkg_master] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_pkg_master] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_pkg_master] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_pkg_master] TO [public]
GO
