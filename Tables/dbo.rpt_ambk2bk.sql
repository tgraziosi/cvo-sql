CREATE TABLE [dbo].[rpt_ambk2bk]
(
[report_group] [tinyint] NULL,
[classification_code] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[report_subgroup] [tinyint] NULL,
[asset_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[co_asset_id] [int] NULL,
[asset_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type_flag] [tinyint] NULL,
[account_type] [tinyint] NULL,
[book_value1] [float] NULL,
[book_value2] [float] NULL,
[difference] [float] NULL,
[account_desc] [char] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_ambk2bk] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_ambk2bk] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_ambk2bk] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_ambk2bk] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_ambk2bk] TO [public]
GO
