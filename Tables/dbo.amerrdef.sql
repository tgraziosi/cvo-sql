CREATE TABLE [dbo].[amerrdef]
(
[timestamp] [timestamp] NOT NULL,
[client_id] [dbo].[smClientID] NOT NULL,
[e_code] [dbo].[smErrorCode] NOT NULL,
[e_level] [dbo].[smErrorLevel] NOT NULL,
[e_active] [dbo].[smErrorActive] NOT NULL,
[e_sdesc] [dbo].[smErrorShortDesc] NOT NULL,
[e_ldesc] [dbo].[smErrorLongDesc] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [amerrdef_ind_0] ON [dbo].[amerrdef] ([e_code]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[smErrorLevel_rl]', N'[dbo].[amerrdef].[e_level]'
GO
EXEC sp_bindefault N'[dbo].[smErrorLevel_df]', N'[dbo].[amerrdef].[e_level]'
GO
EXEC sp_bindrule N'[dbo].[smErrorActive_rl]', N'[dbo].[amerrdef].[e_active]'
GO
EXEC sp_bindefault N'[dbo].[smTrue_df]', N'[dbo].[amerrdef].[e_active]'
GO
GRANT REFERENCES ON  [dbo].[amerrdef] TO [public]
GO
GRANT SELECT ON  [dbo].[amerrdef] TO [public]
GO
GRANT INSERT ON  [dbo].[amerrdef] TO [public]
GO
GRANT DELETE ON  [dbo].[amerrdef] TO [public]
GO
GRANT UPDATE ON  [dbo].[amerrdef] TO [public]
GO
