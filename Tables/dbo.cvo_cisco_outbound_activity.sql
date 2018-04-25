CREATE TABLE [dbo].[cvo_cisco_outbound_activity]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[activity_date] [datetime] NULL,
[agent] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[account] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[shipto] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[activity] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[activity_start] [datetime] NULL,
[activity_end] [datetime] NULL,
[activity_outcome] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_cisco_outbound_activity] ADD CONSTRAINT [PK__cvo_cisco_outbou__1E184A39] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
