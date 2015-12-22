CREATE TABLE [dbo].[dmco]
(
[timestamp] [timestamp] NOT NULL,
[company_id] [smallint] NOT NULL,
[loc_security_flag] [smallint] NOT NULL,
[create_po_dflt_ind] [smallint] NOT NULL,
[use_po_dflt_ind] [smallint] NOT NULL,
[create_so_dflt_ind] [smallint] NOT NULL,
[use_so_dflt_ind] [smallint] NOT NULL,
[use_xfr_dflt_ind] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [dmco_ind_0] ON [dbo].[dmco] ([company_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[dmco] TO [public]
GO
GRANT SELECT ON  [dbo].[dmco] TO [public]
GO
GRANT INSERT ON  [dbo].[dmco] TO [public]
GO
GRANT DELETE ON  [dbo].[dmco] TO [public]
GO
GRANT UPDATE ON  [dbo].[dmco] TO [public]
GO
