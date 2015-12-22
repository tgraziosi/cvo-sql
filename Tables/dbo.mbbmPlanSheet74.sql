CREATE TABLE [dbo].[mbbmPlanSheet74]
(
[TimeStamp] [timestamp] NOT NULL,
[HostCompany] [dbo].[mbbmudtCompanyCode] NOT NULL,
[SheetID] [int] NOT NULL CONSTRAINT [DF__mbbmPlanS__Sheet__20CACFAB] DEFAULT ((0)),
[PlanID] [int] NOT NULL,
[SheetKey] [dbo].[mbbmudtSubBudgetKey] NOT NULL,
[ActiveRevision] [int] NOT NULL,
[SheetManager] [dbo].[mbbmudtUser] NOT NULL,
[Description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Status] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Locked] [dbo].[mbbmudtYesNo] NOT NULL,
[OfflineLocked] [dbo].[mbbmudtYesNo] NOT NULL,
[Parent] [int] NOT NULL,
[SheetType] [int] NOT NULL,
[FileName] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[MergeType] [tinyint] NOT NULL,
[RangeName] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Sheet] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[CellReference] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[IncludeUnposted] [dbo].[mbbmudtYesNo] NOT NULL,
[IncludePendingAlloc] [dbo].[mbbmudtYesNo] NOT NULL,
[AcctNameDesc] [dbo].[mbbmudtYesNo] NOT NULL,
[AcctNameSpacing] [tinyint] NOT NULL,
[LastPublished] [smalldatetime] NULL,
[InternetEnabled] [tinyint] NOT NULL,
[GeneratedBy] [int] NOT NULL,
[PlanFlowCalculation] [int] NOT NULL,
[Publish] [dbo].[mbbmudtYesNo] NOT NULL,
[ExcelFileDate] [datetime] NULL,
[TemplateLastRowID] [int] NOT NULL,
[TemplateSlaveAutoLock] [dbo].[mbbmudtYesNo] NOT NULL,
[CreatedBy] [dbo].[mbbmudtUser] NOT NULL,
[CreatedTime] [dbo].[mbbmudtTagDate] NOT NULL,
[UpdatedBy] [dbo].[mbbmudtUser] NOT NULL,
[UpdatedTime] [dbo].[mbbmudtTagDate] NOT NULL,
[UploadCompany] [dbo].[mbbmudtCompanyCode] NOT NULL,
[CheckedOut] [int] NOT NULL,
[CheckedOutTo] [dbo].[mbbmudtUser] NOT NULL,
[CheckedOutProcessID] [int] NOT NULL,
[CheckedOutProcessType] [int] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE TRIGGER [dbo].[mbbmPlanSheet74_Ins] ON [dbo].[mbbmPlanSheet74] FOR INSERT 
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
	DECLARE @NewSheetID int

	SELECT  @NewSheetID = ISNULL(MAX(SheetID), 0) + 1
	FROM	mbbmPlanSheet74

	UPDATE  mbbmPlanSheet74
	SET     mbbmPlanSheet74.SheetID		= @NewSheetID,
		mbbmPlanSheet74.CreatedBy		= (SELECT hostname FROM master..sysprocesses WHERE spid = @@SPID),
		mbbmPlanSheet74.CreatedTime	= GETDATE(),
		mbbmPlanSheet74.UpdatedBy		= (SELECT hostname FROM master..sysprocesses WHERE spid = @@SPID),
		mbbmPlanSheet74.UpdatedTime	= GETDATE()
	FROM    mbbmPlanSheet74, inserted 
	WHERE   mbbmPlanSheet74.SheetID		= inserted.SheetID

END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE TRIGGER [dbo].[mbbmPlanSheet74_Upd] ON [dbo].[mbbmPlanSheet74] FOR UPDATE 
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

	UPDATE  mbbmPlanSheet74
	SET     mbbmPlanSheet74.UpdatedBy		= (SELECT hostname FROM master..sysprocesses WHERE spid = @@SPID),
		mbbmPlanSheet74.UpdatedTime	= GETDATE()
	FROM    mbbmPlanSheet74, inserted 
	WHERE   mbbmPlanSheet74.SheetID		= inserted.SheetID

END
GO
ALTER TABLE [dbo].[mbbmPlanSheet74] ADD CONSTRAINT [PK_mbbmPlanSheet74] PRIMARY KEY CLUSTERED  ([SheetID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmPlanSheet74] ADD CONSTRAINT [UK_mbbmPlanSheet74] UNIQUE NONCLUSTERED  ([PlanID], [SheetKey]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmPlanSheet74] ADD CONSTRAINT [FK_mbbmPlanSheet74_Status] FOREIGN KEY ([HostCompany], [Status]) REFERENCES [dbo].[mbbmSheetStatusCode6] ([HostCompany], [Code])
GO
ALTER TABLE [dbo].[mbbmPlanSheet74] ADD CONSTRAINT [FK_mbbmPlanSheet74_PlanID] FOREIGN KEY ([PlanID]) REFERENCES [dbo].[mbbmPlan74] ([PlanID])
GO
EXEC sp_bindefault N'[dbo].[mbbmdefEmpty]', N'[dbo].[mbbmPlanSheet74].[SheetManager]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmPlanSheet74].[Locked]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmPlanSheet74].[Locked]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmPlanSheet74].[OfflineLocked]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmPlanSheet74].[OfflineLocked]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmPlanSheet74].[IncludeUnposted]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmPlanSheet74].[IncludeUnposted]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmPlanSheet74].[IncludePendingAlloc]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmPlanSheet74].[IncludePendingAlloc]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmPlanSheet74].[AcctNameDesc]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmPlanSheet74].[AcctNameDesc]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmPlanSheet74].[Publish]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmPlanSheet74].[Publish]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmPlanSheet74].[TemplateSlaveAutoLock]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmPlanSheet74].[TemplateSlaveAutoLock]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefEmpty]', N'[dbo].[mbbmPlanSheet74].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefDate]', N'[dbo].[mbbmPlanSheet74].[CreatedTime]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefEmpty]', N'[dbo].[mbbmPlanSheet74].[UpdatedBy]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefDate]', N'[dbo].[mbbmPlanSheet74].[UpdatedTime]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefEmpty]', N'[dbo].[mbbmPlanSheet74].[CheckedOutTo]'
GO
GRANT REFERENCES ON  [dbo].[mbbmPlanSheet74] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmPlanSheet74] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmPlanSheet74] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmPlanSheet74] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmPlanSheet74] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmPlanSheet74] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmPlanSheet74] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmPlanSheet74] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmPlanSheet74] TO [public]
GO
