CREATE TABLE [dbo].[mbbmPlanGrp74]
(
[TimeStamp] [timestamp] NOT NULL,
[RevisionID] [int] NOT NULL,
[GroupKey] [dbo].[mbbmudtGroupKey] NOT NULL,
[Description] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[CurrentDateType] [tinyint] NOT NULL,
[CurrentDate] [dbo].[mbbmudtAppDate] NULL,
[YearOffset] [smallint] NOT NULL,
[PeriodOffset] [smallint] NOT NULL,
[BalanceType] [tinyint] NOT NULL,
[BalanceCode] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ModelOrder] [smallint] NOT NULL,
[ModelColumnPrefix] [dbo].[mbbmudtColumnKey] NOT NULL,
[ModelColumnDescription] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ModelValuation] [tinyint] NOT NULL,
[ModelFromPeriodType] [tinyint] NOT NULL,
[ModelFromPeriod] [smallint] NOT NULL,
[ModelThruPeriodType] [tinyint] NOT NULL,
[ModelThruPeriod] [smallint] NOT NULL,
[ModelLastFromPeriod] [smallint] NOT NULL,
[ModelLastThruPeriod] [smallint] NOT NULL,
[ModelFromIncrement] [smallint] NOT NULL,
[ModelThruIncrement] [smallint] NOT NULL,
[ModelLayoutStyle] [smallint] NOT NULL,
[ModelColumnTotal] [smallint] NOT NULL,
[Publish] [dbo].[mbbmudtYesNo] NOT NULL,
[GroupCalculation] [int] NULL,
[MeasureName] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ModelViewColumn] [dbo].[mbbmudtYesNo] NOT NULL,
[ModelViewTotal] [dbo].[mbbmudtYesNo] NOT NULL,
[UsePlanBudgetCode] [dbo].[mbbmudtYesNo] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmPlanGrp74] ADD CONSTRAINT [PK_mbbmPlanGrp74] PRIMARY KEY CLUSTERED  ([RevisionID], [GroupKey]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmPlanGrp74] ADD CONSTRAINT [FK_mbbmPlanGrp74_RevisionID] FOREIGN KEY ([RevisionID]) REFERENCES [dbo].[mbbmPlanSheetRev74] ([RevisionID])
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmPlanGrp74].[Publish]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmPlanGrp74].[Publish]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmPlanGrp74].[ModelViewColumn]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmPlanGrp74].[ModelViewColumn]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmPlanGrp74].[ModelViewTotal]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmPlanGrp74].[ModelViewTotal]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmPlanGrp74].[UsePlanBudgetCode]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmPlanGrp74].[UsePlanBudgetCode]'
GO
GRANT REFERENCES ON  [dbo].[mbbmPlanGrp74] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmPlanGrp74] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmPlanGrp74] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmPlanGrp74] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmPlanGrp74] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmPlanGrp74] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmPlanGrp74] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmPlanGrp74] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmPlanGrp74] TO [public]
GO
