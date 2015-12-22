CREATE TABLE [dbo].[mbbmOLAPSecurityCube]
(
[TimeStamp] [timestamp] NOT NULL,
[HostCompany] [dbo].[mbbmudtCompanyCode] NOT NULL,
[RoleName] [dbo].[mbbmudtOLAPRoleName] NOT NULL,
[CubeName] [dbo].[mbbmudtOLAPCubeName] NOT NULL,
[CubeAccess] [dbo].[mbbmudtOLAPCubeAccess] NOT NULL,
[Enforcement] [dbo].[mbbmudtOLAPEnforcement] NOT NULL,
[DrillThrough] [dbo].[mbbmudtOLAPDrillThrough] NOT NULL,
[RestrictDimensions] [dbo].[mbbmudtOLAPRestrictDimensions] NOT NULL,
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
CREATE TRIGGER [dbo].[mbbmOLAPSecurityCube_Ins] ON [dbo].[mbbmOLAPSecurityCube] FOR INSERT 
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
	UPDATE	mbbmOLAPSecurityCube
	SET	mbbmOLAPSecurityCube.CreatedBy		= (SELECT hostname FROM master..sysprocesses WHERE spid = @@SPID),
		mbbmOLAPSecurityCube.CreatedTime	= GETDATE(),
		mbbmOLAPSecurityCube.UpdatedBy		= (SELECT hostname FROM master..sysprocesses WHERE spid = @@SPID),
		mbbmOLAPSecurityCube.UpdatedTime	= GETDATE()
	FROM	mbbmOLAPSecurityCube, inserted 
	WHERE	mbbmOLAPSecurityCube.HostCompany	= inserted.HostCompany
		AND mbbmOLAPSecurityCube.RoleName	= inserted.RoleName
		AND mbbmOLAPSecurityCube.CubeName	= inserted.CubeName
		AND mbbmOLAPSecurityCube.CreatedBy	= ''
END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE TRIGGER [dbo].[mbbmOLAPSecurityCube_Upd] ON [dbo].[mbbmOLAPSecurityCube] FOR UPDATE 
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

	UPDATE  mbbmOLAPSecurityCube
	SET     mbbmOLAPSecurityCube.UpdatedBy	= (SELECT hostname FROM master..sysprocesses WHERE spid = @@SPID),
		mbbmOLAPSecurityCube.UpdatedTime	= GETDATE()
	FROM    mbbmOLAPSecurityCube, inserted 
	WHERE   mbbmOLAPSecurityCube.HostCompany	= inserted.HostCompany
		AND mbbmOLAPSecurityCube.RoleName	= inserted.RoleName
		AND mbbmOLAPSecurityCube.CubeName	= inserted.CubeName
END
GO
ALTER TABLE [dbo].[mbbmOLAPSecurityCube] ADD CONSTRAINT [PK_mbbmOLAPSecurityCube] PRIMARY KEY CLUSTERED  ([HostCompany], [RoleName], [CubeName]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmOLAPSecurityCube] ADD CONSTRAINT [FK_mbbmOLAPSecurityCube_Cube] FOREIGN KEY ([HostCompany], [CubeName]) REFERENCES [dbo].[mbbmCubes75] ([HostCompany], [Name])
GO
ALTER TABLE [dbo].[mbbmOLAPSecurityCube] ADD CONSTRAINT [FK_mbbmOLAPSecurityCube_Name] FOREIGN KEY ([HostCompany], [RoleName]) REFERENCES [dbo].[mbbmOLAPSecurityRole] ([HostCompany], [Name])
GO
EXEC sp_bindrule N'[dbo].[mbbmrulOLAPCubeAccess]', N'[dbo].[mbbmOLAPSecurityCube].[CubeAccess]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmOLAPSecurityCube].[CubeAccess]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulOLAPEnforcement]', N'[dbo].[mbbmOLAPSecurityCube].[Enforcement]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmOLAPSecurityCube].[Enforcement]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmOLAPSecurityCube].[DrillThrough]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmOLAPSecurityCube].[DrillThrough]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmOLAPSecurityCube].[RestrictDimensions]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmOLAPSecurityCube].[RestrictDimensions]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefEmpty]', N'[dbo].[mbbmOLAPSecurityCube].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefDate]', N'[dbo].[mbbmOLAPSecurityCube].[CreatedTime]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefEmpty]', N'[dbo].[mbbmOLAPSecurityCube].[UpdatedBy]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefDate]', N'[dbo].[mbbmOLAPSecurityCube].[UpdatedTime]'
GO
GRANT REFERENCES ON  [dbo].[mbbmOLAPSecurityCube] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmOLAPSecurityCube] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmOLAPSecurityCube] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmOLAPSecurityCube] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmOLAPSecurityCube] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmOLAPSecurityCube] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmOLAPSecurityCube] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmOLAPSecurityCube] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmOLAPSecurityCube] TO [public]
GO
