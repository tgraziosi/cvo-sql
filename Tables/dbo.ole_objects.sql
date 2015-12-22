CREATE TABLE [dbo].[ole_objects]
(
[timestamp] [timestamp] NOT NULL,
[ole_id] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[object] [image] NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[control_num] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[link_id] [varchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[ole_objects] TO [public]
GO
GRANT SELECT ON  [dbo].[ole_objects] TO [public]
GO
GRANT INSERT ON  [dbo].[ole_objects] TO [public]
GO
GRANT DELETE ON  [dbo].[ole_objects] TO [public]
GO
GRANT UPDATE ON  [dbo].[ole_objects] TO [public]
GO
