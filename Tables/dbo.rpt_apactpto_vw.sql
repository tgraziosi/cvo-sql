CREATE TABLE [dbo].[rpt_apactpto_vw]
(
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pay_to_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pay_to_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_last_vouch] [int] NOT NULL,
[date_last_dm] [int] NOT NULL,
[date_last_adj] [int] NOT NULL,
[date_last_pyt] [int] NOT NULL,
[date_last_void] [int] NOT NULL,
[amt_last_vouch] [real] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_apactpto_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_apactpto_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_apactpto_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_apactpto_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_apactpto_vw] TO [public]
GO
