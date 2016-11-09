CREATE TABLE [dbo].[category_3]
(
[timestamp] [timestamp] NOT NULL,
[category_code] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_entered] [datetime] NULL,
[void] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_date] [datetime] NULL,
[cf_process] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__category___cf_pr__4E2422B2] DEFAULT ('N'),
[style_ind] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__category___style__7DD335D4] DEFAULT ('N')
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [category_3_cf_ind0] ON [dbo].[category_3] ([category_code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [category_3_cf_ind1] ON [dbo].[category_3] ([category_code], [void], [cf_process]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[category_3] TO [public]
GO
GRANT SELECT ON  [dbo].[category_3] TO [public]
GO
GRANT INSERT ON  [dbo].[category_3] TO [public]
GO
GRANT DELETE ON  [dbo].[category_3] TO [public]
GO
GRANT UPDATE ON  [dbo].[category_3] TO [public]
GO
