CREATE TABLE [dbo].[cvo_expo_attendees]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[expo_id] [int] NULL,
[territory_id] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[territory_owner] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[isRep] [tinyint] NULL CONSTRAINT [DF__cvo_expo___isRep__620032D6] DEFAULT ((0)),
[isRSM] [tinyint] NULL CONSTRAINT [DF__cvo_expo___isRSM__62F4570F] DEFAULT ((0)),
[territory_map] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[booth] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_expo_attendees] ADD CONSTRAINT [PK__cvo_expo_attende__610C0E9D] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
