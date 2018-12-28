CREATE TABLE [dbo].[cvo_dc_resource_activity]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[resource_name] [varchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[activity_name] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group_code] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[start_time] [datetime] NULL,
[end_time] [datetime] NULL,
[num_tran] [int] NULL,
[qty_tran] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_dc_resource_activity] ADD CONSTRAINT [PK__cvo_dc_resource___5E5DB7D7] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
