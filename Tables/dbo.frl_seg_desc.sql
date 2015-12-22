CREATE TABLE [dbo].[frl_seg_desc]
(
[seg_code] [char] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[entity_num] [smallint] NOT NULL,
[seg_num] [tinyint] NOT NULL,
[seg_code_desc] [char] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[seg_short_desc] [char] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [XIE1frl_seg_desc] ON [dbo].[frl_seg_desc] ([entity_num], [seg_num]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [XPKfrl_seg_desc] ON [dbo].[frl_seg_desc] ([seg_code], [entity_num], [seg_num]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[frl_seg_desc] TO [public]
GO
GRANT SELECT ON  [dbo].[frl_seg_desc] TO [public]
GO
GRANT INSERT ON  [dbo].[frl_seg_desc] TO [public]
GO
GRANT DELETE ON  [dbo].[frl_seg_desc] TO [public]
GO
GRANT UPDATE ON  [dbo].[frl_seg_desc] TO [public]
GO
