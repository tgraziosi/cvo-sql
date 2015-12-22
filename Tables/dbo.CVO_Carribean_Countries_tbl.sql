CREATE TABLE [dbo].[CVO_Carribean_Countries_tbl]
(
[country] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[country_code] [char] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[CVO_Carribean_Countries_tbl] ADD CONSTRAINT [PK_Table1] PRIMARY KEY CLUSTERED  ([country_code]) ON [PRIMARY]
GO
GRANT CONTROL ON  [dbo].[CVO_Carribean_Countries_tbl] TO [public] WITH GRANT OPTION
GO
GRANT SELECT ON  [dbo].[CVO_Carribean_Countries_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_Carribean_Countries_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_Carribean_Countries_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_Carribean_Countries_tbl] TO [public]
GO
