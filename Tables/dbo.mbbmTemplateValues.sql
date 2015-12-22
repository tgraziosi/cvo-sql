CREATE TABLE [dbo].[mbbmTemplateValues]
(
[TimeStamp] [timestamp] NOT NULL,
[PlanID] [int] NOT NULL,
[SheetID] [int] NOT NULL,
[SheetKey] [dbo].[mbbmudtSubBudgetKey] NOT NULL,
[SectionKey] [dbo].[mbbmudtSubBudgetKey] NOT NULL,
[DimCode] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SegmentNum] [int] NOT NULL,
[FromValue] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ThruValue] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[AllFlag] [dbo].[mbbmudtYesNo] NOT NULL,
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
CREATE TRIGGER [dbo].[mbbmTemplateValues_Ins] ON [dbo].[mbbmTemplateValues] FOR INSERT 
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
	UPDATE  mbbmTemplateValues
	SET	mbbmTemplateValues.CreatedBy	= (SELECT hostname FROM master..sysprocesses WHERE spid = @@SPID),
		mbbmTemplateValues.CreatedTime	= GETDATE(),
		mbbmTemplateValues.UpdatedBy	= (SELECT hostname FROM master..sysprocesses WHERE spid = @@SPID),
		mbbmTemplateValues.UpdatedTime	= GETDATE()
	FROM    mbbmTemplateValues, inserted 
	WHERE   mbbmTemplateValues.PlanID	= inserted.PlanID AND
		mbbmTemplateValues.SheetID	= inserted.SheetID AND   
		mbbmTemplateValues.SheetKey	= inserted.SheetKey AND   
		mbbmTemplateValues.SectionKey	= inserted.SectionKey AND   
		mbbmTemplateValues.DimCode	= inserted.DimCode AND   
		mbbmTemplateValues.SegmentNum	= inserted.SegmentNum

END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE TRIGGER [dbo].[mbbmTemplateValues_Upd] ON [dbo].[mbbmTemplateValues] FOR UPDATE 
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

	UPDATE  mbbmTemplateValues
	SET     mbbmTemplateValues.UpdatedBy	= (SELECT hostname FROM master..sysprocesses WHERE spid = @@SPID),
		mbbmTemplateValues.UpdatedTime	= GETDATE()
	FROM    mbbmTemplateValues, inserted 
	WHERE   mbbmTemplateValues.PlanID	= inserted.PlanID AND
		mbbmTemplateValues.SheetID	= inserted.SheetID AND   
		mbbmTemplateValues.SheetKey	= inserted.SheetKey AND   
		mbbmTemplateValues.SectionKey	= inserted.SectionKey AND   
		mbbmTemplateValues.DimCode	= inserted.DimCode AND   
		mbbmTemplateValues.SegmentNum	= inserted.SegmentNum

END
GO
ALTER TABLE [dbo].[mbbmTemplateValues] ADD CONSTRAINT [UK_mbbmTemplateValues] UNIQUE NONCLUSTERED  ([PlanID], [SheetID], [SheetKey], [SectionKey], [DimCode], [SegmentNum]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmTemplateValues] ADD CONSTRAINT [FK_mbbmTemplateValues_PlanID] FOREIGN KEY ([PlanID]) REFERENCES [dbo].[mbbmPlan74] ([PlanID])
GO
ALTER TABLE [dbo].[mbbmTemplateValues] ADD CONSTRAINT [FK_mbbmTemplateValues_Sheet] FOREIGN KEY ([PlanID], [SheetID], [SheetKey]) REFERENCES [dbo].[mbbmTemplateSheets] ([PlanID], [SheetID], [SheetKey])
GO
ALTER TABLE [dbo].[mbbmTemplateValues] ADD CONSTRAINT [FK_mbbmTemplateValues_SheetID] FOREIGN KEY ([SheetID]) REFERENCES [dbo].[mbbmPlanSheet74] ([SheetID])
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmTemplateValues].[AllFlag]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmTemplateValues].[AllFlag]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefEmpty]', N'[dbo].[mbbmTemplateValues].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefDate]', N'[dbo].[mbbmTemplateValues].[CreatedTime]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefEmpty]', N'[dbo].[mbbmTemplateValues].[UpdatedBy]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefDate]', N'[dbo].[mbbmTemplateValues].[UpdatedTime]'
GO
GRANT REFERENCES ON  [dbo].[mbbmTemplateValues] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmTemplateValues] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmTemplateValues] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmTemplateValues] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmTemplateValues] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmTemplateValues] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmTemplateValues] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmTemplateValues] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmTemplateValues] TO [public]
GO
