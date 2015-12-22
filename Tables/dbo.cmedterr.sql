CREATE TABLE [dbo].[cmedterr]
(
[err_code] [int] NOT NULL,
[refer_to] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[field_desc] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[err_type] [smallint] NOT NULL,
[err_desc] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [cmedterr_ind_0] ON [dbo].[cmedterr] ([err_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cmedterr] TO [public]
GO
GRANT SELECT ON  [dbo].[cmedterr] TO [public]
GO
GRANT INSERT ON  [dbo].[cmedterr] TO [public]
GO
GRANT DELETE ON  [dbo].[cmedterr] TO [public]
GO
GRANT UPDATE ON  [dbo].[cmedterr] TO [public]
GO
