CREATE TABLE [dbo].[rpt_socoa]
(
[order_no] [int] NULL,
[order_ext] [int] NULL,
[cust_code] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[line_no] [int] NULL,
[qc_no] [int] NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qc_qty] [decimal] (20, 8) NULL,
[reject_qty] [decimal] (20, 8) NULL,
[date_complete] [datetime] NULL,
[test_key] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[value] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[min_val] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[max_val] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[target] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[print_note] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[coa] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[inspector] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[owner] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hdrnote] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[testnote] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[appearance] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[composition] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group_1] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group_2] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group_3] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_socoa] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_socoa] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_socoa] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_socoa] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_socoa] TO [public]
GO
