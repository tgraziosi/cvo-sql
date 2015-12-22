CREATE TABLE [dbo].[arcomdet]
(
[timestamp] [timestamp] NOT NULL,
[sequence_id] [int] NOT NULL,
[commission_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[from_bracket] [float] NOT NULL,
[to_bracket] [float] NOT NULL,
[commission_amt] [float] NOT NULL,
[percent_flag] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [arcomdet_ind_0] ON [dbo].[arcomdet] ([commission_code], [sequence_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arcomdet] TO [public]
GO
GRANT SELECT ON  [dbo].[arcomdet] TO [public]
GO
GRANT INSERT ON  [dbo].[arcomdet] TO [public]
GO
GRANT DELETE ON  [dbo].[arcomdet] TO [public]
GO
GRANT UPDATE ON  [dbo].[arcomdet] TO [public]
GO
