CREATE TABLE [dbo].[cvo_part_attributes]
(
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[attribute] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_part_attributes_ind0] ON [dbo].[cvo_part_attributes] ([part_no]) ON [PRIMARY]
GO
GRANT DELETE ON  [dbo].[cvo_part_attributes] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_part_attributes] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_part_attributes] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_part_attributes] TO [public]
GO
