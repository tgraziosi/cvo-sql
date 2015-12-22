CREATE TABLE [dbo].[CVO_transfer_return_autoship]
(
[xfer_no] [int] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [CVO_transfer_return_autoship_pk] ON [dbo].[CVO_transfer_return_autoship] ([xfer_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[CVO_transfer_return_autoship] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_transfer_return_autoship] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_transfer_return_autoship] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_transfer_return_autoship] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_transfer_return_autoship] TO [public]
GO
