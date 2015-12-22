CREATE TABLE [dbo].[distr_zoomfld]
(
[timestamp] [timestamp] NOT NULL,
[app_zoom_id] [smallint] NOT NULL,
[zoom_id] [int] NOT NULL,
[col_number] [smallint] NOT NULL,
[field_name] [char] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[field_type] [smallint] NOT NULL,
[display] [smallint] NOT NULL,
[field_width] [smallint] NOT NULL,
[header] [varchar] (39) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[mask] [varchar] (99) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[return_to] [varchar] (31) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sort_by] [smallint] NOT NULL,
[sec_sort_col] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [zoomfld_0] ON [dbo].[distr_zoomfld] ([app_zoom_id], [zoom_id], [col_number]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[distr_zoomfld] TO [public]
GO
GRANT INSERT ON  [dbo].[distr_zoomfld] TO [public]
GO
GRANT DELETE ON  [dbo].[distr_zoomfld] TO [public]
GO
GRANT UPDATE ON  [dbo].[distr_zoomfld] TO [public]
GO
