CREATE TABLE [dbo].[adm_custom_obj_info]
(
[timestamp] [timestamp] NOT NULL,
[obj_grp] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[obj_type] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[attrib_grp] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[attrib_sub_type] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[attrib_nm] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[attrib_descr] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[attrib_typ] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[attrib_dflt] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[seq_id] [int] NOT NULL IDENTITY(1, 1),
[attrib_values] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[attrib_dddw_info] [varchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[computable] [int] NULL,
[style_attrib] [int] NULL,
[enable_if_tx] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[adm_custom_obj_info] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_custom_obj_info] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_custom_obj_info] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_custom_obj_info] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_custom_obj_info] TO [public]
GO
