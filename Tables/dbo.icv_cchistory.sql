CREATE TABLE [dbo].[icv_cchistory]
(
[entry_date] [datetime] NOT NULL,
[entry_type] [smallint] NOT NULL,
[response] [char] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_ctrl_num] [char] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[uname] [char] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account] [char] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ccmonth] [int] NOT NULL,
[ccyear] [int] NOT NULL,
[amount] [float] NOT NULL,
[trx_type] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[authorization_code] [char] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[icv_cchistory] TO [public]
GO
GRANT SELECT ON  [dbo].[icv_cchistory] TO [public]
GO
GRANT INSERT ON  [dbo].[icv_cchistory] TO [public]
GO
GRANT DELETE ON  [dbo].[icv_cchistory] TO [public]
GO
GRANT UPDATE ON  [dbo].[icv_cchistory] TO [public]
GO
