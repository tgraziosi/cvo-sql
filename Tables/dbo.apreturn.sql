CREATE TABLE [dbo].[apreturn]
(
[timestamp] [timestamp] NOT NULL,
[return_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[iv_trx_type] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [apreturn_ind_0] ON [dbo].[apreturn] ([return_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apreturn] TO [public]
GO
GRANT SELECT ON  [dbo].[apreturn] TO [public]
GO
GRANT INSERT ON  [dbo].[apreturn] TO [public]
GO
GRANT DELETE ON  [dbo].[apreturn] TO [public]
GO
GRANT UPDATE ON  [dbo].[apreturn] TO [public]
GO
