CREATE TABLE [dbo].[adm_inv_mtd]
(
[timestamp] [timestamp] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[period] [int] NOT NULL,
[issued_qty] [decimal] (20, 8) NOT NULL,
[produced_qty] [decimal] (20, 8) NOT NULL,
[usage_qty] [decimal] (20, 8) NOT NULL,
[sales_qty] [decimal] (20, 8) NOT NULL,
[sales_amt] [decimal] (20, 8) NOT NULL,
[recv_qty] [decimal] (20, 8) NOT NULL,
[xfer_qty] [decimal] (20, 8) NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [adm_inv_mtd1] ON [dbo].[adm_inv_mtd] ([part_no], [location], [period]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[adm_inv_mtd] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_inv_mtd] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_inv_mtd] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_inv_mtd] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_inv_mtd] TO [public]
GO
