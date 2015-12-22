CREATE TABLE [dbo].[rpt_invactsum]
(
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[begin_stock] [decimal] (20, 8) NULL,
[in_stock] [decimal] (20, 8) NULL,
[rec_sum] [decimal] (20, 8) NULL,
[ship_sum] [decimal] (20, 8) NULL,
[sales_sum] [decimal] (20, 8) NULL,
[xfer_sum_to] [decimal] (20, 8) NULL,
[xfer_sum_from] [decimal] (20, 8) NULL,
[iss_sum] [decimal] (20, 8) NULL,
[mfg_sum] [decimal] (20, 8) NULL,
[used_sum] [decimal] (20, 8) NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_invactsum] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_invactsum] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_invactsum] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_invactsum] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_invactsum] TO [public]
GO
