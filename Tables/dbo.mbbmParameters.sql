CREATE TABLE [dbo].[mbbmParameters]
(
[TimeStamp] [timestamp] NOT NULL,
[HostCompany] [dbo].[mbbmudtCompanyCode] NOT NULL,
[Parameter] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SortKey] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Prompt] [dbo].[mbbmudtYesNo] NOT NULL,
[Parameters] [image] NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmParameters] ADD CONSTRAINT [PK_mbbmParameters] PRIMARY KEY CLUSTERED  ([HostCompany], [Parameter], [SortKey]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmParameters].[Prompt]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmParameters].[Prompt]'
GO
GRANT REFERENCES ON  [dbo].[mbbmParameters] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmParameters] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmParameters] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmParameters] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmParameters] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmParameters] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmParameters] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmParameters] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmParameters] TO [public]
GO
