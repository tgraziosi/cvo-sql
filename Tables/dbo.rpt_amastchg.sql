CREATE TABLE [dbo].[rpt_amastchg]
(
[asset_ctrl_num] [char] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[asset_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[field_type] [int] NOT NULL,
[apply_date] [datetime] NOT NULL,
[apply_date_jul] [int] NOT NULL,
[old_value] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[new_value] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[user_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[classification_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_amastchg] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_amastchg] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_amastchg] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_amastchg] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_amastchg] TO [public]
GO
