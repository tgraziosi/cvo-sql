CREATE TABLE [dbo].[rpt_invindentbldplan]
(
[ilevel] [int] NULL,
[seq_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[indent_part] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty] [decimal] (20, 8) NULL,
[qty_ext] [decimal] (20, 8) NULL,
[cost] [decimal] (20, 8) NULL,
[labor] [decimal] (20, 8) NULL,
[type] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[uom] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[req_pn] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sort_seq] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[direct_dolrs] [decimal] (20, 8) NULL,
[ovhd_dolrs] [decimal] (20, 8) NULL,
[util_dolrs] [decimal] (20, 8) NULL,
[req_qty] [decimal] (20, 8) NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cost_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_invindentbldplan] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_invindentbldplan] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_invindentbldplan] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_invindentbldplan] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_invindentbldplan] TO [public]
GO
