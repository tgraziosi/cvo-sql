CREATE TABLE [dbo].[next_new_cost]
(
[timestamp] [timestamp] NOT NULL,
[last_no] [int] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[next_new_cost] TO [public]
GO
GRANT SELECT ON  [dbo].[next_new_cost] TO [public]
GO
GRANT INSERT ON  [dbo].[next_new_cost] TO [public]
GO
GRANT DELETE ON  [dbo].[next_new_cost] TO [public]
GO
GRANT UPDATE ON  [dbo].[next_new_cost] TO [public]
GO
