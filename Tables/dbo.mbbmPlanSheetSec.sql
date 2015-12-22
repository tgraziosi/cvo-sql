CREATE TABLE [dbo].[mbbmPlanSheetSec]
(
[TimeStamp] [timestamp] NOT NULL,
[SheetID] [int] NOT NULL,
[UserID] [dbo].[mbbmudtUser] NOT NULL,
[SecLevel] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmPlanSheetSec] ADD CONSTRAINT [PK_mbbmPlanSheetSec] PRIMARY KEY CLUSTERED  ([SheetID], [UserID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmPlanSheetSec] ADD CONSTRAINT [FK_mbbmPlanSheetSec_SheetID] FOREIGN KEY ([SheetID]) REFERENCES [dbo].[mbbmPlanSheet74] ([SheetID])
GO
EXEC sp_bindefault N'[dbo].[mbbmdefEmpty]', N'[dbo].[mbbmPlanSheetSec].[UserID]'
GO
GRANT REFERENCES ON  [dbo].[mbbmPlanSheetSec] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmPlanSheetSec] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmPlanSheetSec] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmPlanSheetSec] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmPlanSheetSec] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmPlanSheetSec] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmPlanSheetSec] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmPlanSheetSec] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmPlanSheetSec] TO [public]
GO
