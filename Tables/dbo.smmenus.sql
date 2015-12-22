CREATE TABLE [dbo].[smmenus]
(
[timestamp] [timestamp] NOT NULL,
[app_id] [smallint] NOT NULL,
[form_id] [int] NOT NULL,
[object_type] [smallint] NOT NULL,
[form_subid] [smallint] NOT NULL,
[form_desc] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [smmenus_ind_0] ON [dbo].[smmenus] ([app_id], [form_id], [object_type]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[smmenus] TO [public]
GO
GRANT SELECT ON  [dbo].[smmenus] TO [public]
GO
GRANT INSERT ON  [dbo].[smmenus] TO [public]
GO
GRANT DELETE ON  [dbo].[smmenus] TO [public]
GO
GRANT UPDATE ON  [dbo].[smmenus] TO [public]
GO
