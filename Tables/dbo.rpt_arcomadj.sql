CREATE TABLE [dbo].[rpt_arcomadj]
(
[salesperson_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_effective] [int] NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[adj_base_amt] [real] NOT NULL,
[adj_override_amt] [real] NOT NULL,
[posted_flag] [smallint] NOT NULL,
[user_id] [smallint] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_arcomadj] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_arcomadj] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_arcomadj] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_arcomadj] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_arcomadj] TO [public]
GO
