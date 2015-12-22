CREATE TABLE [dbo].[resource_map_sch]
(
[timestamp] [timestamp] NOT NULL,
[item_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sch_date] [datetime] NOT NULL,
[uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hrs_per_day] [decimal] (20, 8) NOT NULL,
[qty_per_hour] [decimal] (20, 8) NOT NULL,
[type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [resmpsch] ON [dbo].[resource_map_sch] ([item_no], [location], [sch_date]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[resource_map_sch] TO [public]
GO
GRANT SELECT ON  [dbo].[resource_map_sch] TO [public]
GO
GRANT INSERT ON  [dbo].[resource_map_sch] TO [public]
GO
GRANT DELETE ON  [dbo].[resource_map_sch] TO [public]
GO
GRANT UPDATE ON  [dbo].[resource_map_sch] TO [public]
GO
