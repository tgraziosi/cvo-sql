CREATE TABLE [dbo].[cvo_vision_expo_west_attendees]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[expo_id] [int] NULL,
[territory_id] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[territory_owner] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[isRep] [tinyint] NULL CONSTRAINT [DF__cvo_visio__isRep__32030E3E] DEFAULT ((0)),
[isRSM] [tinyint] NULL CONSTRAINT [DF__cvo_visio__isRSM__32F73277] DEFAULT ((0)),
[territory_map] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[booth] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_vision_expo_west_attendees] ADD CONSTRAINT [PK__cvo_vision_expo___310EEA05] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
