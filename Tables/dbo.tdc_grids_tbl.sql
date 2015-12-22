CREATE TABLE [dbo].[tdc_grids_tbl]
(
[userid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[form] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[grid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[field] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pos] [int] NOT NULL,
[visible_flg] [int] NULL CONSTRAINT [DF__tdc_grids__visib__41390421] DEFAULT ((1)),
[editable_flg] [int] NULL CONSTRAINT [DF__tdc_grids__edita__422D285A] DEFAULT ((1))
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [tdc_grids_tbl_idx1] ON [dbo].[tdc_grids_tbl] ([userid], [form], [grid], [field]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_grids_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_grids_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_grids_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_grids_tbl] TO [public]
GO
