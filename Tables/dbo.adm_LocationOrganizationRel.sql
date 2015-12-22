CREATE TABLE [dbo].[adm_LocationOrganizationRel]
(
[timestamp] [timestamp] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[related_org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[type_cd] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[create_ind] [int] NOT NULL,
[use_ind] [int] NOT NULL,
[row_id] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[adm_LocationOrganizationRel] ADD CONSTRAINT [CK_adm_LocationOrganizationRel_type_cd] CHECK (([type_cd]='X' OR [type_cd]='S' OR [type_cd]='P' OR [type_cd]='I'))
GO
CREATE UNIQUE NONCLUSTERED INDEX [LocationOrganizationRel1] ON [dbo].[adm_LocationOrganizationRel] ([location], [related_org_id], [type_cd]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [LocationOrganizationRel2] ON [dbo].[adm_LocationOrganizationRel] ([row_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[adm_LocationOrganizationRel] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_LocationOrganizationRel] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_LocationOrganizationRel] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_LocationOrganizationRel] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_LocationOrganizationRel] TO [public]
GO
