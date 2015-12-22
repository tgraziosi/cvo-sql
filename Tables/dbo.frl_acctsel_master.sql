CREATE TABLE [dbo].[frl_acctsel_master]
(
[acctsel_id] [numeric] (12, 0) NOT NULL IDENTITY(1, 1),
[spec_set] [char] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[row_format] [char] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rptng_tree] [char] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[unit_hcode] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_updated] [datetime] NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [XPKfrl_acctsel_master] ON [dbo].[frl_acctsel_master] ([spec_set], [row_format], [rptng_tree]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[frl_acctsel_master] TO [public]
GO
GRANT SELECT ON  [dbo].[frl_acctsel_master] TO [public]
GO
GRANT INSERT ON  [dbo].[frl_acctsel_master] TO [public]
GO
GRANT DELETE ON  [dbo].[frl_acctsel_master] TO [public]
GO
GRANT UPDATE ON  [dbo].[frl_acctsel_master] TO [public]
GO
