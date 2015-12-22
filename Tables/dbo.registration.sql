CREATE TABLE [dbo].[registration]
(
[timestamp] [timestamp] NOT NULL,
[name] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[serial_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reg_key] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[registration] TO [public]
GO
GRANT SELECT ON  [dbo].[registration] TO [public]
GO
GRANT INSERT ON  [dbo].[registration] TO [public]
GO
GRANT DELETE ON  [dbo].[registration] TO [public]
GO
GRANT UPDATE ON  [dbo].[registration] TO [public]
GO
