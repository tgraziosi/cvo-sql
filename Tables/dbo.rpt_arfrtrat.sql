CREATE TABLE [dbo].[rpt_arfrtrat]
(
[freight_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[freight_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_via_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_via_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[orig_zone_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[from_dest_zone_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[thru_dest_zone_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[max_weight] [float] NOT NULL,
[freight_amt] [float] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_arfrtrat] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_arfrtrat] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_arfrtrat] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_arfrtrat] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_arfrtrat] TO [public]
GO
