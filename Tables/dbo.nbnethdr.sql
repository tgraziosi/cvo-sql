CREATE TABLE [dbo].[nbnethdr]
(
[timestamp] [timestamp] NOT NULL,
[net_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[currency_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[payment_flag] [smallint] NOT NULL,
[amt_payment] [float] NOT NULL,
[module_id] [int] NOT NULL,
[date_entered] [int] NOT NULL,
[user_id] [smallint] NOT NULL,
[posted_flag] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [nbnethdr_ind_0] ON [dbo].[nbnethdr] ([net_ctrl_num]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[nbnethdr] TO [public]
GO
GRANT SELECT ON  [dbo].[nbnethdr] TO [public]
GO
GRANT INSERT ON  [dbo].[nbnethdr] TO [public]
GO
GRANT DELETE ON  [dbo].[nbnethdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[nbnethdr] TO [public]
GO
