CREATE TABLE [dbo].[apchkdat]
(
[timestamp] [timestamp] NOT NULL,
[variable_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[x_coordinate] [float] NOT NULL,
[y_coordinate] [float] NOT NULL,
[display] [smallint] NOT NULL,
[group_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[x_default] [float] NOT NULL,
[y_default] [float] NOT NULL,
[display_default] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [apchkdat_ind_0] ON [dbo].[apchkdat] ([sequence_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apchkdat] TO [public]
GO
GRANT SELECT ON  [dbo].[apchkdat] TO [public]
GO
GRANT INSERT ON  [dbo].[apchkdat] TO [public]
GO
GRANT DELETE ON  [dbo].[apchkdat] TO [public]
GO
GRANT UPDATE ON  [dbo].[apchkdat] TO [public]
GO
