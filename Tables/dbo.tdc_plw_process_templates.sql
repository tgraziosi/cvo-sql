CREATE TABLE [dbo].[tdc_plw_process_templates]
(
[userid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[order_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[type] [varchar] (7) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[template_code] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin_group] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[search_sort] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[dist_type] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pkg_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[user_group] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tran_priority] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[on_hold] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cdock] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pass_bin] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bin_first] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[replen_group] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[multiple_parts] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[modified_by] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[modified_date] [datetime] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_plw_process_templates] ADD CONSTRAINT [PK_tdc_plw_process_templates] PRIMARY KEY NONCLUSTERED  ([template_code], [userid], [location], [order_type], [type]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_plw_process_templates_ind1] ON [dbo].[tdc_plw_process_templates] ([template_code], [userid], [location], [type], [order_type]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_plw_process_templates] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_plw_process_templates] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_plw_process_templates] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_plw_process_templates] TO [public]
GO
