CREATE TABLE [dbo].[mbbmPlan74]
(
[TimeStamp] [timestamp] NOT NULL,
[HostCompany] [dbo].[mbbmudtCompanyCode] NOT NULL,
[PlanID] [int] NOT NULL CONSTRAINT [DF__mbbmPlan7__PlanI__1464F8C6] DEFAULT ((0)),
[PlanKey] [dbo].[mbbmudtBudgetKey] NOT NULL,
[Description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[PlanManager] [dbo].[mbbmudtUser] NOT NULL,
[PrimarySheet] [int] NOT NULL,
[CreatedBy] [dbo].[mbbmudtUser] NOT NULL,
[CreatedTime] [dbo].[mbbmudtTagDate] NOT NULL,
[UpdatedBy] [dbo].[mbbmudtUser] NOT NULL,
[UpdatedTime] [dbo].[mbbmudtTagDate] NOT NULL,
[PlanPublish] [dbo].[mbbmudtYesNo] NOT NULL,
[PlanDate] [datetime] NOT NULL,
[AllowSheetCheckOut] [dbo].[mbbmudtYesNo] NOT NULL,
[PlanBudgetCode] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE TRIGGER [dbo].[mbbmPlan74_Ins] ON [dbo].[mbbmPlan74] FOR INSERT 
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
	DECLARE @NewPlanID int

	SELECT  @NewPlanID = ISNULL(MAX(PlanID), 0) + 1
	FROM	mbbmPlan74

	UPDATE  mbbmPlan74
	SET     mbbmPlan74.PlanID		= @NewPlanID,
		mbbmPlan74.CreatedBy	= (SELECT hostname FROM master..sysprocesses WHERE spid = @@SPID),
		mbbmPlan74.CreatedTime	= GETDATE(),
		mbbmPlan74.UpdatedBy	= (SELECT hostname FROM master..sysprocesses WHERE spid = @@SPID),
		mbbmPlan74.UpdatedTime	= GETDATE()
	FROM    mbbmPlan74, inserted
	WHERE   mbbmPlan74.PlanID 	= inserted.PlanID

END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE TRIGGER [dbo].[mbbmPlan74_Upd] ON [dbo].[mbbmPlan74] FOR UPDATE 
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

	UPDATE  mbbmPlan74
	SET     mbbmPlan74.UpdatedBy	= (SELECT hostname FROM master..sysprocesses WHERE spid = @@SPID),
		mbbmPlan74.UpdatedTime	= GETDATE()
	FROM    mbbmPlan74, inserted 
	WHERE   mbbmPlan74.PlanID		= inserted.PlanID

END
GO
ALTER TABLE [dbo].[mbbmPlan74] ADD CONSTRAINT [PK_mbbmPlan74] PRIMARY KEY CLUSTERED  ([PlanID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmPlan74] ADD CONSTRAINT [UK_mbbmPlan74] UNIQUE NONCLUSTERED  ([HostCompany], [PlanKey]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[mbbmdefEmpty]', N'[dbo].[mbbmPlan74].[PlanManager]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefEmpty]', N'[dbo].[mbbmPlan74].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefDate]', N'[dbo].[mbbmPlan74].[CreatedTime]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefEmpty]', N'[dbo].[mbbmPlan74].[UpdatedBy]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefDate]', N'[dbo].[mbbmPlan74].[UpdatedTime]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmPlan74].[PlanPublish]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmPlan74].[PlanPublish]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmPlan74].[AllowSheetCheckOut]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmPlan74].[AllowSheetCheckOut]'
GO
GRANT REFERENCES ON  [dbo].[mbbmPlan74] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmPlan74] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmPlan74] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmPlan74] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmPlan74] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmPlan74] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmPlan74] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmPlan74] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmPlan74] TO [public]
GO
