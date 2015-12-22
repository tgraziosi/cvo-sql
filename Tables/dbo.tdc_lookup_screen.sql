CREATE TABLE [dbo].[tdc_lookup_screen]
(
[Language] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Screen_Size] [varchar] (7) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Trans] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Element] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Indexes] [int] NOT NULL,
[Height] [int] NOT NULL,
[Width] [int] NOT NULL,
[Top_] [int] NOT NULL,
[Left_] [int] NOT NULL,
[Enable] [int] NULL,
[Enable_Border] [int] NULL,
[Text_] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [tdc_lookup_screen_Index] ON [dbo].[tdc_lookup_screen] ([Trans], [Element], [Indexes], [Language], [Screen_Size]) WITH (FILLFACTOR=100) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_lookup_screen] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_lookup_screen] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_lookup_screen] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_lookup_screen] TO [public]
GO
