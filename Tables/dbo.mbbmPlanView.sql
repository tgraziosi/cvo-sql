CREATE TABLE [dbo].[mbbmPlanView]
(
[HostCompany] [dbo].[mbbmudtCompanyCode] NOT NULL,
[SheetID] [int] NOT NULL,
[GroupKey] [dbo].[mbbmudtGroupKey] NOT NULL,
[Type] [int] NOT NULL,
[Value] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmPlanView] ADD CONSTRAINT [PK_mbbmPlanView] PRIMARY KEY CLUSTERED  ([HostCompany], [SheetID], [GroupKey], [Type]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[mbbmPlanView] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmPlanView] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmPlanView] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmPlanView] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmPlanView] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmPlanView] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmPlanView] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmPlanView] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmPlanView] TO [public]
GO
