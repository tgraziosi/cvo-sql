CREATE TABLE [dbo].[cvo_slp_scorecard]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[userid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[territory_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_entered] [datetime] NOT NULL,
[ly_net_sales] [decimal] (18, 8) NULL,
[doors] [int] NULL,
[st_orders] [int] NULL,
[brands] [int] NULL,
[cust_500] [int] NULL,
[multi_loc_cust] [int] NULL,
[increased_rxe] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[reduced_returns] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[aspire_new_doors] [int] NULL,
[ty_net_sales_target] [decimal] (18, 8) NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_slp_scorecard] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_slp_scorecard] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_slp_scorecard] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_slp_scorecard] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_slp_scorecard] TO [public]
GO
