CREATE TABLE [dbo].[inv_substitutes]
(
[timestamp] [timestamp] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_key] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sub_part] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[priority] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [invsub1] ON [dbo].[inv_substitutes] ([part_no], [customer_key], [sub_part]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[inv_substitutes] TO [public]
GO
GRANT SELECT ON  [dbo].[inv_substitutes] TO [public]
GO
GRANT INSERT ON  [dbo].[inv_substitutes] TO [public]
GO
GRANT DELETE ON  [dbo].[inv_substitutes] TO [public]
GO
GRANT UPDATE ON  [dbo].[inv_substitutes] TO [public]
GO
