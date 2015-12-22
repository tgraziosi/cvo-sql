CREATE TABLE [dbo].[epapvend]
(
[guid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_code] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[modified_dt] [datetime] NOT NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[epapvend] ADD CONSTRAINT [PK_epapvend] PRIMARY KEY NONCLUSTERED  ([guid], [vendor_code]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[epapvend] TO [public]
GO
GRANT INSERT ON  [dbo].[epapvend] TO [public]
GO
GRANT DELETE ON  [dbo].[epapvend] TO [public]
GO
GRANT UPDATE ON  [dbo].[epapvend] TO [public]
GO
