CREATE TABLE [dbo].[arcomadj]
(
[timestamp] [timestamp] NOT NULL,
[salesperson_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[date_effective] [int] NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[adj_base_amt] [float] NOT NULL,
[adj_override_amt] [float] NOT NULL,
[posted_flag] [smallint] NOT NULL,
[user_id] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [arcomadj_ind_2] ON [dbo].[arcomadj] ([posted_flag]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [arcomadj_ind_1] ON [dbo].[arcomadj] ([salesperson_code], [date_effective]) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [arcomadj_ind_0] ON [dbo].[arcomadj] ([salesperson_code], [sequence_id], [date_effective]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arcomadj] TO [public]
GO
GRANT SELECT ON  [dbo].[arcomadj] TO [public]
GO
GRANT INSERT ON  [dbo].[arcomadj] TO [public]
GO
GRANT DELETE ON  [dbo].[arcomadj] TO [public]
GO
GRANT UPDATE ON  [dbo].[arcomadj] TO [public]
GO
