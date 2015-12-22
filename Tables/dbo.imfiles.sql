CREATE TABLE [dbo].[imfiles]
(
[system_defined] [dbo].[smLogicalFalse] NOT NULL,
[file_type] [smallint] NOT NULL,
[type_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[short_name] [char] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [imfiles_ind_0] ON [dbo].[imfiles] ([file_type]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[imfiles].[system_defined]'
GO
EXEC sp_bindefault N'[dbo].[smFalse_df]', N'[dbo].[imfiles].[system_defined]'
GO
GRANT REFERENCES ON  [dbo].[imfiles] TO [public]
GO
GRANT SELECT ON  [dbo].[imfiles] TO [public]
GO
GRANT INSERT ON  [dbo].[imfiles] TO [public]
GO
GRANT DELETE ON  [dbo].[imfiles] TO [public]
GO
GRANT UPDATE ON  [dbo].[imfiles] TO [public]
GO
