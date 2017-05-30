CREATE TABLE [dbo].[cvo_bcode_log]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[bcode_date] [datetime] NULL,
[bcode_user] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sku] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[upc] [varchar] (18) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin] [varchar] (18) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sort] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[aisle] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sort_bin] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[isActive] [tinyint] NULL CONSTRAINT [DF__cvo_bcode__isAct__59C25495] DEFAULT ('1'),
[isPrinted] [tinyint] NULL CONSTRAINT [DF__cvo_bcode__isPri__5AB678CE] DEFAULT ('0'),
[isVoided] [tinyint] NULL CONSTRAINT [DF__cvo_bcode__isVoi__5BAA9D07] DEFAULT ('0'),
[void_date] [datetime] NULL,
[void_user] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_reason] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cat] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_bcode_log] ADD CONSTRAINT [PK__cvo_bcode_log__58CE305C] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
