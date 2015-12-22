CREATE TABLE [dbo].[mbbmOLAPSecurityRole]
(
[TimeStamp] [timestamp] NOT NULL,
[HostCompany] [dbo].[mbbmudtCompanyCode] NOT NULL,
[Name] [dbo].[mbbmudtOLAPRoleName] NOT NULL,
[Description] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Enabled] [dbo].[mbbmudtYesNo] NOT NULL,
[UserList] [varchar] (2048) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
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
CREATE TRIGGER [dbo].[mbbmOLAPSecurityRole_Ins] ON [dbo].[mbbmOLAPSecurityRole] FOR INSERT 
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
	UPDATE	mbbmOLAPSecurityRole
	SET	mbbmOLAPSecurityRole.CreatedBy		= (SELECT hostname FROM master..sysprocesses WHERE spid = @@SPID),
		mbbmOLAPSecurityRole.CreatedTime	= GETDATE(),
		mbbmOLAPSecurityRole.UpdatedBy		= (SELECT hostname FROM master..sysprocesses WHERE spid = @@SPID),
		mbbmOLAPSecurityRole.UpdatedTime	= GETDATE()
	FROM	mbbmOLAPSecurityRole, inserted 
	WHERE	mbbmOLAPSecurityRole.HostCompany	= inserted.HostCompany 
		AND mbbmOLAPSecurityRole.Name		= inserted.Name 
		AND mbbmOLAPSecurityRole.CreatedBy	= ''
END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE TRIGGER [dbo].[mbbmOLAPSecurityRole_Upd] ON [dbo].[mbbmOLAPSecurityRole] FOR UPDATE 
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

	UPDATE  mbbmOLAPSecurityRole
	SET     mbbmOLAPSecurityRole.UpdatedBy		= (SELECT hostname FROM master..sysprocesses WHERE spid = @@SPID),
		mbbmOLAPSecurityRole.UpdatedTime	= GETDATE()
	FROM    mbbmOLAPSecurityRole, inserted 
	WHERE   mbbmOLAPSecurityRole.HostCompany 	= inserted.HostCompany
		AND mbbmOLAPSecurityRole.Name		= inserted.Name
END
GO
ALTER TABLE [dbo].[mbbmOLAPSecurityRole] ADD CONSTRAINT [PK_mbbmOLAPSecurityRole] PRIMARY KEY CLUSTERED  ([HostCompany], [Name]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmOLAPSecurityRole].[Enabled]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmOLAPSecurityRole].[Enabled]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefEmpty]', N'[dbo].[mbbmOLAPSecurityRole].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefDate]', N'[dbo].[mbbmOLAPSecurityRole].[CreatedTime]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefEmpty]', N'[dbo].[mbbmOLAPSecurityRole].[UpdatedBy]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefDate]', N'[dbo].[mbbmOLAPSecurityRole].[UpdatedTime]'
GO
GRANT REFERENCES ON  [dbo].[mbbmOLAPSecurityRole] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmOLAPSecurityRole] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmOLAPSecurityRole] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmOLAPSecurityRole] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmOLAPSecurityRole] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmOLAPSecurityRole] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmOLAPSecurityRole] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmOLAPSecurityRole] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmOLAPSecurityRole] TO [public]
GO
