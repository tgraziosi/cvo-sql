CREATE TABLE [dbo].[ewnumber]
(
[timestamp] [timestamp] NULL,
[company_id] [smallint] NOT NULL,
[company_code] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[num_type] [int] NOT NULL,
[sequence_id] [int] NOT NULL,
[next_num] [int] NOT NULL,
[mask] [char] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[del_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [char] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[fill1] [char] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[fill2] [char] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[fill3] [char] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[fill4] [char] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ewnumber_ind_1] ON [dbo].[ewnumber] ([mask]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [ewnumber_ind_0] ON [dbo].[ewnumber] ([num_type]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[ewnumber] TO [public]
GO
GRANT SELECT ON  [dbo].[ewnumber] TO [public]
GO
GRANT INSERT ON  [dbo].[ewnumber] TO [public]
GO
GRANT DELETE ON  [dbo].[ewnumber] TO [public]
GO
GRANT UPDATE ON  [dbo].[ewnumber] TO [public]
GO
