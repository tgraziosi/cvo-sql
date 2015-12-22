CREATE TABLE [dbo].[cvo_vision_expo_order_lines]
(
[hs_order_no] [int] NULL,
[territory] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sku] [char] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty] [int] NULL,
[category] [char] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[manufacturer] [char] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[model] [char] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[color] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dimension] [char] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[res_type] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[expo_id] [int] NULL,
[brand] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[id] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_vision_expo_order_lines] ADD CONSTRAINT [PK__cvo_vision_expo___549424B1] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
