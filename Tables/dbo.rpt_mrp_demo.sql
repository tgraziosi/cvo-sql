CREATE TABLE [dbo].[rpt_mrp_demo]
(
[report_beg_balance] [float] NULL,
[period_date_beg] [datetime] NULL,
[period_date_end] [datetime] NULL,
[report_line_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[report_line_cust_ord_id] [int] NULL,
[report_line_po_id] [char] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[report_line_quantity] [float] NULL,
[report_line_date] [datetime] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_mrp_demo] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_mrp_demo] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_mrp_demo] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_mrp_demo] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_mrp_demo] TO [public]
GO
