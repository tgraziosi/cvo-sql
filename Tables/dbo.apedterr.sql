CREATE TABLE [dbo].[apedterr]
(
[err_code] [int] NOT NULL,
[refer_to] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[field_desc] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[err_type] [smallint] NOT NULL,
[err_desc] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [apedterr_ind_0] ON [dbo].[apedterr] ([err_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apedterr] TO [public]
GO
GRANT SELECT ON  [dbo].[apedterr] TO [public]
GO
GRANT INSERT ON  [dbo].[apedterr] TO [public]
GO
GRANT DELETE ON  [dbo].[apedterr] TO [public]
GO
GRANT UPDATE ON  [dbo].[apedterr] TO [public]
GO
