CREATE TABLE [dbo].[arfinchg]
(
[timestamp] [timestamp] NOT NULL,
[fin_chg_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[fin_chg_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[min_fin_chg] [float] NOT NULL,
[fin_chg_prc] [float] NOT NULL,
[late_chg_amt] [float] NOT NULL,
[compound_chg_flag] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [arfinchg_ind_0] ON [dbo].[arfinchg] ([fin_chg_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arfinchg] TO [public]
GO
GRANT SELECT ON  [dbo].[arfinchg] TO [public]
GO
GRANT INSERT ON  [dbo].[arfinchg] TO [public]
GO
GRANT DELETE ON  [dbo].[arfinchg] TO [public]
GO
GRANT UPDATE ON  [dbo].[arfinchg] TO [public]
GO
