CREATE TABLE [dbo].[adm_localization]
(
[timestamp] [timestamp] NOT NULL,
[lang_id] [int] NOT NULL,
[rcd_level] [int] NOT NULL,
[window_nm] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[object_nm] [varchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[object_typ] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[attrib_typ] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[attrib_nm] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[orig_stringid] [uniqueidentifier] NULL,
[stringid] [uniqueidentifier] NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [adm_localization_3] ON [dbo].[adm_localization] ([lang_id], [orig_stringid], [attrib_typ]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [adm_localization_2] ON [dbo].[adm_localization] ([lang_id], [orig_stringid], [rcd_level]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [adm_localization_1] ON [dbo].[adm_localization] ([lang_id], [rcd_level], [window_nm], [object_nm], [stringid]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[adm_localization] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_localization] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_localization] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_localization] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_localization] TO [public]
GO
