CREATE TABLE [dbo].[cvo_dc_ship_activity]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[resource_login] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[module] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[activity_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[resource_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[num_tran] [int] NULL,
[ship_date] [datetime] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_dc_ship_activity] ADD CONSTRAINT [PK__cvo_dc_ship_acti__3F6F1C63] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
