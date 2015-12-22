CREATE TABLE [dbo].[rpt_DPR_Reports]
(
[row] [int] NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Reserver_Level] [numeric] (10, 0) NULL,
[POM_Date] [datetime] NULL,
[e4_WU] [numeric] (10, 0) NULL,
[e12_WU] [numeric] (10, 0) NULL,
[e26_WU] [numeric] (10, 0) NULL,
[e52_WU] [numeric] (10, 0) NULL,
[S4_WU] [numeric] (10, 0) NULL,
[S12_WU] [numeric] (10, 0) NULL,
[S26_WU] [numeric] (10, 0) NULL,
[S52_WU] [numeric] (10, 0) NULL,
[On_Hand] [numeric] (10, 0) NULL,
[BackOrder] [numeric] (10, 0) NULL,
[Allocated] [numeric] (10, 0) NULL,
[SA_Allocated] [numeric] (10, 0) NULL,
[Non_Allocated_PO] [numeric] (10, 0) NULL,
[Allocated_PO] [numeric] (10, 0) NULL,
[Future_Orders] [int] NULL,
[Non_Allocated_PO2] [numeric] (10, 0) NULL,
[Allocated_PO2] [numeric] (10, 0) NULL,
[Future_Orders2] [int] NULL,
[Non_Allocated_PO3] [numeric] (10, 0) NULL,
[Allocated_PO3] [numeric] (10, 0) NULL,
[Future_Orders3] [int] NULL,
[Non_Allocated_PO4] [numeric] (10, 0) NULL,
[Allocated_PO4] [numeric] (10, 0) NULL,
[Future_Orders4] [int] NULL,
[Non_Allocated_PO5] [numeric] (10, 0) NULL,
[Allocated_PO5] [numeric] (10, 0) NULL,
[Future_Orders5] [int] NULL,
[Non_Allocated_PO6] [numeric] (10, 0) NULL,
[Allocated_PO6] [numeric] (10, 0) NULL,
[Future_Orders6] [int] NULL,
[avend] [numeric] (10, 0) NULL,
[av4end] [numeric] (10, 0) NULL,
[av8end] [numeric] (10, 0) NULL,
[av12end] [numeric] (10, 0) NULL,
[av16end] [numeric] (10, 0) NULL,
[av20end] [numeric] (10, 0) NULL,
[av24end] [numeric] (10, 0) NULL,
[Orders] [int] NULL,
[status] [int] NULL,
[status_description] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[style] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[collection] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MOQ] [numeric] (10, 0) NULL,
[RR1] [numeric] (10, 2) NULL,
[RR3] [numeric] (10, 2) NULL,
[release_date] [datetime] NULL,
[lead_time] [int] NULL,
[location] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type_code] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_DPR_Reports] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_DPR_Reports] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_DPR_Reports] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_DPR_Reports] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_DPR_Reports] TO [public]
GO
