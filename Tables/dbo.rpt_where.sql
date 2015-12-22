CREATE TABLE [dbo].[rpt_where]
(
[asm_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty] [float] NULL,
[uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[active] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[item_desc] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[asm_desc] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bench_stock] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[constrain] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_where] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_where] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_where] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_where] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_where] TO [public]
GO
