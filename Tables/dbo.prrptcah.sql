CREATE TABLE [dbo].[prrptcah]
(
[contract_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[start_date] [datetime] NULL,
[end_date] [datetime] NULL,
[status] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type] [int] NULL,
[amt_paid] [float] NULL,
[amt_accrued] [float] NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[prrptcah] TO [public]
GO
GRANT SELECT ON  [dbo].[prrptcah] TO [public]
GO
GRANT INSERT ON  [dbo].[prrptcah] TO [public]
GO
GRANT DELETE ON  [dbo].[prrptcah] TO [public]
GO
GRANT UPDATE ON  [dbo].[prrptcah] TO [public]
GO
