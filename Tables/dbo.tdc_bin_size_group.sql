CREATE TABLE [dbo].[tdc_bin_size_group]
(
[size_group_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[dim_uom] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_modified_date] [datetime] NOT NULL,
[modified_by] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[dim_x] [float] NOT NULL,
[dim_y] [float] NOT NULL,
[dim_z] [float] NOT NULL,
[dim_c] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_bin_size_group] ADD CONSTRAINT [PK_tdc_bin_size_group_1__17] PRIMARY KEY CLUSTERED  ([size_group_code]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_bin_size_group] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_bin_size_group] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_bin_size_group] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_bin_size_group] TO [public]
GO
