CREATE TABLE [dbo].[mbbmOLAPLevelPeriods61]
(
[TimeStamp] [timestamp] NOT NULL,
[HostCompany] [dbo].[mbbmudtCompanyCode] NOT NULL,
[DimName] [dbo].[mbbmudtOLAPDimName] NOT NULL,
[YearEnd] [dbo].[mbbmudtTagDate] NOT NULL,
[LevelName] [dbo].[mbbmudtOLAPLevelName] NOT NULL,
[LevelMemberNum] [smallint] NOT NULL,
[FromPeriod] [smallint] NOT NULL,
[ThruPeriod] [smallint] NOT NULL,
[LevelKeyValue] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[LevelNameValue] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[LevelsDeep] [smallint] NOT NULL,
[MinChildNum] [smallint] NOT NULL,
[MaxChildNum] [smallint] NOT NULL,
[ParentLevelName] [dbo].[mbbmudtOLAPLevelName] NOT NULL,
[ParentLevelMemberNum] [smallint] NOT NULL,
[LevelType] [dbo].[mbbmudtOLAPLevelType] NOT NULL,
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
CREATE TRIGGER [dbo].[mbbmOLAPLevelPeriods61_Ins] ON [dbo].[mbbmOLAPLevelPeriods61] FOR INSERT 
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
	UPDATE	mbbmOLAPLevelPeriods61
	SET	mbbmOLAPLevelPeriods61.CreatedBy		= (SELECT hostname FROM master..sysprocesses WHERE spid = @@SPID),
		mbbmOLAPLevelPeriods61.CreatedTime	= GETDATE(),
		mbbmOLAPLevelPeriods61.UpdatedBy		= (SELECT hostname FROM master..sysprocesses WHERE spid = @@SPID),
		mbbmOLAPLevelPeriods61.UpdatedTime	= GETDATE()
	FROM	mbbmOLAPLevelPeriods61, inserted 
	WHERE	mbbmOLAPLevelPeriods61.HostCompany	= inserted.HostCompany
		AND mbbmOLAPLevelPeriods61.DimName	= inserted.DimName
		AND mbbmOLAPLevelPeriods61.YearEnd	= inserted.YearEnd
		AND mbbmOLAPLevelPeriods61.LevelName	= inserted.LevelName
		AND mbbmOLAPLevelPeriods61.LevelMemberNum	= inserted.LevelMemberNum
		AND mbbmOLAPLevelPeriods61.CreatedBy	= ''
END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE TRIGGER [dbo].[mbbmOLAPLevelPeriods61_Upd] ON [dbo].[mbbmOLAPLevelPeriods61] FOR UPDATE 
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

	UPDATE  mbbmOLAPLevelPeriods61
	SET     mbbmOLAPLevelPeriods61.UpdatedBy		= (SELECT hostname FROM master..sysprocesses WHERE spid = @@SPID),
		mbbmOLAPLevelPeriods61.UpdatedTime	= GETDATE()
	FROM    mbbmOLAPLevelPeriods61, inserted 
	WHERE	mbbmOLAPLevelPeriods61.HostCompany	= inserted.HostCompany
		AND mbbmOLAPLevelPeriods61.DimName	= inserted.DimName
		AND mbbmOLAPLevelPeriods61.YearEnd	= inserted.YearEnd
		AND mbbmOLAPLevelPeriods61.LevelName	= inserted.LevelName
		AND mbbmOLAPLevelPeriods61.LevelMemberNum	= inserted.LevelMemberNum
END
GO
ALTER TABLE [dbo].[mbbmOLAPLevelPeriods61] ADD CONSTRAINT [PK_mbbmOLAPLevelPeriods61] PRIMARY KEY CLUSTERED  ([HostCompany], [DimName], [YearEnd], [LevelName], [LevelMemberNum]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmOLAPLevelPeriods61] ADD CONSTRAINT [FK_mbbmOLAPLevelPeriods61] FOREIGN KEY ([HostCompany], [DimName], [LevelName]) REFERENCES [dbo].[mbbmOLAPDimLevels75] ([HostCompany], [DimName], [Name])
GO
EXEC sp_bindefault N'[dbo].[mbbmdefDate]', N'[dbo].[mbbmOLAPLevelPeriods61].[YearEnd]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulOLAPLevelType]', N'[dbo].[mbbmOLAPLevelPeriods61].[LevelType]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmOLAPLevelPeriods61].[LevelType]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefEmpty]', N'[dbo].[mbbmOLAPLevelPeriods61].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefDate]', N'[dbo].[mbbmOLAPLevelPeriods61].[CreatedTime]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefEmpty]', N'[dbo].[mbbmOLAPLevelPeriods61].[UpdatedBy]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefDate]', N'[dbo].[mbbmOLAPLevelPeriods61].[UpdatedTime]'
GO
GRANT REFERENCES ON  [dbo].[mbbmOLAPLevelPeriods61] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmOLAPLevelPeriods61] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmOLAPLevelPeriods61] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmOLAPLevelPeriods61] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmOLAPLevelPeriods61] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmOLAPLevelPeriods61] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmOLAPLevelPeriods61] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmOLAPLevelPeriods61] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmOLAPLevelPeriods61] TO [public]
GO
