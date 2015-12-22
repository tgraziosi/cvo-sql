CREATE TABLE [dbo].[mod_customers]
(
[timestamp] [timestamp] NOT NULL,
[customer_key] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [modcust1] ON [dbo].[mod_customers] ([customer_key]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[mod_customers] TO [public]
GO
GRANT SELECT ON  [dbo].[mod_customers] TO [public]
GO
GRANT INSERT ON  [dbo].[mod_customers] TO [public]
GO
GRANT DELETE ON  [dbo].[mod_customers] TO [public]
GO
GRANT UPDATE ON  [dbo].[mod_customers] TO [public]
GO
