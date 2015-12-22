CREATE TABLE [dbo].[ewimages]
(
[image_id] [int] NOT NULL,
[image_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[image] [image] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [ewimages_ind_0] ON [dbo].[ewimages] ([image_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[ewimages] TO [public]
GO
GRANT SELECT ON  [dbo].[ewimages] TO [public]
GO
GRANT INSERT ON  [dbo].[ewimages] TO [public]
GO
GRANT DELETE ON  [dbo].[ewimages] TO [public]
GO
GRANT UPDATE ON  [dbo].[ewimages] TO [public]
GO
