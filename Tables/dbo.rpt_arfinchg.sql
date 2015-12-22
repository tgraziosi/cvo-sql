CREATE TABLE [dbo].[rpt_arfinchg]
(
[fin_chg_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[fin_chg_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[min_fin_chg] [real] NOT NULL,
[fin_chg_prc] [real] NOT NULL,
[late_chg_amt] [real] NOT NULL,
[compound_chg_flag] [smallint] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_arfinchg] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_arfinchg] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_arfinchg] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_arfinchg] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_arfinchg] TO [public]
GO
