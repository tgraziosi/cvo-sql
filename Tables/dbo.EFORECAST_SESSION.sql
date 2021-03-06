CREATE TABLE [dbo].[EFORECAST_SESSION]
(
[SESSIONID] [int] NOT NULL,
[SESSTIMESTAMP] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[FOREDESC] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AUTHOR] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TAG] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SESSNOTE] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[EFORECAST_SESSION] ADD CONSTRAINT [PK_EFORECAST_SESSION] PRIMARY KEY CLUSTERED  ([SESSIONID]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[EFORECAST_SESSION] TO [epicoradmin]
GO
GRANT INSERT ON  [dbo].[EFORECAST_SESSION] TO [epicoradmin]
GO
GRANT DELETE ON  [dbo].[EFORECAST_SESSION] TO [epicoradmin]
GO
GRANT UPDATE ON  [dbo].[EFORECAST_SESSION] TO [epicoradmin]
GO
GRANT REFERENCES ON  [dbo].[EFORECAST_SESSION] TO [public]
GO
GRANT SELECT ON  [dbo].[EFORECAST_SESSION] TO [public]
GO
GRANT INSERT ON  [dbo].[EFORECAST_SESSION] TO [public]
GO
GRANT DELETE ON  [dbo].[EFORECAST_SESSION] TO [public]
GO
GRANT UPDATE ON  [dbo].[EFORECAST_SESSION] TO [public]
GO
