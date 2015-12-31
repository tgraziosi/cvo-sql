CREATE TABLE [dbo].[cvo_flash_goals]
(
[rec_id] [int] NOT NULL IDENTITY(1, 1),
[promo_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[promo_level] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[start_date] [datetime] NULL,
[end_date] [datetime] NULL,
[stat] [int] NULL,
[Program_cnt] [int] NULL,
[Program_dolrs] [decimal] (20, 8) NULL,
[Territory_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [PK_flash_goals] ON [dbo].[cvo_flash_goals] ([promo_id], [promo_level], [stat], [Territory_code]) ON [PRIMARY]
GO
