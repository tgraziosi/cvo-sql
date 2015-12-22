CREATE TABLE [dbo].[mbbmTmpFormula]
(
[TimeStamp] [timestamp] NOT NULL,
[Spid] [int] NOT NULL,
[FormulaKey] [dbo].[mbbmudtFormulaKey] NOT NULL,
[Description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[InclPrevAlloc] [dbo].[mbbmudtYesNo] NOT NULL,
[CreatedBy] [dbo].[mbbmudtUser] NOT NULL,
[CreatedTime] [dbo].[mbbmudtTagDate] NOT NULL,
[UpdatedBy] [dbo].[mbbmudtUser] NOT NULL,
[UpdatedTime] [dbo].[mbbmudtTagDate] NOT NULL,
[FormulaFromTemplate] [dbo].[mbbmudtYesNo] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE TRIGGER [dbo].[mbbmTmpFormula_Ins] ON [dbo].[mbbmTmpFormula] FOR INSERT 
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
	UPDATE  mbbmTmpFormula
	SET     mbbmTmpFormula.CreatedBy          = (SELECT hostname FROM master..sysprocesses WHERE spid = @@SPID),
		mbbmTmpFormula.CreatedTime        = GETDATE(),
		mbbmTmpFormula.UpdatedBy          = (SELECT hostname FROM master..sysprocesses WHERE spid = @@SPID),
		mbbmTmpFormula.UpdatedTime        = GETDATE()
	FROM    mbbmTmpFormula, inserted 
	WHERE   mbbmTmpFormula.FormulaKey         = inserted.FormulaKey
		AND mbbmTmpFormula.Spid           = inserted.Spid
		AND mbbmTmpFormula.CreatedBy      = ''
END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE TRIGGER [dbo].[mbbmTmpFormula_Upd] ON [dbo].[mbbmTmpFormula] FOR UPDATE 
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

	UPDATE  mbbmTmpFormula
	SET     mbbmTmpFormula.UpdatedBy          = (SELECT hostname FROM master..sysprocesses WHERE spid = @@SPID),
		mbbmTmpFormula.UpdatedTime        = GETDATE()
	FROM    mbbmTmpFormula, inserted 
	WHERE   mbbmTmpFormula.FormulaKey         = inserted.FormulaKey
		AND mbbmTmpFormula.Spid           = inserted.Spid
END
GO
ALTER TABLE [dbo].[mbbmTmpFormula] ADD CONSTRAINT [PK_mbbmTmpFormula] PRIMARY KEY CLUSTERED  ([Spid], [FormulaKey]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IDX_mbbmTmpFormula] ON [dbo].[mbbmTmpFormula] ([FormulaKey], [Spid], [CreatedBy]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmTmpFormula].[InclPrevAlloc]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmTmpFormula].[InclPrevAlloc]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefEmpty]', N'[dbo].[mbbmTmpFormula].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefDate]', N'[dbo].[mbbmTmpFormula].[CreatedTime]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefEmpty]', N'[dbo].[mbbmTmpFormula].[UpdatedBy]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefDate]', N'[dbo].[mbbmTmpFormula].[UpdatedTime]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmTmpFormula].[FormulaFromTemplate]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmTmpFormula].[FormulaFromTemplate]'
GO
GRANT REFERENCES ON  [dbo].[mbbmTmpFormula] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmTmpFormula] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmTmpFormula] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmTmpFormula] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmTmpFormula] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmTmpFormula] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmTmpFormula] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmTmpFormula] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmTmpFormula] TO [public]
GO
