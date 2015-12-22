CREATE TABLE [dbo].[mbbmOLAPSecurityCell]
(
[TimeStamp] [timestamp] NOT NULL,
[HostCompany] [dbo].[mbbmudtCompanyCode] NOT NULL,
[RoleName] [dbo].[mbbmudtOLAPRoleName] NOT NULL,
[CubeName] [dbo].[mbbmudtOLAPCubeName] NOT NULL,
[ObjectType] [dbo].[mbbmudtOLAPObjectType] NOT NULL,
[ObjectName] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ObjectSubName] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[CellSecurity] [dbo].[mbbmudtOLAPCellSecurity] NOT NULL,
[FromThruRange] [varchar] (2048) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
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
CREATE TRIGGER [dbo].[mbbmOLAPSecurityCell_Ins] ON [dbo].[mbbmOLAPSecurityCell] FOR INSERT 
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
	UPDATE	mbbmOLAPSecurityCell
	SET	mbbmOLAPSecurityCell.CreatedBy		= (SELECT hostname FROM master..sysprocesses WHERE spid = @@SPID),
		mbbmOLAPSecurityCell.CreatedTime	= GETDATE(),
		mbbmOLAPSecurityCell.UpdatedBy		= (SELECT hostname FROM master..sysprocesses WHERE spid = @@SPID),
		mbbmOLAPSecurityCell.UpdatedTime	= GETDATE()
	FROM	mbbmOLAPSecurityCell, inserted 
	WHERE	mbbmOLAPSecurityCell.HostCompany	= inserted.HostCompany
		AND mbbmOLAPSecurityCell.RoleName	= inserted.RoleName
		AND mbbmOLAPSecurityCell.CubeName	= inserted.CubeName
		AND mbbmOLAPSecurityCell.ObjectType	= inserted.ObjectType
		AND mbbmOLAPSecurityCell.ObjectName	= inserted.ObjectName
		AND mbbmOLAPSecurityCell.ObjectSubName	= inserted.ObjectSubName
		AND mbbmOLAPSecurityCell.CreatedBy	= ''
END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE TRIGGER [dbo].[mbbmOLAPSecurityCell_Upd] ON [dbo].[mbbmOLAPSecurityCell] FOR UPDATE 
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

	UPDATE  mbbmOLAPSecurityCell
	SET     mbbmOLAPSecurityCell.UpdatedBy		= (SELECT hostname FROM master..sysprocesses WHERE spid = @@SPID),
		mbbmOLAPSecurityCell.UpdatedTime	= GETDATE()
	FROM    mbbmOLAPSecurityCell, inserted 
	WHERE	mbbmOLAPSecurityCell.HostCompany	= inserted.HostCompany
		AND mbbmOLAPSecurityCell.RoleName	= inserted.RoleName
		AND mbbmOLAPSecurityCell.CubeName	= inserted.CubeName
		AND mbbmOLAPSecurityCell.ObjectType	= inserted.ObjectType
		AND mbbmOLAPSecurityCell.ObjectName	= inserted.ObjectName
		AND mbbmOLAPSecurityCell.ObjectSubName	= inserted.ObjectSubName
END
GO
ALTER TABLE [dbo].[mbbmOLAPSecurityCell] ADD CONSTRAINT [PK_mbbmOLAPSecurityCell] PRIMARY KEY CLUSTERED  ([HostCompany], [RoleName], [CubeName], [ObjectType], [ObjectName], [ObjectSubName]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmOLAPSecurityCell] ADD CONSTRAINT [FK_mbbmOLAPSecurityCell_Name] FOREIGN KEY ([HostCompany], [RoleName], [CubeName]) REFERENCES [dbo].[mbbmOLAPSecurityCube] ([HostCompany], [RoleName], [CubeName])
GO
EXEC sp_bindrule N'[dbo].[mbbmrulOLAPObjectType]', N'[dbo].[mbbmOLAPSecurityCell].[ObjectType]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmOLAPSecurityCell].[ObjectType]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulOLAPCellSecurity]', N'[dbo].[mbbmOLAPSecurityCell].[CellSecurity]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmOLAPSecurityCell].[CellSecurity]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefEmpty]', N'[dbo].[mbbmOLAPSecurityCell].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefDate]', N'[dbo].[mbbmOLAPSecurityCell].[CreatedTime]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefEmpty]', N'[dbo].[mbbmOLAPSecurityCell].[UpdatedBy]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefDate]', N'[dbo].[mbbmOLAPSecurityCell].[UpdatedTime]'
GO
GRANT REFERENCES ON  [dbo].[mbbmOLAPSecurityCell] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmOLAPSecurityCell] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmOLAPSecurityCell] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmOLAPSecurityCell] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmOLAPSecurityCell] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmOLAPSecurityCell] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmOLAPSecurityCell] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmOLAPSecurityCell] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmOLAPSecurityCell] TO [public]
GO
