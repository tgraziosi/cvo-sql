CREATE TABLE [dbo].[tdc_user_pallet_build_tbl]
(
[userid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pkg_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[current_pallet_id] [int] NULL,
[current_load_no] [int] NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_user_pallet_build_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_user_pallet_build_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_user_pallet_build_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_user_pallet_build_tbl] TO [public]
GO
