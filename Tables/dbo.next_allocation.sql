CREATE TABLE [dbo].[next_allocation]
(
[timestamp] [timestamp] NOT NULL,
[alloc_seq_id] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [pk_next_allocation] ON [dbo].[next_allocation] ([alloc_seq_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[next_allocation] TO [public]
GO
GRANT SELECT ON  [dbo].[next_allocation] TO [public]
GO
GRANT INSERT ON  [dbo].[next_allocation] TO [public]
GO
GRANT DELETE ON  [dbo].[next_allocation] TO [public]
GO
GRANT UPDATE ON  [dbo].[next_allocation] TO [public]
GO
