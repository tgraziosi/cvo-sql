CREATE TABLE [dbo].[cvo_sales_bag]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[tray_no] [smallint] NULL,
[slot_no] [smallint] NULL,
[slot_image] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[image_path] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_sales_bag] ADD CONSTRAINT [PK__cvo_sales_bag__0FAB9435] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
