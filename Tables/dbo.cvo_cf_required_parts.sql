CREATE TABLE [dbo].[cvo_cf_required_parts]
(
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_type] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty] [decimal] (20, 8) NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_cf_required_parts_ind0] ON [dbo].[cvo_cf_required_parts] ([part_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_cf_required_parts_cf_ind0] ON [dbo].[cvo_cf_required_parts] ([part_type], [part_no]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[cvo_cf_required_parts] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_cf_required_parts] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_cf_required_parts] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_cf_required_parts] TO [public]
GO
