CREATE TABLE [dbo].[cvo_cf_process_select]
(
[user_spid] [int] NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_part_type] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[line_no] [int] NULL,
[orig_row] [int] NULL,
[component_type] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[orig_component] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[repl_component] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[comp_desc] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[required_qty] [decimal] (20, 8) NULL,
[available_qty] [decimal] (20, 8) NULL,
[attribute] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[category] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[style] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[show_all_styles] [int] NULL,
[all_type] [int] NULL,
[colour] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[size_code] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_by] [int] NULL,
[selected] [int] NULL,
[selected_qty] [decimal] (20, 8) NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_cf_process_select_ind0] ON [dbo].[cvo_cf_process_select] ([user_spid]) ON [PRIMARY]
GO
GRANT DELETE ON  [dbo].[cvo_cf_process_select] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_cf_process_select] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_cf_process_select] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_cf_process_select] TO [public]
GO
