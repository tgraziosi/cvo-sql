CREATE TABLE [dbo].[cvo_seco_2016_attendees]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[expo_id] [int] NULL,
[territory_id] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[territory_owner] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[isRep] [tinyint] NULL CONSTRAINT [DF__cvo_seco___isRep__786D0034] DEFAULT ((0)),
[isRSM] [tinyint] NULL CONSTRAINT [DF__cvo_seco___isRSM__7961246D] DEFAULT ((0)),
[territory_map] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[booth] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_seco_2016_attendees] ADD CONSTRAINT [PK__cvo_seco_2016_at__7778DBFB] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
