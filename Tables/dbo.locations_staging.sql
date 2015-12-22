CREATE TABLE [dbo].[locations_staging]
(
[location] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[name] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location_type] [float] NULL,
[addr1] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr2] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr3] [float] NULL,
[addr4] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr5] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr_sort1] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr_sort2] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr_sort3] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[phone] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[contact_name] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[consign_customer_code] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[consign_vendor_code] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[aracct_code] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[zone_code] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_who] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_date] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[apacct_code] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dflt_recv_bin] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[country_code] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[harbour] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bundesland] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[department] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[city] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[state] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[zip] [float] NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[locations_staging] TO [public]
GO
GRANT INSERT ON  [dbo].[locations_staging] TO [public]
GO
GRANT DELETE ON  [dbo].[locations_staging] TO [public]
GO
GRANT UPDATE ON  [dbo].[locations_staging] TO [public]
GO
