CREATE TABLE [dbo].[cvo_ord_list_fc]
(
[order_no] [int] NULL,
[order_ext] [int] NULL,
[line_no] [int] NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[case_part] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pattern_part] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[polarized_part] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_ord_list_fc_ind0] ON [dbo].[cvo_ord_list_fc] ([order_no], [order_ext], [line_no], [part_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_ord_list_fc] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_ord_list_fc] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_ord_list_fc] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_ord_list_fc] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_ord_list_fc] TO [public]
GO
