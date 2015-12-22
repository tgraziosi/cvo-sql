CREATE TABLE [dbo].[cvo_cmi_worksheet]
(
[id] [smallint] NOT NULL IDENTITY(1, 1),
[variant_id] [int] NULL,
[ship1_qty] [int] NULL,
[ship1_date] [datetime] NULL,
[ship2_qty] [int] NULL,
[ship2_date] [datetime] NULL,
[ship3_qty] [int] NULL,
[ship3_date] [datetime] NULL,
[lead_qty] [int] NULL,
[description] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[model_id] [int] NULL,
[isActive] [smallint] NULL CONSTRAINT [DF__cvo_cmi_w__isAct__03EECBA5] DEFAULT ('1'),
[brand] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_cmi_worksheet] ADD CONSTRAINT [PK__cvo_cmi_workshee__74AC8815] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
