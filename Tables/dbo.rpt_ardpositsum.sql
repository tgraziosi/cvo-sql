CREATE TABLE [dbo].[rpt_ardpositsum]
(
[payment_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[nat_cur_symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[home_cur_symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[home_total] [float] NOT NULL,
[natural_total] [float] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_ardpositsum] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_ardpositsum] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_ardpositsum] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_ardpositsum] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_ardpositsum] TO [public]
GO
