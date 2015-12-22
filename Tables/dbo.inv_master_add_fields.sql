CREATE TABLE [dbo].[inv_master_add_fields]
(
[timestamp] [timestamp] NOT NULL,
[field_name] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[field_title] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[field_text] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[enabled] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [_WA_Sys_field_name_1F3E4F6F] ON [dbo].[inv_master_add_fields] ([field_name]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[inv_master_add_fields] TO [public]
GO
GRANT SELECT ON  [dbo].[inv_master_add_fields] TO [public]
GO
GRANT INSERT ON  [dbo].[inv_master_add_fields] TO [public]
GO
GRANT DELETE ON  [dbo].[inv_master_add_fields] TO [public]
GO
GRANT UPDATE ON  [dbo].[inv_master_add_fields] TO [public]
GO
