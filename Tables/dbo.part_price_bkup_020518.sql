CREATE TABLE [dbo].[part_price_bkup_020518]
(
[timestamp] [timestamp] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[curr_key] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[price_a] [decimal] (20, 8) NULL,
[price_b] [decimal] (20, 8) NULL,
[price_c] [decimal] (20, 8) NULL,
[price_d] [decimal] (20, 8) NULL,
[price_e] [decimal] (20, 8) NULL,
[price_f] [decimal] (20, 8) NULL,
[qty_a] [decimal] (20, 8) NULL,
[qty_b] [decimal] (20, 8) NULL,
[qty_c] [decimal] (20, 8) NULL,
[qty_d] [decimal] (20, 8) NULL,
[qty_e] [decimal] (20, 8) NULL,
[qty_f] [decimal] (20, 8) NULL,
[promo_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[promo_rate] [decimal] (20, 8) NULL,
[promo_date_expires] [datetime] NULL,
[promo_date_entered] [datetime] NULL,
[promo_start_date] [datetime] NULL,
[last_system_upd_date] [datetime] NULL
) ON [PRIMARY]
GO
