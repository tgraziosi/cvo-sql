CREATE TABLE [dbo].[rpt_ardncshd]
(
[dunning_level] [smallint] NOT NULL,
[dunn_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[lower_sep_day] [int] NOT NULL,
[upper_sep_day] [int] NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_due] [float] NOT NULL,
[amt_extra] [float] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_ardncshd] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_ardncshd] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_ardncshd] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_ardncshd] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_ardncshd] TO [public]
GO
