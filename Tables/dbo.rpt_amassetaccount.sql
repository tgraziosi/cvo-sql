CREATE TABLE [dbo].[rpt_amassetaccount]
(
[asset_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[asset_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[account_reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[account_type_id] [smallint] NULL,
[original_account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[new_account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[error_message] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[account_type_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[display_order] [int] NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_amassetaccount] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_amassetaccount] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_amassetaccount] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_amassetaccount] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_amassetaccount] TO [public]
GO
