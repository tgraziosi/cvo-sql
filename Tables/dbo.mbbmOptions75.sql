CREATE TABLE [dbo].[mbbmOptions75]
(
[TimeStamp] [timestamp] NOT NULL,
[HostCompany] [dbo].[mbbmudtCompanyCode] NOT NULL,
[JournalCode] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[BatchNoOption] [tinyint] NOT NULL,
[BatchControlMask] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[BatchControlNo] [int] NOT NULL,
[JournalNoOption] [tinyint] NOT NULL,
[JournalControlMask] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[JournalControlNo] [int] NOT NULL,
[AvgDailyBalExclSat] [dbo].[mbbmudtYesNo] NOT NULL,
[AvgDailyBalExclSun] [dbo].[mbbmudtYesNo] NOT NULL,
[UpdatedBy] [dbo].[mbbmudtUser] NOT NULL,
[UpdatedTime] [dbo].[mbbmudtTagDate] NOT NULL,
[ExclInactiveAccts] [dbo].[mbbmudtYesNo] NOT NULL,
[AccountSizeUnmasked] [int] NOT NULL,
[NextProcessID] [int] NOT NULL,
[UploadMultiUser] [dbo].[mbbmudtYesNo] NOT NULL,
[OverwriteEntire] [dbo].[mbbmudtYesNo] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE TRIGGER [dbo].[mbbmOptions75_Upd] ON [dbo].[mbbmOptions75] FOR UPDATE 
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

	UPDATE  mbbmOptions75
	SET     UpdatedBy       = (SELECT hostname FROM master..sysprocesses WHERE spid = @@SPID),
		UpdatedTime     = GETDATE()
	FROM	mbbmOptions75, inserted
	WHERE	mbbmOptions75.HostCompany	= inserted.HostCompany
END
GO
ALTER TABLE [dbo].[mbbmOptions75] ADD CONSTRAINT [CK_mbbmOptions75_BatchNoOption] CHECK (([BatchNoOption]=(1) OR [BatchNoOption]=(0)))
GO
ALTER TABLE [dbo].[mbbmOptions75] ADD CONSTRAINT [CK_mbbmOptions75_JrnlNoOption] CHECK (([JournalNoOption]=(2) OR [JournalNoOption]=(1) OR [JournalNoOption]=(0)))
GO
ALTER TABLE [dbo].[mbbmOptions75] ADD CONSTRAINT [PK_mbbmOptions75] PRIMARY KEY CLUSTERED  ([HostCompany]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmOptions75].[AvgDailyBalExclSat]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmOptions75].[AvgDailyBalExclSat]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmOptions75].[AvgDailyBalExclSun]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmOptions75].[AvgDailyBalExclSun]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefEmpty]', N'[dbo].[mbbmOptions75].[UpdatedBy]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefDate]', N'[dbo].[mbbmOptions75].[UpdatedTime]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmOptions75].[ExclInactiveAccts]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmOptions75].[ExclInactiveAccts]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmOptions75].[UploadMultiUser]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmOptions75].[UploadMultiUser]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmOptions75].[OverwriteEntire]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmOptions75].[OverwriteEntire]'
GO
GRANT REFERENCES ON  [dbo].[mbbmOptions75] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmOptions75] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmOptions75] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmOptions75] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmOptions75] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmOptions75] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmOptions75] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmOptions75] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmOptions75] TO [public]
GO
