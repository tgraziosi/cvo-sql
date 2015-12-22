CREATE TABLE [dbo].[rpt_appurach]
(
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[beginning_bal] [float] NOT NULL,
[charge] [float] NOT NULL,
[payment] [float] NOT NULL,
[adjust] [float] NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_appurach] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_appurach] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_appurach] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_appurach] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_appurach] TO [public]
GO
