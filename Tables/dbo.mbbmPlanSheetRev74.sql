CREATE TABLE [dbo].[mbbmPlanSheetRev74]
(
[TimeStamp] [timestamp] NOT NULL,
[RevisionID] [int] NOT NULL CONSTRAINT [DF__mbbmPlanS__Revis__296015AC] DEFAULT ((0)),
[SheetID] [int] NOT NULL,
[RevisionKey] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[CurrentDate] [dbo].[mbbmudtAppDate] NOT NULL,
[PrintSettings] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Spreadsheet] [image] NOT NULL,
[CreatedBy] [dbo].[mbbmudtUser] NOT NULL,
[CreatedTime] [dbo].[mbbmudtTagDate] NOT NULL,
[UpdatedBy] [dbo].[mbbmudtUser] NOT NULL,
[UpdatedTime] [dbo].[mbbmudtTagDate] NOT NULL,
[RowIDGen] [dbo].[mbbmudtYesNo] NOT NULL,
[ParIDGen] [dbo].[mbbmudtYesNo] NOT NULL,
[RowIDFunc] [varchar] (512) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ParIDFunc] [varchar] (512) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[BaseDateType] [dbo].[mbbmudtBaseDateType] NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE TRIGGER [dbo].[mbbmPlanSheetRev74_Ins] ON [dbo].[mbbmPlanSheetRev74] FOR INSERT 
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
	DECLARE @NewRevisionID int

	SELECT  @NewRevisionID = ISNULL(MAX(RevisionID), 0) + 1
	FROM	mbbmPlanSheetRev74

	UPDATE  mbbmPlanSheetRev74
	SET     mbbmPlanSheetRev74.RevisionID	= @NewRevisionID,
		mbbmPlanSheetRev74.CreatedBy	= (SELECT hostname FROM master..sysprocesses WHERE spid = @@SPID),
		mbbmPlanSheetRev74.CreatedTime	= GETDATE(),
		mbbmPlanSheetRev74.UpdatedBy	= (SELECT hostname FROM master..sysprocesses WHERE spid = @@SPID),
		mbbmPlanSheetRev74.UpdatedTime	= GETDATE()
	FROM    mbbmPlanSheetRev74, inserted 
	WHERE   mbbmPlanSheetRev74.RevisionID	= inserted.RevisionID

END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE TRIGGER [dbo].[mbbmPlanSheetRev74_Upd] ON [dbo].[mbbmPlanSheetRev74] FOR UPDATE 
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

	UPDATE  mbbmPlanSheetRev74
	SET     mbbmPlanSheetRev74.UpdatedBy	= (SELECT hostname FROM master..sysprocesses WHERE spid = @@SPID),
		mbbmPlanSheetRev74.UpdatedTime	= GETDATE()
	FROM    mbbmPlanSheetRev74, inserted 
	WHERE   mbbmPlanSheetRev74.RevisionID	= inserted.RevisionID

END
GO
ALTER TABLE [dbo].[mbbmPlanSheetRev74] ADD CONSTRAINT [PK_mbbmPlanRev74] PRIMARY KEY CLUSTERED  ([RevisionID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmPlanSheetRev74] ADD CONSTRAINT [PK_mbbmPlanSheetRev74] UNIQUE NONCLUSTERED  ([SheetID], [RevisionKey]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmPlanSheetRev74] ADD CONSTRAINT [FK_mbbmPlanRev74_SheetID] FOREIGN KEY ([SheetID]) REFERENCES [dbo].[mbbmPlanSheet74] ([SheetID])
GO
EXEC sp_bindefault N'[dbo].[mbbmdefEmpty]', N'[dbo].[mbbmPlanSheetRev74].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefDate]', N'[dbo].[mbbmPlanSheetRev74].[CreatedTime]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefEmpty]', N'[dbo].[mbbmPlanSheetRev74].[UpdatedBy]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefDate]', N'[dbo].[mbbmPlanSheetRev74].[UpdatedTime]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmPlanSheetRev74].[RowIDGen]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmPlanSheetRev74].[RowIDGen]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmPlanSheetRev74].[ParIDGen]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmPlanSheetRev74].[ParIDGen]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulBaseDateType]', N'[dbo].[mbbmPlanSheetRev74].[BaseDateType]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmPlanSheetRev74].[BaseDateType]'
GO
GRANT REFERENCES ON  [dbo].[mbbmPlanSheetRev74] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmPlanSheetRev74] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmPlanSheetRev74] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmPlanSheetRev74] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmPlanSheetRev74] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmPlanSheetRev74] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmPlanSheetRev74] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmPlanSheetRev74] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmPlanSheetRev74] TO [public]
GO
