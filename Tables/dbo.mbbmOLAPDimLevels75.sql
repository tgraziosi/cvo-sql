CREATE TABLE [dbo].[mbbmOLAPDimLevels75]
(
[TimeStamp] [timestamp] NOT NULL,
[HostCompany] [dbo].[mbbmudtCompanyCode] NOT NULL,
[DimName] [dbo].[mbbmudtOLAPDimName] NOT NULL,
[Name] [dbo].[mbbmudtOLAPLevelName] NOT NULL,
[Description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[LevelOrder] [tinyint] NOT NULL,
[KeySelect] [image] NOT NULL,
[NameSelect] [image] NOT NULL,
[MemberCount] [smallint] NOT NULL,
[UniqueMembers] [dbo].[mbbmudtYesNo] NOT NULL,
[Disabled] [dbo].[mbbmudtYesNo] NOT NULL,
[LevelType] [dbo].[mbbmudtOLAPLevelType] NOT NULL,
[KeyDataSize] [smallint] NOT NULL,
[KeyDataType] [dbo].[mbbmudtOLAPDataType] NOT NULL,
[OrderByKey] [dbo].[mbbmudtYesNo] NOT NULL,
[Custom] [dbo].[mbbmudtYesNo] NOT NULL,
[KeyCustom] [dbo].[mbbmudtYesNo] NOT NULL,
[NameCustom] [dbo].[mbbmudtYesNo] NOT NULL,
[CreatedBy] [dbo].[mbbmudtUser] NOT NULL,
[CreatedTime] [dbo].[mbbmudtTagDate] NOT NULL,
[UpdatedBy] [dbo].[mbbmudtUser] NOT NULL,
[UpdatedTime] [dbo].[mbbmudtTagDate] NOT NULL,
[KeyDSVSelectCustom] [dbo].[mbbmudtYesNo] NOT NULL,
[NameDSVSelectCustom] [dbo].[mbbmudtYesNo] NOT NULL,
[KeyDSVTableCustom] [dbo].[mbbmudtYesNo] NOT NULL,
[NameDSVTableCustom] [dbo].[mbbmudtYesNo] NOT NULL,
[KeyDSVTable] [image] NULL,
[KeyDSVSelect] [image] NULL,
[NameDSVTable] [image] NULL,
[NameDSVSelect] [image] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE TRIGGER [dbo].[mbbmOLAPDimLevels75_Ins] ON [dbo].[mbbmOLAPDimLevels75] FOR INSERT 
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
	UPDATE	mbbmOLAPDimLevels75
	SET	mbbmOLAPDimLevels75.CreatedBy		= (SELECT hostname FROM master..sysprocesses WHERE spid = @@SPID),
		mbbmOLAPDimLevels75.CreatedTime	= GETDATE(),
		mbbmOLAPDimLevels75.UpdatedBy		= (SELECT hostname FROM master..sysprocesses WHERE spid = @@SPID),
		mbbmOLAPDimLevels75.UpdatedTime	= GETDATE()
	FROM	mbbmOLAPDimLevels75, inserted 
	WHERE	mbbmOLAPDimLevels75.HostCompany	= inserted.HostCompany
		AND mbbmOLAPDimLevels75.DimName	= inserted.DimName
		AND mbbmOLAPDimLevels75.Name	= inserted.Name
		AND mbbmOLAPDimLevels75.CreatedBy	= ''
END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE TRIGGER [dbo].[mbbmOLAPDimLevels75_Upd] ON [dbo].[mbbmOLAPDimLevels75] FOR UPDATE 
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

	UPDATE  mbbmOLAPDimLevels75
	SET     mbbmOLAPDimLevels75.UpdatedBy	= (SELECT hostname FROM master..sysprocesses WHERE spid = @@SPID),
		mbbmOLAPDimLevels75.UpdatedTime	= GETDATE()
	FROM    mbbmOLAPDimLevels75, inserted 
	WHERE   mbbmOLAPDimLevels75.HostCompany	= inserted.HostCompany
		AND mbbmOLAPDimLevels75.DimName	= inserted.DimName
		AND mbbmOLAPDimLevels75.Name	= inserted.Name
END
GO
ALTER TABLE [dbo].[mbbmOLAPDimLevels75] ADD CONSTRAINT [PK_mbbmOLAPDimLevels75] PRIMARY KEY CLUSTERED  ([HostCompany], [DimName], [Name]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmOLAPDimLevels75] ADD CONSTRAINT [FK_mbbmOLAPDimLevels75_Name] FOREIGN KEY ([HostCompany], [DimName]) REFERENCES [dbo].[mbbmOLAPDimensions61] ([HostCompany], [Name])
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmOLAPDimLevels75].[UniqueMembers]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmOLAPDimLevels75].[UniqueMembers]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmOLAPDimLevels75].[Disabled]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmOLAPDimLevels75].[Disabled]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulOLAPLevelType]', N'[dbo].[mbbmOLAPDimLevels75].[LevelType]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmOLAPDimLevels75].[LevelType]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmOLAPDimLevels75].[OrderByKey]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmOLAPDimLevels75].[OrderByKey]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmOLAPDimLevels75].[Custom]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmOLAPDimLevels75].[Custom]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmOLAPDimLevels75].[KeyCustom]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmOLAPDimLevels75].[KeyCustom]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmOLAPDimLevels75].[NameCustom]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmOLAPDimLevels75].[NameCustom]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefEmpty]', N'[dbo].[mbbmOLAPDimLevels75].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefDate]', N'[dbo].[mbbmOLAPDimLevels75].[CreatedTime]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefEmpty]', N'[dbo].[mbbmOLAPDimLevels75].[UpdatedBy]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefDate]', N'[dbo].[mbbmOLAPDimLevels75].[UpdatedTime]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmOLAPDimLevels75].[KeyDSVSelectCustom]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmOLAPDimLevels75].[KeyDSVSelectCustom]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmOLAPDimLevels75].[NameDSVSelectCustom]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmOLAPDimLevels75].[NameDSVSelectCustom]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmOLAPDimLevels75].[KeyDSVTableCustom]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmOLAPDimLevels75].[KeyDSVTableCustom]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmOLAPDimLevels75].[NameDSVTableCustom]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmOLAPDimLevels75].[NameDSVTableCustom]'
GO
GRANT REFERENCES ON  [dbo].[mbbmOLAPDimLevels75] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmOLAPDimLevels75] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmOLAPDimLevels75] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmOLAPDimLevels75] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmOLAPDimLevels75] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmOLAPDimLevels75] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmOLAPDimLevels75] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmOLAPDimLevels75] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmOLAPDimLevels75] TO [public]
GO
