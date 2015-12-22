CREATE TABLE [dbo].[rpt_soa]
(
[code] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sales] [decimal] (20, 8) NULL,
[cost] [decimal] (20, 8) NULL,
[margin] [decimal] (20, 8) NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_soa] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_soa] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_soa] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_soa] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_soa] TO [public]
GO
