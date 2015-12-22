CREATE TABLE [dbo].[rpt_arcomm]
(
[commission_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[from_bracket] [float] NOT NULL,
[to_bracket] [float] NOT NULL,
[commission_amt] [float] NOT NULL,
[percent_flag] [smallint] NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[base_type] [smallint] NOT NULL,
[table_amt_type] [smallint] NOT NULL,
[calc_type] [smallint] NOT NULL,
[when_paid_type] [smallint] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_arcomm] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_arcomm] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_arcomm] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_arcomm] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_arcomm] TO [public]
GO
