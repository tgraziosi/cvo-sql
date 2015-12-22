CREATE TABLE [dbo].[rpt_arterms]
(
[timestamp] [timestamp] NOT NULL,
[terms_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [smallint] NOT NULL,
[terms_desc] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[days_due] [smallint] NOT NULL,
[min_days_due] [smallint] NOT NULL,
[discount_days] [smallint] NOT NULL,
[terms_type] [smallint] NOT NULL,
[discount_prc] [float] NOT NULL,
[date_due] [int] NOT NULL,
[date_discount] [int] NOT NULL,
[str_1st_l] [varchar] (70) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[str_1st_r] [varchar] (70) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[str_2nd_l] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[str_2nd_r] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[str_3rd_l] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[l_2nd_val] [int] NOT NULL,
[r_2nd_val] [int] NOT NULL,
[l_3rd_val] [int] NOT NULL,
[str_terms_type] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_arterms] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_arterms] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_arterms] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_arterms] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_arterms] TO [public]
GO
