CREATE TABLE [dbo].[adm_inv_mtd_calendar]
(
[timestamp] [timestamp] NOT NULL,
[tran_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[beg_date] [int] NULL,
[reset_date] [datetime] NULL,
[year_month] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[fiscal_year] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[fiscal_start_mth] [int] NOT NULL,
[mtd_ind] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [adm_inv_mtd_calendar] ON [dbo].[adm_inv_mtd_calendar] ([beg_date]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [adm_inv_mtd_calendar2] ON [dbo].[adm_inv_mtd_calendar] ([tran_type], [beg_date]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [adm_inv_mtd_calendar0] ON [dbo].[adm_inv_mtd_calendar] ([tran_type], [beg_date], [mtd_ind], [year_month]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [adm_inv_mtd_calendar1] ON [dbo].[adm_inv_mtd_calendar] ([tran_type], [year_month]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[adm_inv_mtd_calendar] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_inv_mtd_calendar] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_inv_mtd_calendar] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_inv_mtd_calendar] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_inv_mtd_calendar] TO [public]
GO
