CREATE TABLE [dbo].[artax]
(
[timestamp] [timestamp] NOT NULL,
[tax_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tax_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tax_included_flag] [smallint] NOT NULL,
[override_flag] [smallint] NOT NULL,
[module_flag] [smallint] NOT NULL,
[tax_connect_flag] [smallint] NOT NULL CONSTRAINT [DF__artax__tax_conne__55894A3A] DEFAULT ((0)),
[external_tax_code] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__artax__external___567D6E73] DEFAULT (''),
[imported_flag] [smallint] NULL CONSTRAINT [DF__artax__imported___577192AC] DEFAULT ((0))
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [artax_ind_0] ON [dbo].[artax] ([tax_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[artax] TO [public]
GO
GRANT SELECT ON  [dbo].[artax] TO [public]
GO
GRANT INSERT ON  [dbo].[artax] TO [public]
GO
GRANT DELETE ON  [dbo].[artax] TO [public]
GO
GRANT UPDATE ON  [dbo].[artax] TO [public]
GO
