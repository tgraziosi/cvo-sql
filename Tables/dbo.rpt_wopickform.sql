CREATE TABLE [dbo].[rpt_wopickform]
(
[p_prod_no] [int] NOT NULL,
[p_prod_ext] [int] NOT NULL,
[p_status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[p_sch_date] [datetime] NOT NULL,
[p_part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_staging_area] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_project] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_sch_qty] [decimal] (20, 8) NOT NULL,
[p_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_prod_date] [datetime] NOT NULL,
[p_qty] [decimal] (20, 8) NOT NULL,
[p_location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_level] [int] NOT NULL,
[x_line_no] [int] NOT NULL,
[x_seq_no] [char] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[x_part_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[x_location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[x_planned] [decimal] (20, 8) NOT NULL,
[x_picked] [decimal] (20, 8) NOT NULL,
[x_lb_tracking] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[x_plan_pcs] [decimal] (20, 8) NOT NULL,
[i_bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[i_uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[i_in_stock] [decimal] (20, 8) NOT NULL,
[i_commit_ed] [decimal] (20, 8) NOT NULL,
[i_status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_qty] [decimal] (20, 8) NULL,
[l_uom_qty] [decimal] (20, 8) NULL,
[c_printed] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[p_note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[i_description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[k_msg] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[k_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[x_pline] [int] NOT NULL,
[x_constrain] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[x_sort_order] [int] NOT NULL,
[x_note2] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_note3] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_note4] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[s_prod_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[g_dec_separator] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[g_thou_separator] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group_1] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group_2] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_ind] [int] NULL,
[sch_qty_precision] [int] NULL,
[planned_qty_precision] [int] NULL,
[picked_qty_precision] [int] NULL,
[bin_qty_precision] [int] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_wopickform] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_wopickform] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_wopickform] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_wopickform] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_wopickform] TO [public]
GO
