CREATE TABLE [dbo].[glclilst]
(
[timestamp] [timestamp] NOT NULL,
[client_id] [char] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[e_code] [int] NULL,
[generic_col] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[generic_col_def] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [glclilst_ind_0] ON [dbo].[glclilst] ([client_id], [e_code], [generic_col]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[glclilst] TO [public]
GO
GRANT SELECT ON  [dbo].[glclilst] TO [public]
GO
GRANT INSERT ON  [dbo].[glclilst] TO [public]
GO
GRANT DELETE ON  [dbo].[glclilst] TO [public]
GO
GRANT UPDATE ON  [dbo].[glclilst] TO [public]
GO
