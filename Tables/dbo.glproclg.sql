CREATE TABLE [dbo].[glproclg]
(
[timestamp] [timestamp] NOT NULL,
[kp_id] [int] NOT NULL,
[user_id] [smallint] NOT NULL,
[client_id] [smallint] NOT NULL,
[ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[time] [datetime] NOT NULL,
[date_entered] [int] NOT NULL,
[document_1] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[document_2] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[char_parm_1] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[char_parm_2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[char_parm_3] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[float_parm_1] [float] NULL,
[float_parm_2] [float] NULL,
[float_parm_3] [float] NULL,
[int_parm_1] [int] NULL,
[int_parm_2] [int] NULL,
[int_parm_3] [int] NULL,
[sint_parm_1] [smallint] NULL,
[sint_parm_2] [smallint] NULL,
[sint_parm_3] [smallint] NULL,
[float_parm_4] [float] NULL,
[float_parm_5] [float] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [glproclg_ind_3] ON [dbo].[glproclg] ([client_id], [user_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [glproclg_ind_4] ON [dbo].[glproclg] ([ctrl_num]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [glproclg_ind_1] ON [dbo].[glproclg] ([document_1]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [glproclg_ind_2] ON [dbo].[glproclg] ([document_2]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [glproclg_ind_0] ON [dbo].[glproclg] ([kp_id], [time]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[glproclg] TO [public]
GO
GRANT SELECT ON  [dbo].[glproclg] TO [public]
GO
GRANT INSERT ON  [dbo].[glproclg] TO [public]
GO
GRANT DELETE ON  [dbo].[glproclg] TO [public]
GO
GRANT UPDATE ON  [dbo].[glproclg] TO [public]
GO
