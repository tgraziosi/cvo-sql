CREATE TABLE [dbo].[temp_prod_list]
(
[timestamp] [timestamp] NOT NULL,
[prod_no] [int] NOT NULL,
[prod_ext] [int] NOT NULL,
[line_no] [int] NOT NULL,
[seq_no] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[plan_qty] [decimal] (20, 8) NOT NULL,
[used_qty] [decimal] (20, 8) NOT NULL,
[attrib] [decimal] (20, 8) NULL,
[uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[conv_factor] [decimal] (20, 8) NOT NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lb_tracking] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bench_stock] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[constrain] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[plan_pcs] [decimal] (20, 8) NOT NULL,
[pieces] [decimal] (20, 8) NOT NULL,
[scrap_pcs] [decimal] (20, 8) NOT NULL,
[part_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[row_id] [int] NOT NULL IDENTITY(1, 1),
[p_qty] [decimal] (20, 8) NULL,
[p_line] [int] NULL,
[p_pcs] [decimal] (20, 8) NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [tprodlst1] ON [dbo].[temp_prod_list] ([prod_no], [prod_ext], [row_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[temp_prod_list] TO [public]
GO
GRANT SELECT ON  [dbo].[temp_prod_list] TO [public]
GO
GRANT INSERT ON  [dbo].[temp_prod_list] TO [public]
GO
GRANT DELETE ON  [dbo].[temp_prod_list] TO [public]
GO
GRANT UPDATE ON  [dbo].[temp_prod_list] TO [public]
GO
