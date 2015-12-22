CREATE TABLE [dbo].[imaction]
(
[system_defined] [dbo].[smLogicalFalse] NOT NULL,
[file_type] [smallint] NOT NULL,
[action] [smallint] NOT NULL,
[field_id] [int] NOT NULL,
[file_order] [smallint] NOT NULL,
[field_default_is_null] [tinyint] NOT NULL,
[field_default] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[update_allowed] [tinyint] NOT NULL,
[required_field] [tinyint] NOT NULL,
[nulls_allowed] [tinyint] NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [imaction_ind_0] ON [dbo].[imaction] ([file_type], [action]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[imaction].[system_defined]'
GO
EXEC sp_bindefault N'[dbo].[smFalse_df]', N'[dbo].[imaction].[system_defined]'
GO
GRANT REFERENCES ON  [dbo].[imaction] TO [public]
GO
GRANT SELECT ON  [dbo].[imaction] TO [public]
GO
GRANT INSERT ON  [dbo].[imaction] TO [public]
GO
GRANT DELETE ON  [dbo].[imaction] TO [public]
GO
GRANT UPDATE ON  [dbo].[imaction] TO [public]
GO
