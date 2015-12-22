CREATE TABLE [dbo].[rpt_socustanl]
(
[order_no] [int] NULL,
[order_ext] [int] NULL,
[cust_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sch_ship_date] [datetime] NULL,
[date_shipped] [datetime] NULL,
[ship_amt] [decimal] (20, 8) NULL,
[Backordered] [int] NOT NULL,
[Early] [int] NOT NULL,
[Late] [int] NOT NULL,
[OnTime] [int] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_socustanl] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_socustanl] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_socustanl] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_socustanl] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_socustanl] TO [public]
GO
