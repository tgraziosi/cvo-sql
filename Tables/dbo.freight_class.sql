CREATE TABLE [dbo].[freight_class]
(
[timestamp] [timestamp] NOT NULL,
[freight_class] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[hm] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[dot] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[void_who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_date] [datetime] NULL,
[void] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [freight_class_pk] ON [dbo].[freight_class] ([freight_class]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[freight_class] TO [public]
GO
GRANT SELECT ON  [dbo].[freight_class] TO [public]
GO
GRANT INSERT ON  [dbo].[freight_class] TO [public]
GO
GRANT DELETE ON  [dbo].[freight_class] TO [public]
GO
GRANT UPDATE ON  [dbo].[freight_class] TO [public]
GO
