CREATE TABLE [dbo].[sys_status_code]
(
[timestamp] [timestamp] NOT NULL,
[status_code] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status_desc] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Aplication] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[sys_status_code] TO [public]
GO
GRANT SELECT ON  [dbo].[sys_status_code] TO [public]
GO
GRANT INSERT ON  [dbo].[sys_status_code] TO [public]
GO
GRANT DELETE ON  [dbo].[sys_status_code] TO [public]
GO
GRANT UPDATE ON  [dbo].[sys_status_code] TO [public]
GO
