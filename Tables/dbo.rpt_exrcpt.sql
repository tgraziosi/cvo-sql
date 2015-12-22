CREATE TABLE [dbo].[rpt_exrcpt]
(
[description] [varchar] (254) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[uom] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[po_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[release_date] [datetime] NULL,
[quantity] [float] NULL,
[received] [float] NULL,
[conv_factor] [float] NULL,
[unit_measure] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor_code] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[line_status] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rel_status] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[unit_cost] [float] NULL,
[inv_qty] [float] NULL,
[group_1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_exrcpt] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_exrcpt] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_exrcpt] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_exrcpt] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_exrcpt] TO [public]
GO
