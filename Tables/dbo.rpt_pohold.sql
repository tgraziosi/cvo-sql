CREATE TABLE [dbo].[rpt_pohold]
(
[po_no] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[po_key] [int] NOT NULL,
[po_type] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_of_order] [datetime] NULL,
[date_order_due] [datetime] NULL,
[ship_to_no] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[who_entered] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[total_amt_order] [float] NULL,
[status] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hold_reason] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_pohold] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_pohold] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_pohold] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_pohold] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_pohold] TO [public]
GO
