CREATE TABLE [dbo].[atmtchdr_all]
(
[timestamp] [timestamp] NOT NULL,
[invoice_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_net] [float] NULL,
[date_doc] [int] NOT NULL,
[date_discount] [int] NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[status] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_posted] [int] NULL,
[date_imported] [int] NOT NULL,
[num_failed] [smallint] NULL,
[date_failed] [int] NULL,
[source_module] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[error_desc] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[amt_tax] [float] NULL,
[amt_discount] [float] NULL,
[amt_freight] [float] NULL,
[amt_misc] [float] NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [atmtchdr_all_ind_0] ON [dbo].[atmtchdr_all] ([invoice_no], [vendor_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[atmtchdr_all] TO [public]
GO
GRANT SELECT ON  [dbo].[atmtchdr_all] TO [public]
GO
GRANT INSERT ON  [dbo].[atmtchdr_all] TO [public]
GO
GRANT DELETE ON  [dbo].[atmtchdr_all] TO [public]
GO
GRANT UPDATE ON  [dbo].[atmtchdr_all] TO [public]
GO
