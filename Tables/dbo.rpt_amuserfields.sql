CREATE TABLE [dbo].[rpt_amuserfields]
(
[asset_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[asset_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_code_1_title] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_code_1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_code_2_title] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_code_2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_code_3_title] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_code_3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_code_4_title] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_code_4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_code_5_title] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_code_5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_date_1_title] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_date_1] [datetime] NULL,
[user_date_2_title] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_date_2] [datetime] NULL,
[user_date_3_title] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_date_3] [datetime] NULL,
[user_date_4_title] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_date_4] [datetime] NULL,
[user_date_5_title] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_date_5] [datetime] NULL,
[user_amount_1_title] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_amount_1] [float] NULL,
[user_amount_2_title] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_amount_2] [float] NULL,
[user_amount_3_title] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_amount_3] [float] NULL,
[user_amount_4_title] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_amount_4] [float] NULL,
[user_amount_5_title] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_amount_5] [float] NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_amuserfields] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_amuserfields] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_amuserfields] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_amuserfields] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_amuserfields] TO [public]
GO
