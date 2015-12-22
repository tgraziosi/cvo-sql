CREATE TABLE [dbo].[gl_cmdty]
(
[timestamp] [timestamp] NOT NULL,
[cmdty_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rpt_flag_esl] [smallint] NOT NULL,
[rpt_flag_int] [smallint] NOT NULL,
[weight_flag] [smallint] NOT NULL,
[supp_unit_flag] [smallint] NOT NULL,
[weight_uom] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[supp_uom] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cmdty_desc_1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cmdty_desc_2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cmdty_desc_3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cmdty_desc_4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cmdty_desc_5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [gl_cmdty_0] ON [dbo].[gl_cmdty] ([cmdty_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[gl_cmdty] TO [public]
GO
GRANT SELECT ON  [dbo].[gl_cmdty] TO [public]
GO
GRANT INSERT ON  [dbo].[gl_cmdty] TO [public]
GO
GRANT DELETE ON  [dbo].[gl_cmdty] TO [public]
GO
GRANT UPDATE ON  [dbo].[gl_cmdty] TO [public]
GO
