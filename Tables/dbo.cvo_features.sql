CREATE TABLE [dbo].[cvo_features]
(
[Feature_Id] [int] NOT NULL,
[Feature_Desc] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Feature_Group] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [cvo_features_idx0] ON [dbo].[cvo_features] ([Feature_Id], [Feature_Desc], [Feature_Group]) ON [PRIMARY]
GO
