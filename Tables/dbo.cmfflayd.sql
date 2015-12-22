CREATE TABLE [dbo].[cmfflayd]
(
[timestamp] [timestamp] NOT NULL,
[bank_file_id] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[field] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[offset] [smallint] NOT NULL,
[length] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [cmfflayd_ind_0] ON [dbo].[cmfflayd] ([bank_file_id], [sequence_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cmfflayd] TO [public]
GO
GRANT SELECT ON  [dbo].[cmfflayd] TO [public]
GO
GRANT INSERT ON  [dbo].[cmfflayd] TO [public]
GO
GRANT DELETE ON  [dbo].[cmfflayd] TO [public]
GO
GRANT UPDATE ON  [dbo].[cmfflayd] TO [public]
GO
