CREATE TABLE [dbo].[nbtrx]
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
[date_posted] [int] NOT NULL,
[user_id] [smallint] NOT NULL,
[process_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[posted_flag] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [nbtrx_ind_0] ON [dbo].[nbtrx] ([net_ctrl_num]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[nbtrx] TO [public]
GO
GRANT SELECT ON  [dbo].[nbtrx] TO [public]
GO
GRANT INSERT ON  [dbo].[nbtrx] TO [public]
GO
GRANT DELETE ON  [dbo].[nbtrx] TO [public]
GO
GRANT UPDATE ON  [dbo].[nbtrx] TO [public]
GO
