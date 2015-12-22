CREATE TABLE [dbo].[rpt_invforecast]
(
[FOREDESC] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SESSTIMESTAMP] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[NOTE] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[STORENAME] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[PART] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[NAME] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[PROMOTION] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[MONTHYEAR] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[FORECAST] [real] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_invforecast] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_invforecast] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_invforecast] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_invforecast] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_invforecast] TO [public]
GO
