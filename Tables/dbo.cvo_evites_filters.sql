CREATE TABLE [dbo].[cvo_evites_filters]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[request_group] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[f_brand] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[f_restype] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[f_fit] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[f_eyeshape] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[f_demographic] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[f_color] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[f_frametype] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[f_minqty] [int] NULL,
[f_orderqty] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_evites_filters] ADD CONSTRAINT [PK__cvo_evites_filte__0F6B0386] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
