CREATE TABLE [dbo].[next_rec_batch_no]
(
[timestamp] [timestamp] NOT NULL,
[last_number] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [next_rec_batch_no_idx] ON [dbo].[next_rec_batch_no] ([last_number]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[next_rec_batch_no] TO [public]
GO
GRANT SELECT ON  [dbo].[next_rec_batch_no] TO [public]
GO
GRANT INSERT ON  [dbo].[next_rec_batch_no] TO [public]
GO
GRANT DELETE ON  [dbo].[next_rec_batch_no] TO [public]
GO
GRANT UPDATE ON  [dbo].[next_rec_batch_no] TO [public]
GO
