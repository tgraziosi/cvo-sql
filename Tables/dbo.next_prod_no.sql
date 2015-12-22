CREATE TABLE [dbo].[next_prod_no]
(
[timestamp] [timestamp] NOT NULL,
[last_no] [int] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[next_prod_no] TO [public]
GO
GRANT SELECT ON  [dbo].[next_prod_no] TO [public]
GO
GRANT INSERT ON  [dbo].[next_prod_no] TO [public]
GO
GRANT DELETE ON  [dbo].[next_prod_no] TO [public]
GO
GRANT UPDATE ON  [dbo].[next_prod_no] TO [public]
GO
