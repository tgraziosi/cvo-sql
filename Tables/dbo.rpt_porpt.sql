CREATE TABLE [dbo].[rpt_porpt]
(
[vendor_code] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[account_no] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[conv_factor] [decimal] (18, 0) NULL,
[date_of_order] [datetime] NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ext_cost] [decimal] (18, 0) NULL,
[location] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[po_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[po_key] [int] NULL,
[project1] [varchar] (75) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[project2] [varchar] (75) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[project3] [varchar] (75) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty_ordered] [decimal] (18, 0) NULL,
[qty_received] [decimal] (18, 0) NULL,
[reference_code] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rel_date] [datetime] NULL,
[line_status] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[item_type] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[unit_cost] [decimal] (18, 0) NULL,
[unit_measure] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vend_sku] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[who_entered] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[po_type] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[prod_no] [int] NULL,
[po_status] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[confirm_date] [datetime] NULL,
[rel_quantity] [decimal] (18, 0) NULL,
[rel_received] [decimal] (18, 0) NULL,
[release_date] [datetime] NULL,
[rel_status] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group_1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group_2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group_3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group_4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_porpt] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_porpt] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_porpt] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_porpt] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_porpt] TO [public]
GO
