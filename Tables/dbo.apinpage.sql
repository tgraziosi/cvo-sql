CREATE TABLE [dbo].[apinpage]
(
[timestamp] [timestamp] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[sequence_id] [int] NOT NULL,
[date_applied] [int] NOT NULL,
[date_due] [int] NOT NULL,
[date_aging] [int] NOT NULL,
[amt_due] [float] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [apinpage_ind_0] ON [dbo].[apinpage] ([trx_ctrl_num], [trx_type], [date_aging]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apinpage] TO [public]
GO
GRANT SELECT ON  [dbo].[apinpage] TO [public]
GO
GRANT INSERT ON  [dbo].[apinpage] TO [public]
GO
GRANT DELETE ON  [dbo].[apinpage] TO [public]
GO
GRANT UPDATE ON  [dbo].[apinpage] TO [public]
GO
