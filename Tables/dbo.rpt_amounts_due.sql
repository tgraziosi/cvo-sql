CREATE TABLE [dbo].[rpt_amounts_due]
(
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[module] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_applied] [int] NOT NULL,
[date_due] [int] NOT NULL,
[amount] [float] NOT NULL,
[runningtotal] [float] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_amounts_due] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_amounts_due] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_amounts_due] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_amounts_due] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_amounts_due] TO [public]
GO
