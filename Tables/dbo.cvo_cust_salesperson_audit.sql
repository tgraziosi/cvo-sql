CREATE TABLE [dbo].[cvo_cust_salesperson_audit]
(
[row_id] [int] NOT NULL IDENTITY(1, 1),
[row_type] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[audit_date] [datetime] NULL CONSTRAINT [DF__cvo_cust___audit__78FC9F7A] DEFAULT (getdate()),
[user_spid] [int] NULL,
[username] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[salesperson_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[primary_rep] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[include_rx] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[split] [decimal] (20, 8) NULL,
[brand] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[brand_split] [decimal] (20, 8) NULL,
[brand_excl] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[comm_rate] [decimal] (20, 8) NULL,
[brand_exclude] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[promo_id] [varchar] (31) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rx_only] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[startdate] [datetime] NULL,
[enddate] [datetime] NULL,
[ship_to] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT DELETE ON  [dbo].[cvo_cust_salesperson_audit] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_cust_salesperson_audit] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_cust_salesperson_audit] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_cust_salesperson_audit] TO [public]
GO
