CREATE TABLE [dbo].[nbtrxlogdesc]
(
[timestamp] [timestamp] NOT NULL,
[log_description] [varchar] (180) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[step] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[substep] [smallint] NOT NULL,
[error] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [nbtrxrel_ind_0] ON [dbo].[nbtrxlogdesc] ([step], [substep]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[nbtrxlogdesc] TO [public]
GO
GRANT SELECT ON  [dbo].[nbtrxlogdesc] TO [public]
GO
GRANT INSERT ON  [dbo].[nbtrxlogdesc] TO [public]
GO
GRANT DELETE ON  [dbo].[nbtrxlogdesc] TO [public]
GO
GRANT UPDATE ON  [dbo].[nbtrxlogdesc] TO [public]
GO
