CREATE TABLE [dbo].[ep_temp_glref]
(
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reference_type] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[status_flag] [smallint] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[ep_temp_glref] TO [public]
GO
GRANT SELECT ON  [dbo].[ep_temp_glref] TO [public]
GO
GRANT INSERT ON  [dbo].[ep_temp_glref] TO [public]
GO
GRANT DELETE ON  [dbo].[ep_temp_glref] TO [public]
GO
GRANT UPDATE ON  [dbo].[ep_temp_glref] TO [public]
GO
