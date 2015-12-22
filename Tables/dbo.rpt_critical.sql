CREATE TABLE [dbo].[rpt_critical]
(
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[demand_date] [datetime] NULL,
[source] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[source_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty] [float] NULL,
[uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vend_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_critical] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_critical] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_critical] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_critical] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_critical] TO [public]
GO
