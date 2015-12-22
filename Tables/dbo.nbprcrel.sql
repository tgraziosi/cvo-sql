CREATE TABLE [dbo].[nbprcrel]
(
[timestamp] [timestamp] NOT NULL,
[process_ctrl_parent] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[process_ctrl_child] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [nbprcrel_ind_0] ON [dbo].[nbprcrel] ([process_ctrl_parent], [process_ctrl_child]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[nbprcrel] TO [public]
GO
GRANT SELECT ON  [dbo].[nbprcrel] TO [public]
GO
GRANT INSERT ON  [dbo].[nbprcrel] TO [public]
GO
GRANT DELETE ON  [dbo].[nbprcrel] TO [public]
GO
GRANT UPDATE ON  [dbo].[nbprcrel] TO [public]
GO
