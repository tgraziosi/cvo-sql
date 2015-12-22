CREATE TABLE [dbo].[CVO_discount_adjustment_results]
(
[rec_id] [int] NOT NULL IDENTITY(1, 1),
[spid] [int] NOT NULL,
[order_no] [int] NOT NULL,
[ext] [int] NOT NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[promo_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[promo_level] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[curr_factor] [decimal] (20, 8) NOT NULL,
[oper_factor] [decimal] (20, 8) NOT NULL,
[curr_key] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[line_no] [int] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty] [decimal] (20, 8) NOT NULL,
[svag_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[orig_price] [decimal] (20, 8) NOT NULL,
[discount] [decimal] (20, 8) NOT NULL,
[std_price] [decimal] (20, 8) NULL,
[promo_disc] [decimal] (20, 8) NULL,
[price_diff] [decimal] (20, 8) NULL,
[price_level] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[process] [smallint] NOT NULL,
[date_from] [datetime] NULL,
[date_to] [datetime] NULL,
[price_class] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cust_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CVO_discount_adjustment_results_inx01] ON [dbo].[CVO_discount_adjustment_results] ([rec_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CVO_discount_adjustment_results_inx02] ON [dbo].[CVO_discount_adjustment_results] ([spid]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CVO_discount_adjustment_results_inx03] ON [dbo].[CVO_discount_adjustment_results] ([spid], [process], [status]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[CVO_discount_adjustment_results] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_discount_adjustment_results] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_discount_adjustment_results] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_discount_adjustment_results] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_discount_adjustment_results] TO [public]
GO
