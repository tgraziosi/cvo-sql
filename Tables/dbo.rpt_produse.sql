CREATE TABLE [dbo].[rpt_produse]
(
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[prod_part] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[prod_no] [int] NULL,
[prod_ext] [int] NULL,
[seq_no] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tran_date] [datetime] NULL,
[employee_key] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[used_qty] [float] NULL,
[pieces] [float] NULL,
[scrap_pcs] [float] NULL,
[shift] [int] NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[time_no] [int] NULL,
[prod_description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[inv_description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_produse] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_produse] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_produse] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_produse] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_produse] TO [public]
GO
