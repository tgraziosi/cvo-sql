CREATE TABLE [dbo].[glcon]
(
[timestamp] [timestamp] NOT NULL,
[consol_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_asof] [int] NOT NULL,
[date_entered] [int] NOT NULL,
[status_type] [smallint] NOT NULL,
[direct_post_flag] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [glcon_ind_0] ON [dbo].[glcon] ([consol_ctrl_num]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[glcon] TO [public]
GO
GRANT SELECT ON  [dbo].[glcon] TO [public]
GO
GRANT INSERT ON  [dbo].[glcon] TO [public]
GO
GRANT DELETE ON  [dbo].[glcon] TO [public]
GO
GRANT UPDATE ON  [dbo].[glcon] TO [public]
GO
