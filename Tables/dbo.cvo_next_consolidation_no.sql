CREATE TABLE [dbo].[cvo_next_consolidation_no]
(
[timestamp] [timestamp] NOT NULL,
[last_no] [int] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_next_consolidation_no] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_next_consolidation_no] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_next_consolidation_no] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_next_consolidation_no] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_next_consolidation_no] TO [public]
GO
