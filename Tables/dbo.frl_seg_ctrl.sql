CREATE TABLE [dbo].[frl_seg_ctrl]
(
[entity_num] [smallint] NOT NULL,
[seg_num] [tinyint] NOT NULL,
[seg_desc] [char] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seg_length] [tinyint] NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [XIE1frl_seg_ctrl] ON [dbo].[frl_seg_ctrl] ([entity_num]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [XPKfrl_seg_ctrl] ON [dbo].[frl_seg_ctrl] ([entity_num], [seg_num]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[frl_seg_ctrl] TO [public]
GO
GRANT SELECT ON  [dbo].[frl_seg_ctrl] TO [public]
GO
GRANT INSERT ON  [dbo].[frl_seg_ctrl] TO [public]
GO
GRANT DELETE ON  [dbo].[frl_seg_ctrl] TO [public]
GO
GRANT UPDATE ON  [dbo].[frl_seg_ctrl] TO [public]
GO
