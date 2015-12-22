CREATE TABLE [dbo].[rpt_qc]
(
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qc_no] [int] NULL,
[tran_code] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tran_no] [int] NULL,
[uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qc_qty] [decimal] (20, 8) NULL,
[reject_qty] [decimal] (20, 8) NULL,
[reject_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[inspector] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[who_inspected] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_inspected] [datetime] NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_entered] [datetime] NULL,
[date_complete] [datetime] NULL,
[reason] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group_1] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group_2] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_qc] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_qc] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_qc] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_qc] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_qc] TO [public]
GO
