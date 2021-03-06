CREATE TABLE [dbo].[EFORECAST_REPORT]
(
[SESSIONID] [int] NOT NULL,
[CONVERSIONID] [int] NOT NULL,
[PRODUCTID] [int] NOT NULL,
[LOCATIONID] [int] NOT NULL,
[FORESUM] [real] NULL,
[CUMFORE] [real] NULL,
[FOREMETHOD] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AVEERROR] [real] NULL,
[AVEPCTERROR] [real] NULL,
[HISTORYSTART] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HISTORYEND] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CASES] [int] NULL,
[ADJUSTMENTS] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HEDGE] [int] NULL,
[EVENTEFFECTS] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HORIZON] [int] NULL,
[SERVICELEVEL] [int] NULL,
[AVEPERPERIOD] [real] NULL,
[AVELTD] [real] NULL,
[STDDEV] [real] NULL,
[SAFETYSTOCK] [real] NULL,
[MINIMUM] [real] NULL,
[PCT50LEVEL] [real] NULL,
[PCT] [int] NULL,
[PCTLEVEL] [real] NULL,
[MAXIMUM] [real] NULL,
[METHODTYPE] [int] NULL,
[FORECASTTYPE] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[STATUS] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TYPE] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TAG] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[NOTES] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GROUPID] [int] NULL,
[LASTMODIFIEDBY] [int] NULL,
[LASTMODIFIED] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CONVERSION] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FRACTIONALHORIZON] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_EFORECAST_REPORT_1] ON [dbo].[EFORECAST_REPORT] ([PRODUCTID], [LOCATIONID], [SESSIONID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[EFORECAST_REPORT] ADD CONSTRAINT [FK_SSI_REP_1_GROUPID] FOREIGN KEY ([GROUPID]) REFERENCES [dbo].[SSI_GRP_1] ([GROUPID])
GO
ALTER TABLE [dbo].[EFORECAST_REPORT] ADD CONSTRAINT [FK_SSI_REP_1_LASTMOD] FOREIGN KEY ([LASTMODIFIEDBY]) REFERENCES [dbo].[SSI_USR] ([USERID])
GO
ALTER TABLE [dbo].[EFORECAST_REPORT] ADD CONSTRAINT [FK_EFORECAST_REPORT_EFORECAST_LOCATION_LOCATIONID] FOREIGN KEY ([LOCATIONID]) REFERENCES [dbo].[EFORECAST_LOCATION] ([LOCATIONID])
GO
ALTER TABLE [dbo].[EFORECAST_REPORT] ADD CONSTRAINT [FK_EFORECAST_REPORT_EFORECAST_PRODUCT_PRODUCTID] FOREIGN KEY ([PRODUCTID]) REFERENCES [dbo].[EFORECAST_PRODUCT] ([PRODUCTID])
GO
GRANT SELECT ON  [dbo].[EFORECAST_REPORT] TO [epicoradmin]
GO
GRANT INSERT ON  [dbo].[EFORECAST_REPORT] TO [epicoradmin]
GO
GRANT DELETE ON  [dbo].[EFORECAST_REPORT] TO [epicoradmin]
GO
GRANT UPDATE ON  [dbo].[EFORECAST_REPORT] TO [epicoradmin]
GO
GRANT REFERENCES ON  [dbo].[EFORECAST_REPORT] TO [public]
GO
GRANT SELECT ON  [dbo].[EFORECAST_REPORT] TO [public]
GO
GRANT INSERT ON  [dbo].[EFORECAST_REPORT] TO [public]
GO
GRANT DELETE ON  [dbo].[EFORECAST_REPORT] TO [public]
GO
GRANT UPDATE ON  [dbo].[EFORECAST_REPORT] TO [public]
GO
