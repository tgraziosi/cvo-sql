CREATE TABLE [dbo].[cvo_tbb_orders]
(
[purchase_order] [int] NOT NULL,
[order_date] [datetime] NOT NULL,
[id] [bigint] NOT NULL,
[account_name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_num] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[contact] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[email] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[alt_ship] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_tbb_o__alt_s__14AEA9C6] DEFAULT (NULL),
[tray] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_tbb_or__tray__15A2CDFF] DEFAULT (NULL),
[promo] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_tbb_o__promo__1696F238] DEFAULT (NULL),
[brand] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[model] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[color] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[size] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[patient_name] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_tbb_o__patie__178B1671] DEFAULT (NULL),
[instructions] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[mail_sent_to] [varchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_tbb_o__mail___187F3AAA] DEFAULT (NULL)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
