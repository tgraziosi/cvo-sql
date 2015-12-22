CREATE TABLE [dbo].[distr_custbtn_dtl]
(
[timestamp] [timestamp] NOT NULL,
[app_zoom_id] [smallint] NOT NULL,
[btn_id] [int] NOT NULL,
[dw_nm] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[col_nm] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[operator] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[expl_col_name] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[row_id] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [custbtndtl_0] ON [dbo].[distr_custbtn_dtl] ([app_zoom_id], [btn_id], [expl_col_name], [dw_nm], [col_nm]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[distr_custbtn_dtl] TO [public]
GO
GRANT SELECT ON  [dbo].[distr_custbtn_dtl] TO [public]
GO
GRANT INSERT ON  [dbo].[distr_custbtn_dtl] TO [public]
GO
GRANT DELETE ON  [dbo].[distr_custbtn_dtl] TO [public]
GO
GRANT UPDATE ON  [dbo].[distr_custbtn_dtl] TO [public]
GO
