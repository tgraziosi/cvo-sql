CREATE TABLE [dbo].[cvo_sc_ra_forgiveness]
(
[Salesperson] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Territory] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Cust_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Order_no] [int] NULL,
[Ext] [int] NULL,
[Invoice_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[InvoiceDate] [datetime] NULL,
[Amount] [real] NULL,
[comm_pct] [decimal] (5, 2) NULL,
[comm_amt] [real] NULL,
[RA_amount] [float] NULL,
[pom_amount] [float] NULL,
[forgive_me] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[id] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
GRANT DELETE ON  [dbo].[cvo_sc_ra_forgiveness] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_sc_ra_forgiveness] TO [public]
GO
GRANT REFERENCES ON  [dbo].[cvo_sc_ra_forgiveness] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_sc_ra_forgiveness] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_sc_ra_forgiveness] TO [public]
GO
