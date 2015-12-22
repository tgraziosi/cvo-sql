CREATE TABLE [dbo].[icv_events]
(
[cca_trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_code] [varchar] (18) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[payment_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cc_number] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_requested] [datetime] NOT NULL,
[trx_requested] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amount] [float] NOT NULL,
[currency_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[auth_code] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pttd_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[user_id] [smallint] NOT NULL,
[response_code] [int] NOT NULL,
[orig_no] [int] NOT NULL,
[reference] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[julian_date] [int] NOT NULL,
[provider] [smallint] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[icv_events] TO [public]
GO
GRANT SELECT ON  [dbo].[icv_events] TO [public]
GO
GRANT INSERT ON  [dbo].[icv_events] TO [public]
GO
GRANT DELETE ON  [dbo].[icv_events] TO [public]
GO
GRANT UPDATE ON  [dbo].[icv_events] TO [public]
GO
