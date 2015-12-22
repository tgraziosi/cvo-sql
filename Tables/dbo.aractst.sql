CREATE TABLE [dbo].[aractst]
(
[timestamp] [timestamp] NOT NULL,
[proc_key] [int] NOT NULL,
[posting_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[inactive_flag] [smallint] NOT NULL,
[invalid_flag] [smallint] NOT NULL,
[date] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [aractst_ind_0] ON [dbo].[aractst] ([proc_key], [account_code], [date]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [aractst_ind_1] ON [dbo].[aractst] ([proc_key], [posting_code], [account_code], [date]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [aractst_ind_2] ON [dbo].[aractst] ([proc_key], [posting_code], [date]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[aractst] TO [public]
GO
GRANT SELECT ON  [dbo].[aractst] TO [public]
GO
GRANT INSERT ON  [dbo].[aractst] TO [public]
GO
GRANT DELETE ON  [dbo].[aractst] TO [public]
GO
GRANT UPDATE ON  [dbo].[aractst] TO [public]
GO
