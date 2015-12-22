CREATE TABLE [dbo].[aperrlst]
(
[timestamp] [timestamp] NOT NULL,
[seq_id] [int] NOT NULL,
[proc_id] [int] NOT NULL,
[client_id] [char] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[user_id] [int] NOT NULL,
[e_code] [int] NOT NULL,
[time] [datetime] NOT NULL,
[date_entered] [int] NOT NULL,
[filename] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[linenum] [int] NULL,
[char_parm_1] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[char_parm_2] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[int_parm_1] [int] NULL,
[int_parm_2] [int] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [aperrlst_idx_1] ON [dbo].[aperrlst] ([client_id], [e_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[aperrlst] TO [public]
GO
GRANT SELECT ON  [dbo].[aperrlst] TO [public]
GO
GRANT INSERT ON  [dbo].[aperrlst] TO [public]
GO
GRANT DELETE ON  [dbo].[aperrlst] TO [public]
GO
GRANT UPDATE ON  [dbo].[aperrlst] TO [public]
GO
