CREATE TABLE [dbo].[arreturn]
(
[timestamp] [timestamp] NOT NULL,
[return_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[iv_trx_type] [smallint] NOT NULL,
[spoilage_flag] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [arreturn_ind_0] ON [dbo].[arreturn] ([return_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arreturn] TO [public]
GO
GRANT SELECT ON  [dbo].[arreturn] TO [public]
GO
GRANT INSERT ON  [dbo].[arreturn] TO [public]
GO
GRANT DELETE ON  [dbo].[arreturn] TO [public]
GO
GRANT UPDATE ON  [dbo].[arreturn] TO [public]
GO
