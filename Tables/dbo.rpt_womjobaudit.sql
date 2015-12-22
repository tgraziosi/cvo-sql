CREATE TABLE [dbo].[rpt_womjobaudit]
(
[prod_no] [int] NULL,
[prod_part] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[prod_desc] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[prod_stat] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[po_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[release_date] [datetime] NULL,
[quantity] [decimal] (20, 0) NULL,
[received] [decimal] (20, 0) NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_womjobaudit] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_womjobaudit] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_womjobaudit] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_womjobaudit] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_womjobaudit] TO [public]
GO
