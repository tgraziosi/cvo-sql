CREATE TABLE [dbo].[mbbmTemplateSheets]
(
[TimeStamp] [timestamp] NOT NULL,
[PlanID] [int] NOT NULL,
[SheetID] [int] NOT NULL,
[SheetKey] [dbo].[mbbmudtSubBudgetKey] NOT NULL,
[Description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SheetManager] [dbo].[mbbmudtUser] NOT NULL,
[HostCompany] [dbo].[mbbmudtCompanyCode] NOT NULL,
[Status] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[RevisionKey] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[CreatedBy] [dbo].[mbbmudtUser] NOT NULL,
[CreatedTime] [dbo].[mbbmudtTagDate] NOT NULL,
[UpdatedBy] [dbo].[mbbmudtUser] NOT NULL,
[UpdatedTime] [dbo].[mbbmudtTagDate] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE TRIGGER [dbo].[mbbmTemplateSheets_Ins] ON [dbo].[mbbmTemplateSheets] FOR INSERT 
AS
BEGIN
/************************************************************************************
* Copyright 2008 Sage Software, Inc. All rights reserved.                           *
* This procedure, trigger or view is the intellectual property of Sage Software,    *
* Inc.  You may not reverse engineer, alter, or redistribute this code without the  *
* express written permission of Sage Software, Inc.  This code, or any portions of  *
* it, may not be used for any other purpose except for the use of the application   *
* software that it was shipped with.  This code falls under the licensing agreement *
* shipped with the software.  See your license agreement for further information.   *
************************************************************************************/
	UPDATE  mbbmTemplateSheets
	SET	mbbmTemplateSheets.CreatedBy	= (SELECT hostname FROM master..sysprocesses WHERE spid = @@SPID),
		mbbmTemplateSheets.CreatedTime	= GETDATE(),
		mbbmTemplateSheets.UpdatedBy	= (SELECT hostname FROM master..sysprocesses WHERE spid = @@SPID),
		mbbmTemplateSheets.UpdatedTime	= GETDATE()
	FROM    mbbmTemplateSheets, inserted 
	WHERE   mbbmTemplateSheets.PlanID	= inserted.PlanID AND
		mbbmTemplateSheets.SheetID	= inserted.SheetID AND   
		mbbmTemplateSheets.SheetKey	= inserted.SheetKey
END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE TRIGGER [dbo].[mbbmTemplateSheets_Upd] ON [dbo].[mbbmTemplateSheets] FOR UPDATE 
AS
BEGIN
/************************************************************************************
* Copyright 2008 Sage Software, Inc. All rights reserved.                           *
* This procedure, trigger or view is the intellectual property of Sage Software,    *
* Inc.  You may not reverse engineer, alter, or redistribute this code without the  *
* express written permission of Sage Software, Inc.  This code, or any portions of  *
* it, may not be used for any other purpose except for the use of the application   *
* software that it was shipped with.  This code falls under the licensing agreement *
* shipped with the software.  See your license agreement for further information.   *
************************************************************************************/
	IF (Update(UpdatedBy) OR Update(UpdatedTime)) RETURN --DS 11/28/2009 for recursive triggers on problem per Andy

	UPDATE  mbbmTemplateSheets
	SET     mbbmTemplateSheets.UpdatedBy	= (SELECT hostname FROM master..sysprocesses WHERE spid = @@SPID),
		mbbmTemplateSheets.UpdatedTime	= GETDATE()
	FROM    mbbmTemplateSheets, inserted 
	WHERE   mbbmTemplateSheets.PlanID	= inserted.PlanID AND
		mbbmTemplateSheets.SheetID	= inserted.SheetID AND   
		mbbmTemplateSheets.SheetKey	= inserted.SheetKey
END
GO
ALTER TABLE [dbo].[mbbmTemplateSheets] ADD CONSTRAINT [UK_mbbmTemplateSheets] UNIQUE NONCLUSTERED  ([PlanID], [SheetID], [SheetKey]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmTemplateSheets] ADD CONSTRAINT [FK_mbbmTemplateValues_Status] FOREIGN KEY ([HostCompany], [Status]) REFERENCES [dbo].[mbbmSheetStatusCode6] ([HostCompany], [Code])
GO
ALTER TABLE [dbo].[mbbmTemplateSheets] ADD CONSTRAINT [FK_mbbmTemplateSheets_PlanID] FOREIGN KEY ([PlanID]) REFERENCES [dbo].[mbbmPlan74] ([PlanID])
GO
ALTER TABLE [dbo].[mbbmTemplateSheets] ADD CONSTRAINT [FK_mbbmTemplateSheets_SheetID] FOREIGN KEY ([SheetID]) REFERENCES [dbo].[mbbmPlanSheet74] ([SheetID])
GO
EXEC sp_bindefault N'[dbo].[mbbmdefEmpty]', N'[dbo].[mbbmTemplateSheets].[SheetManager]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefEmpty]', N'[dbo].[mbbmTemplateSheets].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefDate]', N'[dbo].[mbbmTemplateSheets].[CreatedTime]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefEmpty]', N'[dbo].[mbbmTemplateSheets].[UpdatedBy]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefDate]', N'[dbo].[mbbmTemplateSheets].[UpdatedTime]'
GO
GRANT REFERENCES ON  [dbo].[mbbmTemplateSheets] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmTemplateSheets] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmTemplateSheets] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmTemplateSheets] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmTemplateSheets] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmTemplateSheets] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmTemplateSheets] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmTemplateSheets] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmTemplateSheets] TO [public]
GO
