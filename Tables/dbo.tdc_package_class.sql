CREATE TABLE [dbo].[tdc_package_class]
(
[pkg_class_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[last_modified_date] [datetime] NOT NULL,
[modified_by] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pc_udef_a] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pc_udef_b] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pc_udef_c] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pc_udef_d] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pc_udef_e] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_package_class] ADD CONSTRAINT [PK_tdc_package_class_1__15] PRIMARY KEY CLUSTERED  ([pkg_class_code]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_package_class] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_package_class] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_package_class] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_package_class] TO [public]
GO
