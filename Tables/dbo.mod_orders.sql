CREATE TABLE [dbo].[mod_orders]
(
[timestamp] [timestamp] NOT NULL,
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [modord1] ON [dbo].[mod_orders] ([order_no], [order_ext]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[mod_orders] TO [public]
GO
GRANT SELECT ON  [dbo].[mod_orders] TO [public]
GO
GRANT INSERT ON  [dbo].[mod_orders] TO [public]
GO
GRANT DELETE ON  [dbo].[mod_orders] TO [public]
GO
GRANT UPDATE ON  [dbo].[mod_orders] TO [public]
GO
