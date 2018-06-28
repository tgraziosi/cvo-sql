CREATE TABLE [dbo].[cvo_boxing_log]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[bcode_date] [datetime] NULL,
[bcode_user] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sku] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[upc] [varchar] (18) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[isPrinted] [tinyint] NULL CONSTRAINT [DF__cvo_boxin__isPri__05A1A22A] DEFAULT ('0'),
[isVoided] [tinyint] NULL CONSTRAINT [DF__cvo_boxin__isVoi__0695C663] DEFAULT ('0'),
[void_date] [datetime] NULL,
[void_user] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_reason] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[isActive] [tinyint] NULL CONSTRAINT [DF__cvo_boxin__isAct__0789EA9C] DEFAULT ('1'),
[qty] [smallint] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_boxing_log] ADD CONSTRAINT [PK__cvo_boxing_log__04AD7DF1] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
