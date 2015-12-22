CREATE TABLE [dbo].[user_def_fields_mgt]
(
[timestamp] [timestamp] NOT NULL,
[tran_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[field_name] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[field_title] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [_WA_Sys_field_name_04AA54C4] ON [dbo].[user_def_fields_mgt] ([field_name]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [_WA_Sys_field_title_04AA54C4] ON [dbo].[user_def_fields_mgt] ([field_title]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [_WA_Sys_tran_type_04AA54C4] ON [dbo].[user_def_fields_mgt] ([tran_type]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[user_def_fields_mgt] TO [public]
GO
GRANT SELECT ON  [dbo].[user_def_fields_mgt] TO [public]
GO
GRANT INSERT ON  [dbo].[user_def_fields_mgt] TO [public]
GO
GRANT DELETE ON  [dbo].[user_def_fields_mgt] TO [public]
GO
GRANT UPDATE ON  [dbo].[user_def_fields_mgt] TO [public]
GO
