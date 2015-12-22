CREATE TABLE [dbo].[apclilst]
(
[timestamp] [timestamp] NOT NULL,
[client_id] [char] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[e_code] [int] NULL,
[generic_col] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[generic_col_def] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [apclilst_ind_0] ON [dbo].[apclilst] ([client_id], [e_code], [generic_col]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apclilst] TO [public]
GO
GRANT SELECT ON  [dbo].[apclilst] TO [public]
GO
GRANT INSERT ON  [dbo].[apclilst] TO [public]
GO
GRANT DELETE ON  [dbo].[apclilst] TO [public]
GO
GRANT UPDATE ON  [dbo].[apclilst] TO [public]
GO
