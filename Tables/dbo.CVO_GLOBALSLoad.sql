CREATE TABLE [dbo].[CVO_GLOBALSLoad]
(
[row] [int] NOT NULL IDENTITY(1, 1),
[CODE] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ID] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SCODE] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[NAME] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ADDR1] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ADDR2] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[F7] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CITY] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ST] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ZIP] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TEL] [float] NULL,
[CON] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SVIA] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FAX] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SVCHG] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FRTCHG] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[INTL] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[COUNTRY] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[COM%] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TX1] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TX2] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TX3] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SCTBL] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RTE] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SHPTOLAB] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SMGR] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MGRSCTBL] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RXSVIA] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[CVO_GLOBALSLoad] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_GLOBALSLoad] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_GLOBALSLoad] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_GLOBALSLoad] TO [public]
GO
