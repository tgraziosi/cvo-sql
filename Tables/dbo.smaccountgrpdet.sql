CREATE TABLE [dbo].[smaccountgrpdet]
(
[timestamp] [timestamp] NOT NULL,
[group_id] [smallint] NOT NULL,
[account_mask] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [smaccountgrpdet_ind_1] ON [dbo].[smaccountgrpdet] ([group_id], [account_mask]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [smaccountgrpdet_ind_0] ON [dbo].[smaccountgrpdet] ([group_id], [sequence_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[smaccountgrpdet] TO [public]
GO
GRANT SELECT ON  [dbo].[smaccountgrpdet] TO [public]
GO
GRANT INSERT ON  [dbo].[smaccountgrpdet] TO [public]
GO
GRANT DELETE ON  [dbo].[smaccountgrpdet] TO [public]
GO
GRANT UPDATE ON  [dbo].[smaccountgrpdet] TO [public]
GO
