CREATE TABLE [dbo].[mbbmSheetStatusCode6]
(
[TimeStamp] [timestamp] NOT NULL,
[HostCompany] [dbo].[mbbmudtCompanyCode] NOT NULL,
[Code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__mbbmSheet__Descr__109467E2] DEFAULT (''),
[SetDistList] [tinyint] NOT NULL,
[SetUserID] [dbo].[mbbmudtUser] NOT NULL,
[SetMessage] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SaveDistList] [tinyint] NOT NULL,
[SaveUserID] [dbo].[mbbmudtUser] NOT NULL,
[SaveMessage] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[CreatedBy] [dbo].[mbbmudtUser] NOT NULL,
[CreatedTime] [dbo].[mbbmudtTagDate] NOT NULL,
[UpdatedBy] [dbo].[mbbmudtUser] NOT NULL,
[UpdatedTime] [dbo].[mbbmudtTagDate] NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE TRIGGER [dbo].[mbbmSheetStatusCode6_Ins] ON [dbo].[mbbmSheetStatusCode6] FOR INSERT 
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
	UPDATE  mbbmSheetStatusCode6
	SET     mbbmSheetStatusCode6.CreatedBy		= (SELECT hostname FROM master..sysprocesses WHERE spid = @@SPID),
		mbbmSheetStatusCode6.CreatedTime	= GETDATE(),
		mbbmSheetStatusCode6.UpdatedBy		= (SELECT hostname FROM master..sysprocesses WHERE spid = @@SPID),
		mbbmSheetStatusCode6.UpdatedTime	= GETDATE()
	FROM    mbbmSheetStatusCode6, inserted 
	WHERE   mbbmSheetStatusCode6.HostCompany	= inserted.HostCompany
		AND mbbmSheetStatusCode6.Code		= inserted.Code
END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE TRIGGER [dbo].[mbbmSheetStatusCode6_Upd] ON [dbo].[mbbmSheetStatusCode6] FOR UPDATE 
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

	UPDATE  mbbmSheetStatusCode6
	SET     mbbmSheetStatusCode6.UpdatedBy		= (SELECT hostname FROM master..sysprocesses WHERE spid = @@SPID),
		mbbmSheetStatusCode6.UpdatedTime	= GETDATE()
	FROM    mbbmSheetStatusCode6, inserted 
	WHERE   mbbmSheetStatusCode6.HostCompany	= inserted.HostCompany
		AND mbbmSheetStatusCode6.Code		= inserted.Code
END
GO
ALTER TABLE [dbo].[mbbmSheetStatusCode6] ADD CONSTRAINT [PK_mbbmSheetStatusCode6] PRIMARY KEY CLUSTERED  ([HostCompany], [Code]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[mbbmdefEmpty]', N'[dbo].[mbbmSheetStatusCode6].[SetUserID]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefEmpty]', N'[dbo].[mbbmSheetStatusCode6].[SaveUserID]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefEmpty]', N'[dbo].[mbbmSheetStatusCode6].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefDate]', N'[dbo].[mbbmSheetStatusCode6].[CreatedTime]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefEmpty]', N'[dbo].[mbbmSheetStatusCode6].[UpdatedBy]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefDate]', N'[dbo].[mbbmSheetStatusCode6].[UpdatedTime]'
GO
GRANT REFERENCES ON  [dbo].[mbbmSheetStatusCode6] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmSheetStatusCode6] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmSheetStatusCode6] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmSheetStatusCode6] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmSheetStatusCode6] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmSheetStatusCode6] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmSheetStatusCode6] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmSheetStatusCode6] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmSheetStatusCode6] TO [public]
GO
