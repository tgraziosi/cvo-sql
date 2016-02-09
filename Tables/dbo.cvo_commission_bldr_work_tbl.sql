CREATE TABLE [dbo].[cvo_commission_bldr_work_tbl]
(
[Salesperson] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Territory] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Cust_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Ship_to] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Order_no] [int] NULL,
[Ext] [int] NULL,
[Invoice_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[InvoiceDate] [int] NOT NULL,
[DateShipped] [int] NOT NULL,
[OrderType] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Promo_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Level] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[type] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Net_Sales] [float] NULL,
[Amount] [float] NULL,
[Comm_pct] [decimal] (5, 2) NULL,
[Comm_amt] [float] NULL,
[Loc] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[salesperson_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HireDate] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[draw_amount] [decimal] (14, 2) NULL,
[invoicedate_dt] [datetime] NOT NULL,
[dateshipped_dt] [datetime] NOT NULL,
[fiscal_period] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[added_date] [datetime] NOT NULL,
[added_by] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[id] [bigint] NOT NULL
) ON [PRIMARY]
ALTER TABLE [dbo].[cvo_commission_bldr_work_tbl] ADD 
CONSTRAINT [PK__cvo_commission_b__64F0176C] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_commission_bldr_work_tbl] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_commission_bldr_work_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_commission_bldr_work_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_commission_bldr_work_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_commission_bldr_work_tbl] TO [public]
GO
