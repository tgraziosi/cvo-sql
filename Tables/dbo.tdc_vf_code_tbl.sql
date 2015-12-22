CREATE TABLE [dbo].[tdc_vf_code_tbl]
(
[vf_code] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[quantity] [decimal] (20, 8) NOT NULL,
[carton_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pack_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[weight] [decimal] (20, 8) NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[tdc_vf_code_tbl] TO [public]
GO
GRANT SELECT ON  [dbo].[tdc_vf_code_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_vf_code_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_vf_code_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_vf_code_tbl] TO [public]
GO
