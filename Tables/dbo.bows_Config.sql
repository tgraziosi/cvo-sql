CREATE TABLE [dbo].[bows_Config]
(
[ID] [int] NOT NULL,
[APUserName] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[APBatchDescription] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[APBatchCloseFlag] [int] NOT NULL,
[APBatchHoldFlag] [int] NOT NULL,
[APErrorAccountFlag] [int] NOT NULL,
[ARUserName] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ARBatchDescription] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ARBatchCloseFlag] [int] NOT NULL,
[ARBatchHoldFlag] [int] NOT NULL,
[ARErrorAccountFlag] [int] NOT NULL,
[GLUserName] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[GLBatchDescription] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GLBatchCloseFlag] [int] NOT NULL,
[GLBatchHoldFlag] [int] NOT NULL,
[GLErrorAccountFlag] [int] NOT NULL,
[ErrorAccountCode] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[APApplyDocPosted] [int] NOT NULL CONSTRAINT [DF__bows_Conf__APApp__4B272518] DEFAULT ((0)),
[ARApplyDocPosted] [int] NOT NULL CONSTRAINT [DF__bows_Conf__ARApp__4C1B4951] DEFAULT ((0)),
[po_orig_flag] [int] NOT NULL CONSTRAINT [DF__bows_Conf__po_or__4D0F6D8A] DEFAULT ((0)),
[APApplyDatePrior] [nchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__bows_Conf__APApp__4E0391C3] DEFAULT ((1)),
[APApplyDateFuture] [nchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__bows_Conf__APApp__4EF7B5FC] DEFAULT ((1)),
[ARApplyDatePrior] [nchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__bows_Conf__ARApp__4FEBDA35] DEFAULT ((1)),
[ARApplyDateFuture] [nchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__bows_Conf__ARApp__50DFFE6E] DEFAULT ((1)),
[GLExportBatchSize] [int] NULL CONSTRAINT [DF__bows_Conf__GLExp__51D422A7] DEFAULT ((500)),
[GLApplyDatePrior] [nchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__bows_Conf__GLApp__52C846E0] DEFAULT ((1)),
[GLApplyDateFuture] [nchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__bows_Conf__GLApp__53BC6B19] DEFAULT ((1)),
[SummarizeTime] [nchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__bows_Conf__Summa__54B08F52] DEFAULT ((0)),
[SummarizeExpense] [nchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__bows_Conf__Summa__55A4B38B] DEFAULT ((0)),
[SummarizeMaterials] [nchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__bows_Conf__Summa__5698D7C4] DEFAULT ((0)),
[SummarizeRevRecg] [nchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__bows_Conf__Summa__578CFBFD] DEFAULT ((0)),
[SummarizeDisb] [nchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__bows_Conf__Summa__58812036] DEFAULT ((0)),
[SummarizeManualJournal] [nchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__bows_Conf__Summa__5975446F] DEFAULT ((0)),
[GroupByFirstDayofWeek] [nchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GroupByProject] [nchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__bows_Conf__Group__5A6968A8] DEFAULT ((1)),
[GroupByResource] [nchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__bows_Conf__Group__5B5D8CE1] DEFAULT ((1)),
[GroupByDay] [nchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__bows_Conf__Group__5C51B11A] DEFAULT ((0)),
[GroupByWeek] [nchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__bows_Conf__Group__5D45D553] DEFAULT ((0)),
[GroupByPeriod] [nchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__bows_Conf__Group__5E39F98C] DEFAULT ((1)),
[APExportImportBatchSize] [int] NOT NULL CONSTRAINT [DF__bows_Conf__APExp__5F2E1DC5] DEFAULT ((500)),
[APExportImportThresholdSize] [int] NOT NULL CONSTRAINT [DF__bows_Conf__APExp__602241FE] DEFAULT ((50)),
[ARExportImportBatchSize] [int] NOT NULL CONSTRAINT [DF__bows_Conf__ARExp__61166637] DEFAULT ((500)),
[ARExportImportThresholdSize] [int] NOT NULL CONSTRAINT [DF__bows_Conf__ARExp__620A8A70] DEFAULT ((50))
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[bows_Config] TO [public]
GO
GRANT INSERT ON  [dbo].[bows_Config] TO [public]
GO
GRANT DELETE ON  [dbo].[bows_Config] TO [public]
GO
GRANT UPDATE ON  [dbo].[bows_Config] TO [public]
GO
