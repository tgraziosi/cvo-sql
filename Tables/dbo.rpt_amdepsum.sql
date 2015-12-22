CREATE TABLE [dbo].[rpt_amdepsum]
(
[book_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[depr_rule_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[depr_conv_id] [tinyint] NULL,
[cost] [float] NULL,
[accum_depr] [float] NULL,
[book_value] [float] NULL,
[depr_expense] [float] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_amdepsum] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_amdepsum] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_amdepsum] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_amdepsum] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_amdepsum] TO [public]
GO
