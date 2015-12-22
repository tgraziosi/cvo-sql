CREATE TABLE [dbo].[arcent]
(
[timestamp] [timestamp] NOT NULL,
[cents_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cents_code_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [arcent_ind_0] ON [dbo].[arcent] ([cents_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arcent] TO [public]
GO
GRANT SELECT ON  [dbo].[arcent] TO [public]
GO
GRANT INSERT ON  [dbo].[arcent] TO [public]
GO
GRANT DELETE ON  [dbo].[arcent] TO [public]
GO
GRANT UPDATE ON  [dbo].[arcent] TO [public]
GO
