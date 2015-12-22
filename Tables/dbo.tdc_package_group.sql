CREATE TABLE [dbo].[tdc_package_group]
(
[pkg_group_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[last_modified_date] [datetime] NOT NULL,
[modified_by] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pg_udef_a] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pg_udef_b] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pg_udef_c] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pg_udef_d] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pg_udef_e] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_package_group] ADD CONSTRAINT [PK_tdc_package_group_1__15] PRIMARY KEY CLUSTERED  ([pkg_group_code]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_package_group] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_package_group] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_package_group] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_package_group] TO [public]
GO
