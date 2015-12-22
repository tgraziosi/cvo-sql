CREATE TABLE [dbo].[distr_zoomind]
(
[timestamp] [timestamp] NOT NULL,
[window_nm] [char] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[datawin_nm] [char] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[col_nm] [char] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[app_zoom_id] [smallint] NOT NULL,
[zoom_id] [int] NOT NULL,
[match_col] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[condition] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[row_id] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [zoomind_2] ON [dbo].[distr_zoomind] ([app_zoom_id], [zoom_id]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [zoomind_0] ON [dbo].[distr_zoomind] ([window_nm], [datawin_nm], [col_nm], [app_zoom_id], [zoom_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [zoomind_1] ON [dbo].[distr_zoomind] ([window_nm], [datawin_nm], [col_nm], [app_zoom_id], [zoom_id]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[distr_zoomind] TO [public]
GO
GRANT INSERT ON  [dbo].[distr_zoomind] TO [public]
GO
GRANT DELETE ON  [dbo].[distr_zoomind] TO [public]
GO
GRANT UPDATE ON  [dbo].[distr_zoomind] TO [public]
GO
