CREATE TABLE [dbo].[cvo_vision_expo_attendees]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[expo_id] [int] NULL,
[territory_id] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[territory_owner] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[isRep] [tinyint] NULL CONSTRAINT [DF__cvo_visio__isRep__24900BD4] DEFAULT ((0)),
[isRSM] [tinyint] NULL CONSTRAINT [DF__cvo_visio__isRSM__2584300D] DEFAULT ((0)),
[territory_map] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_vision_expo_attendees] ADD CONSTRAINT [PK__cvo_vision_expo___22A7C362] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_vision_expo_attendees] WITH NOCHECK ADD CONSTRAINT [FK__cvo_visio__expo___239BE79B] FOREIGN KEY ([expo_id]) REFERENCES [dbo].[cvo_vision_expo_config] ([id])
GO
ALTER TABLE [dbo].[cvo_vision_expo_attendees] NOCHECK CONSTRAINT [FK__cvo_visio__expo___239BE79B]
GO
