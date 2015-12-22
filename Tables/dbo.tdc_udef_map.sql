CREATE TABLE [dbo].[tdc_udef_map]
(
[screen_name] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[column_name] [varchar] (62) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[udef_label] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[data_type] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[data_width] [int] NULL,
[description] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [tdc_udef_idx] ON [dbo].[tdc_udef_map] ([screen_name], [column_name]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_udef_map] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_udef_map] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_udef_map] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_udef_map] TO [public]
GO
