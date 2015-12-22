CREATE TABLE [dbo].[rpt_atmtcmdt]
(
[invoice_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[po_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty] [float] NOT NULL,
[unit_price] [float] NOT NULL,
[amt_tax] [float] NOT NULL,
[amt_discount] [float] NOT NULL,
[amt_freight] [float] NOT NULL,
[amt_misc] [float] NOT NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_atmtcmdt] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_atmtcmdt] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_atmtcmdt] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_atmtcmdt] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_atmtcmdt] TO [public]
GO
