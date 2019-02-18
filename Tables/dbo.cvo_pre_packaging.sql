CREATE TABLE [dbo].[cvo_pre_packaging]
(
[order_no] [int] NULL,
[order_ext] [int] NULL,
[cons_no] [int] NULL,
[line_no] [int] NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ordered] [decimal] (20, 8) NULL,
[pack_qty] [decimal] (20, 8) NULL,
[box_type] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[box_id] [int] NULL,
[carton_no] [int] NULL,
[order_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[kit_item] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[row_id] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_pre_packaging_ind0] ON [dbo].[cvo_pre_packaging] ([order_no], [order_ext]) ON [PRIMARY]
GO
GRANT DELETE ON  [dbo].[cvo_pre_packaging] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_pre_packaging] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_pre_packaging] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_pre_packaging] TO [public]
GO
