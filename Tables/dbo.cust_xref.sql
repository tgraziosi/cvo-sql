CREATE TABLE [dbo].[cust_xref]
(
[timestamp] [timestamp] NOT NULL,
[customer_key] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[last_date] [datetime] NOT NULL,
[ordered] [decimal] (20, 8) NULL,
[shipped] [decimal] (20, 8) NULL,
[last_price] [decimal] (20, 8) NOT NULL,
[cust_part] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_no] [int] NULL,
[order_ext] [int] NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [custxrf1] ON [dbo].[cust_xref] ([customer_key], [part_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cust_xref] TO [public]
GO
GRANT SELECT ON  [dbo].[cust_xref] TO [public]
GO
GRANT INSERT ON  [dbo].[cust_xref] TO [public]
GO
GRANT DELETE ON  [dbo].[cust_xref] TO [public]
GO
GRANT UPDATE ON  [dbo].[cust_xref] TO [public]
GO
