CREATE TABLE [dbo].[rpt_invtrndet]
(
[tran_type] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tran_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty] [decimal] (20, 8) NULL,
[tran_date] [datetime] NULL,
[in_stock] [decimal] (20, 8) NULL,
[update_typ] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tran_typ] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hold_qty] [decimal] (20, 8) NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_invtrndet] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_invtrndet] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_invtrndet] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_invtrndet] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_invtrndet] TO [public]
GO
