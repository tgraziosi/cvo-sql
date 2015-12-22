CREATE TABLE [dbo].[tolerance]
(
[timestamp] [timestamp] NOT NULL,
[tolerance_cd] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[receipts_qty_action] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[matching_qty_action] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty_over_pct] [tinyint] NOT NULL,
[qty_under_pct] [tinyint] NOT NULL,
[receipts_unit_price_action] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[matching_unit_price_action] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[unit_price_over_pct] [tinyint] NOT NULL,
[unit_price_under_pct] [tinyint] NOT NULL,
[tax_action] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tax_over_pct] [tinyint] NOT NULL,
[tax_under_pct] [tinyint] NOT NULL,
[total_amt_action] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[total_amt_over_pct] [tinyint] NOT NULL,
[total_amt_under_pct] [tinyint] NOT NULL,
[amt_over_ext_price] [decimal] (20, 8) NULL,
[amt_under_ext_price] [decimal] (20, 8) NULL,
[amt_over_tax] [decimal] (20, 8) NULL,
[amt_under_tax] [decimal] (20, 8) NULL,
[amt_under_total_order] [decimal] (20, 8) NULL,
[amt_over_total_order] [decimal] (20, 8) NULL,
[void] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[void_who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_date] [datetime] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [pk_tolerance] ON [dbo].[tolerance] ([tolerance_cd]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[tolerance] TO [public]
GO
GRANT SELECT ON  [dbo].[tolerance] TO [public]
GO
GRANT INSERT ON  [dbo].[tolerance] TO [public]
GO
GRANT DELETE ON  [dbo].[tolerance] TO [public]
GO
GRANT UPDATE ON  [dbo].[tolerance] TO [public]
GO
