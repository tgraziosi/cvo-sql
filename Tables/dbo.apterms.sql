CREATE TABLE [dbo].[apterms]
(
[timestamp] [timestamp] NOT NULL,
[terms_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[terms_desc] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[days_due] [smallint] NOT NULL,
[discount_days] [smallint] NOT NULL,
[terms_type] [smallint] NOT NULL,
[discount_prc] [float] NOT NULL,
[min_days_due] [smallint] NOT NULL,
[date_due] [int] NOT NULL,
[date_discount] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [apterms_ind_0] ON [dbo].[apterms] ([terms_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apterms] TO [public]
GO
GRANT SELECT ON  [dbo].[apterms] TO [public]
GO
GRANT INSERT ON  [dbo].[apterms] TO [public]
GO
GRANT DELETE ON  [dbo].[apterms] TO [public]
GO
GRANT UPDATE ON  [dbo].[apterms] TO [public]
GO
