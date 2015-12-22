CREATE TABLE [dbo].[eft_errlst]
(
[seq_id] [int] NOT NULL,
[client_id] [char] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[user_id] [int] NOT NULL,
[e_code] [int] NOT NULL,
[time] [datetime] NOT NULL,
[char_parm_1] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[char_parm_2] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[e_ldesc] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [eft_errlst_ind_0] ON [dbo].[eft_errlst] ([seq_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[eft_errlst] TO [public]
GO
GRANT SELECT ON  [dbo].[eft_errlst] TO [public]
GO
GRANT INSERT ON  [dbo].[eft_errlst] TO [public]
GO
GRANT DELETE ON  [dbo].[eft_errlst] TO [public]
GO
GRANT UPDATE ON  [dbo].[eft_errlst] TO [public]
GO
