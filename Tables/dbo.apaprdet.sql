CREATE TABLE [dbo].[apaprdet]
(
[timestamp] [timestamp] NOT NULL,
[approval_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[amt_min] [float] NOT NULL,
[amt_max] [float] NOT NULL,
[user_id] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [apaprdet_ind_0] ON [dbo].[apaprdet] ([approval_code], [sequence_id]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [apaprdet_ind_1] ON [dbo].[apaprdet] ([approval_code], [user_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apaprdet] TO [public]
GO
GRANT SELECT ON  [dbo].[apaprdet] TO [public]
GO
GRANT INSERT ON  [dbo].[apaprdet] TO [public]
GO
GRANT DELETE ON  [dbo].[apaprdet] TO [public]
GO
GRANT UPDATE ON  [dbo].[apaprdet] TO [public]
GO
