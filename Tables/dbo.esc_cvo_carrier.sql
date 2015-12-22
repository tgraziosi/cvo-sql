CREATE TABLE [dbo].[esc_cvo_carrier]
(
[Carrier] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CarrierDescription] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MAX $] [float] NULL,
[MAX WEIGHT] [float] NULL,
[CLIPPERSHIP CODE] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CLIPPERSHIP DESCRIPTION] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[esc_cvo_carrier] TO [public]
GO
GRANT INSERT ON  [dbo].[esc_cvo_carrier] TO [public]
GO
GRANT DELETE ON  [dbo].[esc_cvo_carrier] TO [public]
GO
GRANT UPDATE ON  [dbo].[esc_cvo_carrier] TO [public]
GO
