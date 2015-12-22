CREATE TABLE [dbo].[adm_custom_datawindow]
(
[timestamp] [timestamp] NOT NULL,
[window_nm] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[datawindow_nm] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[typ_ind] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seq_id] [int] NOT NULL,
[syntax_tx] [varchar] (7500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [acd_i1] ON [dbo].[adm_custom_datawindow] ([window_nm], [datawindow_nm], [typ_ind], [seq_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[adm_custom_datawindow] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_custom_datawindow] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_custom_datawindow] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_custom_datawindow] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_custom_datawindow] TO [public]
GO
