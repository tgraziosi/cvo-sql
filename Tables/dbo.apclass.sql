CREATE TABLE [dbo].[apclass]
(
[timestamp] [timestamp] NOT NULL,
[class_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [apclass_ind_0] ON [dbo].[apclass] ([class_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apclass] TO [public]
GO
GRANT SELECT ON  [dbo].[apclass] TO [public]
GO
GRANT INSERT ON  [dbo].[apclass] TO [public]
GO
GRANT DELETE ON  [dbo].[apclass] TO [public]
GO
GRANT UPDATE ON  [dbo].[apclass] TO [public]
GO
