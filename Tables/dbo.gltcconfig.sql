CREATE TABLE [dbo].[gltcconfig]
(
[timestamp] [timestamp] NOT NULL,
[company_id] [smallint] NOT NULL,
[url] [varchar] (900) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[viaurl] [varchar] (900) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[username] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[password] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[requesttimeout] [int] NOT NULL,
[currency_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[freight_tax_type_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tax_auth_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[gl_internal_tax_account] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[gl_sales_tax_account] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[gltcconfig] TO [public]
GO
GRANT SELECT ON  [dbo].[gltcconfig] TO [public]
GO
GRANT INSERT ON  [dbo].[gltcconfig] TO [public]
GO
GRANT DELETE ON  [dbo].[gltcconfig] TO [public]
GO
GRANT UPDATE ON  [dbo].[gltcconfig] TO [public]
GO
