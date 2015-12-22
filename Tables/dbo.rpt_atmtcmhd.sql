CREATE TABLE [dbo].[rpt_atmtcmhd]
(
[invoice_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[status] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[source_module] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_doc] [int] NOT NULL,
[date_imported] [int] NOT NULL,
[date_discount] [int] NOT NULL,
[error_desc] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_tax] [float] NOT NULL,
[amt_discount] [float] NOT NULL,
[amt_freight] [float] NOT NULL,
[amt_misc] [float] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_atmtcmhd] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_atmtcmhd] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_atmtcmhd] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_atmtcmhd] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_atmtcmhd] TO [public]
GO
