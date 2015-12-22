CREATE TABLE [dbo].[cvo_ARAging_month]
(
[CUST_CODE] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[KEY] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[attn_email] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SLS] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TERR] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[REGION] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[NAME] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BG_CODE] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BG_NAME] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TMS] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AVGDAYSLATE] [smallint] NULL,
[BAL] [float] NULL,
[FUT] [float] NULL,
[CUR] [float] NULL,
[AR30] [float] NULL,
[AR60] [float] NULL,
[AR90] [float] NULL,
[AR120] [float] NULL,
[AR150] [float] NULL,
[CREDIT_LIMIT] [float] NULL,
[ONORDER] [float] NULL,
[lpmtdt] [datetime] NULL,
[AMOUNT] [float] NULL,
[YTDCREDS] [float] NULL,
[YTDSALES] [float] NULL,
[LYRSALES] [float] NULL,
[r12sales] [float] NULL,
[HOLD] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_asof] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_type_string] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_type] [tinyint] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [idx_araging_m] ON [dbo].[cvo_ARAging_month] ([CUST_CODE], [date_asof]) ON [PRIMARY]
GO
