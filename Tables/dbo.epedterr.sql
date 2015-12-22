CREATE TABLE [dbo].[epedterr]
(
[err_code] [int] NOT NULL,
[refer_to] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[field_desc] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[err_type] [smallint] NOT NULL,
[err_desc] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [epedterr_ind_0] ON [dbo].[epedterr] ([err_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[epedterr] TO [public]
GO
GRANT SELECT ON  [dbo].[epedterr] TO [public]
GO
GRANT INSERT ON  [dbo].[epedterr] TO [public]
GO
GRANT DELETE ON  [dbo].[epedterr] TO [public]
GO
GRANT UPDATE ON  [dbo].[epedterr] TO [public]
GO
