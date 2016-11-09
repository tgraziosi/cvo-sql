CREATE TABLE [dbo].[cvo_alternate_attributes]
(
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[attribute_key] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[attributes] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_alternate_attributes_ind1] ON [dbo].[cvo_alternate_attributes] ([attribute_key]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_alternate_attributes_ind0] ON [dbo].[cvo_alternate_attributes] ([part_no]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[cvo_alternate_attributes] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_alternate_attributes] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_alternate_attributes] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_alternate_attributes] TO [public]
GO
