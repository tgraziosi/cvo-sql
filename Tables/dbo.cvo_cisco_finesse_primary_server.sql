CREATE TABLE [dbo].[cvo_cisco_finesse_primary_server]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[server_address] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[isPrimary] [tinyint] NULL CONSTRAINT [DF__cvo_cisco__isPri__715AB25B] DEFAULT ((0)),
[switched_date] [datetime] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_cisco_finesse_primary_server] ADD CONSTRAINT [PK__cvo_cisco_finess__70668E22] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
