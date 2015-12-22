CREATE TABLE [dbo].[gl_identcurcvt]
(
[timestamp] [timestamp] NOT NULL,
[currency_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rpt_cur_ident] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [gl_identcurcvt_0] ON [dbo].[gl_identcurcvt] ([currency_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[gl_identcurcvt] TO [public]
GO
GRANT SELECT ON  [dbo].[gl_identcurcvt] TO [public]
GO
GRANT INSERT ON  [dbo].[gl_identcurcvt] TO [public]
GO
GRANT DELETE ON  [dbo].[gl_identcurcvt] TO [public]
GO
GRANT UPDATE ON  [dbo].[gl_identcurcvt] TO [public]
GO
