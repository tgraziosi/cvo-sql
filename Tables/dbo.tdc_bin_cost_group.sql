CREATE TABLE [dbo].[tdc_bin_cost_group]
(
[cost_group_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cost_currency_uom] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_modified_date] [datetime] NOT NULL,
[modified_by] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bcost_udef_a] [money] NULL,
[bcost_udef_b] [money] NULL,
[bcost_udef_c] [money] NULL,
[bcost_udef_d] [money] NULL,
[bcost_udef_e] [money] NULL,
[bcost_udef_f] [int] NULL,
[bcost_udef_g] [int] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [tdc_bin_cost_group_idx1] ON [dbo].[tdc_bin_cost_group] ([cost_group_code]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_bin_cost_group] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_bin_cost_group] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_bin_cost_group] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_bin_cost_group] TO [public]
GO
