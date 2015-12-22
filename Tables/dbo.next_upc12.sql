CREATE TABLE [dbo].[next_upc12]
(
[last_no] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [next_upc12_idx] ON [dbo].[next_upc12] ([last_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[next_upc12] TO [public]
GO
GRANT SELECT ON  [dbo].[next_upc12] TO [public]
GO
GRANT INSERT ON  [dbo].[next_upc12] TO [public]
GO
GRANT DELETE ON  [dbo].[next_upc12] TO [public]
GO
GRANT UPDATE ON  [dbo].[next_upc12] TO [public]
GO
