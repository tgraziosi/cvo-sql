CREATE TABLE [dbo].[mod_inv_list]
(
[timestamp] [timestamp] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [modinvl1] ON [dbo].[mod_inv_list] ([part_no], [location]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[mod_inv_list] TO [public]
GO
GRANT SELECT ON  [dbo].[mod_inv_list] TO [public]
GO
GRANT INSERT ON  [dbo].[mod_inv_list] TO [public]
GO
GRANT DELETE ON  [dbo].[mod_inv_list] TO [public]
GO
GRANT UPDATE ON  [dbo].[mod_inv_list] TO [public]
GO
