CREATE TABLE [dbo].[agents]
(
[timestamp] [timestamp] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[agent_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seq_no] [int] NOT NULL,
[agent_verb] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[agent_obj] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[row_id] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [agent1] ON [dbo].[agents] ([part_no], [agent_type], [seq_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[agents] TO [public]
GO
GRANT SELECT ON  [dbo].[agents] TO [public]
GO
GRANT INSERT ON  [dbo].[agents] TO [public]
GO
GRANT DELETE ON  [dbo].[agents] TO [public]
GO
GRANT UPDATE ON  [dbo].[agents] TO [public]
GO
