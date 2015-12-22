CREATE TABLE [dbo].[imfields]
(
[system_defined] [dbo].[smLogicalFalse] NOT NULL,
[field_id] [int] NOT NULL,
[field_name] [varchar] (31) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[field_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[field_type] [smallint] NOT NULL,
[field_length] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [imfields_ind_0] ON [dbo].[imfields] ([field_id]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[imfields].[system_defined]'
GO
EXEC sp_bindefault N'[dbo].[smFalse_df]', N'[dbo].[imfields].[system_defined]'
GO
GRANT REFERENCES ON  [dbo].[imfields] TO [public]
GO
GRANT SELECT ON  [dbo].[imfields] TO [public]
GO
GRANT INSERT ON  [dbo].[imfields] TO [public]
GO
GRANT DELETE ON  [dbo].[imfields] TO [public]
GO
GRANT UPDATE ON  [dbo].[imfields] TO [public]
GO
