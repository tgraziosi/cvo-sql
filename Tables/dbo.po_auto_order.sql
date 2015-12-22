CREATE TABLE [dbo].[po_auto_order]
(
[timestamp] [timestamp] NOT NULL,
[row_id] [int] NOT NULL IDENTITY(1, 1),
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[po_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[po_line] [int] NOT NULL,
[po_part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ordered] [decimal] (20, 8) NOT NULL,
[conv_factor] [decimal] (20, 8) NOT NULL,
[curr_price] [decimal] (20, 8) NOT NULL,
[part_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[discount] [decimal] (20, 8) NOT NULL,
[create_po_flag] [int] NOT NULL,
[back_ord_flag] [int] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tax_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[price_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [po_auto_order1] ON [dbo].[po_auto_order] ([po_no], [po_line], [po_part_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [po_auto_order2] ON [dbo].[po_auto_order] ([row_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[po_auto_order] TO [public]
GO
GRANT SELECT ON  [dbo].[po_auto_order] TO [public]
GO
GRANT INSERT ON  [dbo].[po_auto_order] TO [public]
GO
GRANT DELETE ON  [dbo].[po_auto_order] TO [public]
GO
GRANT UPDATE ON  [dbo].[po_auto_order] TO [public]
GO
