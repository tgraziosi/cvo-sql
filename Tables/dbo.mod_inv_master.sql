CREATE TABLE [dbo].[mod_inv_master]
(
[timestamp] [timestamp] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [modinvm1] ON [dbo].[mod_inv_master] ([part_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[mod_inv_master] TO [public]
GO
GRANT SELECT ON  [dbo].[mod_inv_master] TO [public]
GO
GRANT INSERT ON  [dbo].[mod_inv_master] TO [public]
GO
GRANT DELETE ON  [dbo].[mod_inv_master] TO [public]
GO
GRANT UPDATE ON  [dbo].[mod_inv_master] TO [public]
GO
