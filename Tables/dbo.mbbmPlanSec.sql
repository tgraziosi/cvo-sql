CREATE TABLE [dbo].[mbbmPlanSec]
(
[TimeStamp] [timestamp] NOT NULL,
[PlanID] [int] NOT NULL,
[UserID] [dbo].[mbbmudtUser] NOT NULL,
[SecLevel] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmPlanSec] ADD CONSTRAINT [PK_mbbmPlanSec] PRIMARY KEY CLUSTERED  ([PlanID], [UserID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmPlanSec] ADD CONSTRAINT [FK_mbbmPlanSec_PlanID] FOREIGN KEY ([PlanID]) REFERENCES [dbo].[mbbmPlan74] ([PlanID])
GO
EXEC sp_bindefault N'[dbo].[mbbmdefEmpty]', N'[dbo].[mbbmPlanSec].[UserID]'
GO
GRANT REFERENCES ON  [dbo].[mbbmPlanSec] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmPlanSec] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmPlanSec] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmPlanSec] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmPlanSec] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmPlanSec] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmPlanSec] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmPlanSec] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmPlanSec] TO [public]
GO
