CREATE TABLE [dbo].[smgrouptype]
(
[timestamp] [timestamp] NOT NULL,
[type] [smallint] NOT NULL,
[description] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[smgrouptype] TO [public]
GO
GRANT SELECT ON  [dbo].[smgrouptype] TO [public]
GO
GRANT INSERT ON  [dbo].[smgrouptype] TO [public]
GO
GRANT DELETE ON  [dbo].[smgrouptype] TO [public]
GO
GRANT UPDATE ON  [dbo].[smgrouptype] TO [public]
GO
