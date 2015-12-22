CREATE TABLE [dbo].[category_5]
(
[timestamp] [timestamp] NOT NULL,
[category_code] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_entered] [datetime] NULL,
[void] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_date] [datetime] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[category_5] TO [public]
GO
GRANT SELECT ON  [dbo].[category_5] TO [public]
GO
GRANT INSERT ON  [dbo].[category_5] TO [public]
GO
GRANT DELETE ON  [dbo].[category_5] TO [public]
GO
GRANT UPDATE ON  [dbo].[category_5] TO [public]
GO
