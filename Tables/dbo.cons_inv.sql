CREATE TABLE [dbo].[cons_inv]
(
[timestamp] [timestamp] NOT NULL,
[order_ext] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[order_no] [int] NOT NULL,
[ext] [int] NOT NULL,
[cust_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_shipped] [datetime] NOT NULL,
[ship_to] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[total_amt_order] [decimal] (13, 0) NOT NULL,
[consolidate_flag] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [cons_inv_idx] ON [dbo].[cons_inv] ([order_ext]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cons_inv] TO [public]
GO
GRANT SELECT ON  [dbo].[cons_inv] TO [public]
GO
GRANT INSERT ON  [dbo].[cons_inv] TO [public]
GO
GRANT DELETE ON  [dbo].[cons_inv] TO [public]
GO
GRANT UPDATE ON  [dbo].[cons_inv] TO [public]
GO
