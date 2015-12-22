CREATE TABLE [dbo].[distr_custbtn]
(
[timestamp] [timestamp] NOT NULL,
[app_zoom_id] [smallint] NOT NULL,
[window_nm] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[btn_id] [int] NOT NULL,
[btn_txt] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[btn_order] [int] NOT NULL CONSTRAINT [DF__distr_cus__btn_o__62317A46] DEFAULT ((0)),
[btn_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[expl_vw_nm] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[row_id] [int] NOT NULL IDENTITY(1, 1),
[ext_path] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sec_lvl] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [custbtn_0] ON [dbo].[distr_custbtn] ([app_zoom_id], [btn_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[distr_custbtn] TO [public]
GO
GRANT SELECT ON  [dbo].[distr_custbtn] TO [public]
GO
GRANT INSERT ON  [dbo].[distr_custbtn] TO [public]
GO
GRANT DELETE ON  [dbo].[distr_custbtn] TO [public]
GO
GRANT UPDATE ON  [dbo].[distr_custbtn] TO [public]
GO
