CREATE TABLE [dbo].[glcondet]
(
[timestamp] [timestamp] NOT NULL,
[consol_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[journal_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[subs_id] [smallint] NOT NULL,
[subs_period_end_date] [int] NOT NULL,
[work_flag] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [glcondet_ind_0] ON [dbo].[glcondet] ([consol_ctrl_num], [sequence_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[glcondet] TO [public]
GO
GRANT SELECT ON  [dbo].[glcondet] TO [public]
GO
GRANT INSERT ON  [dbo].[glcondet] TO [public]
GO
GRANT DELETE ON  [dbo].[glcondet] TO [public]
GO
GRANT UPDATE ON  [dbo].[glcondet] TO [public]
GO
