CREATE TABLE [dbo].[gl_country]
(
[timestamp] [timestamp] NOT NULL,
[country_code] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ec_member] [smallint] NOT NULL,
[weight_code] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [gl_country_0] ON [dbo].[gl_country] ([country_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[gl_country] TO [public]
GO
GRANT SELECT ON  [dbo].[gl_country] TO [public]
GO
GRANT INSERT ON  [dbo].[gl_country] TO [public]
GO
GRANT DELETE ON  [dbo].[gl_country] TO [public]
GO
GRANT UPDATE ON  [dbo].[gl_country] TO [public]
GO
