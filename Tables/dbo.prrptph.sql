CREATE TABLE [dbo].[prrptph]
(
[contract_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[member_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[member_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[member_type] [smallint] NULL,
[void] [int] NOT NULL,
[date_entered] [int] NOT NULL,
[userid] [int] NOT NULL,
[amount_paid_to_date] [float] NULL,
[amount_accrued] [float] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[prrptph] TO [public]
GO
GRANT SELECT ON  [dbo].[prrptph] TO [public]
GO
GRANT INSERT ON  [dbo].[prrptph] TO [public]
GO
GRANT DELETE ON  [dbo].[prrptph] TO [public]
GO
GRANT UPDATE ON  [dbo].[prrptph] TO [public]
GO
