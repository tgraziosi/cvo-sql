CREATE TABLE [dbo].[next_new_price]
(
[timestamp] [timestamp] NOT NULL,
[last_no] [int] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[next_new_price] TO [public]
GO
GRANT SELECT ON  [dbo].[next_new_price] TO [public]
GO
GRANT INSERT ON  [dbo].[next_new_price] TO [public]
GO
GRANT DELETE ON  [dbo].[next_new_price] TO [public]
GO
GRANT UPDATE ON  [dbo].[next_new_price] TO [public]
GO
