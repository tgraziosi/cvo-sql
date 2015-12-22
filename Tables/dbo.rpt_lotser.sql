CREATE TABLE [dbo].[rpt_lotser]
(
[item_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_expires] [datetime] NULL,
[qty] [float] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_lotser] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_lotser] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_lotser] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_lotser] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_lotser] TO [public]
GO
