CREATE TABLE [dbo].[gl_glnotr]
(
[timestamp] [timestamp] NOT NULL,
[country_code] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[src_trx_id] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rpt_flag_esl] [smallint] NOT NULL,
[neg_flag_esl] [smallint] NOT NULL,
[disp_flow_flag] [smallint] NOT NULL,
[disp_f_notr_code] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[disp_s_notr_code] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[arr_flow_flag] [smallint] NOT NULL,
[arr_f_notr_code] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[arr_s_notr_code] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[stat_manner] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[regime] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [gl_glnotr_0] ON [dbo].[gl_glnotr] ([country_code], [src_trx_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[gl_glnotr] TO [public]
GO
GRANT SELECT ON  [dbo].[gl_glnotr] TO [public]
GO
GRANT INSERT ON  [dbo].[gl_glnotr] TO [public]
GO
GRANT DELETE ON  [dbo].[gl_glnotr] TO [public]
GO
GRANT UPDATE ON  [dbo].[gl_glnotr] TO [public]
GO
