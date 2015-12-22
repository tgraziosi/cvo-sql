CREATE TABLE [dbo].[pbatch]
(
[timestamp] [timestamp] NOT NULL,
[process_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[batch_ctrl_num] [char] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[start_number] [int] NOT NULL,
[start_total] [float] NOT NULL,
[end_number] [int] NOT NULL,
[end_total] [float] NOT NULL,
[start_time] [datetime] NOT NULL,
[end_time] [datetime] NULL,
[flag] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [pbatch_ind_1] ON [dbo].[pbatch] ([process_ctrl_num], [batch_ctrl_num]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[pbatch] TO [public]
GO
GRANT SELECT ON  [dbo].[pbatch] TO [public]
GO
GRANT INSERT ON  [dbo].[pbatch] TO [public]
GO
GRANT DELETE ON  [dbo].[pbatch] TO [public]
GO
GRANT UPDATE ON  [dbo].[pbatch] TO [public]
GO
