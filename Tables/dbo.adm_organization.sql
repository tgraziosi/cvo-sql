CREATE TABLE [dbo].[adm_organization]
(
[timestamp] [timestamp] NOT NULL,
[organization_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[io_use_po_ind] [smallint] NOT NULL,
[io_use_so_ind] [smallint] NOT NULL,
[io_use_xfer_ind] [smallint] NOT NULL,
[io_create_po_ind] [smallint] NOT NULL,
[io_create_so_ind] [smallint] NOT NULL,
[use_ext_vend_ind] [smallint] NOT NULL,
[use_ext_cust_ind] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [dmco_ind_0] ON [dbo].[adm_organization] ([organization_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[adm_organization] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_organization] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_organization] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_organization] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_organization] TO [public]
GO
