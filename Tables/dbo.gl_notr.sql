CREATE TABLE [dbo].[gl_notr]
(
[timestamp] [timestamp] NOT NULL,
[country_code] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[neg_flag_total] [smallint] NOT NULL,
[f_notr_code] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[s_notr_code] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[notr_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [gl_notr_0] ON [dbo].[gl_notr] ([country_code], [f_notr_code], [s_notr_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[gl_notr] TO [public]
GO
GRANT SELECT ON  [dbo].[gl_notr] TO [public]
GO
GRANT INSERT ON  [dbo].[gl_notr] TO [public]
GO
GRANT DELETE ON  [dbo].[gl_notr] TO [public]
GO
GRANT UPDATE ON  [dbo].[gl_notr] TO [public]
GO
