CREATE TABLE [dbo].[rpt_invhold]
(
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[item_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hold_qty] [float] NULL,
[hold_mfg] [float] NULL,
[hold_ord] [float] NULL,
[hold_rcv] [float] NULL,
[hold_xfr] [float] NULL,
[transit] [float] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_invhold] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_invhold] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_invhold] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_invhold] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_invhold] TO [public]
GO
