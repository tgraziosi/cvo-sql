CREATE TABLE [dbo].[mbbmFormula74]
(
[TimeStamp] [timestamp] NOT NULL,
[HostCompany] [dbo].[mbbmudtCompanyCode] NOT NULL,
[FormulaType] [dbo].[mbbmudtFormulaType] NOT NULL,
[FormulaOwnerType] [tinyint] NOT NULL,
[FormulaOwnerID] [int] NOT NULL,
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
CREATE TRIGGER [dbo].[mbbmFormula74_Ins] ON [dbo].[mbbmFormula74] FOR INSERT 
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
	UPDATE	mbbmFormula74
	SET	mbbmFormula74.CreatedBy			= (SELECT hostname FROM master..sysprocesses WHERE spid = @@SPID),
		mbbmFormula74.CreatedTime			= GETDATE(),
		mbbmFormula74.UpdatedBy			= (SELECT hostname FROM master..sysprocesses WHERE spid = @@SPID),
		mbbmFormula74.UpdatedTime			= GETDATE()
	FROM	mbbmFormula74, inserted 
	WHERE	mbbmFormula74.FormulaType		= inserted.FormulaType 
		AND mbbmFormula74.FormulaOwnerType	= inserted.FormulaOwnerType 
		AND mbbmFormula74.FormulaOwnerID		= inserted.FormulaOwnerID
		AND mbbmFormula74.FormulaKey		= inserted.FormulaKey
		AND mbbmFormula74.CreatedBy		= ''
END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE TRIGGER [dbo].[mbbmFormula74_Upd] ON [dbo].[mbbmFormula74] FOR UPDATE 
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

	UPDATE  mbbmFormula74
	SET     mbbmFormula74.UpdatedBy			= (SELECT hostname FROM master..sysprocesses WHERE spid = @@SPID),
		mbbmFormula74.UpdatedTime			= GETDATE()
	FROM    mbbmFormula74, inserted 
	WHERE   mbbmFormula74.FormulaType		= inserted.FormulaType
		AND mbbmFormula74.FormulaOwnerType	= inserted.FormulaOwnerType
		AND mbbmFormula74.FormulaOwnerID		= inserted.FormulaOwnerID
		AND mbbmFormula74.FormulaKey		= inserted.FormulaKey
END
GO
ALTER TABLE [dbo].[mbbmFormula74] ADD CONSTRAINT [PK_mbbmFormula74] PRIMARY KEY CLUSTERED  ([HostCompany], [FormulaType], [FormulaOwnerType], [FormulaOwnerID], [FormulaKey]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IDX_mbbmFormula74] ON [dbo].[mbbmFormula74] ([FormulaType], [FormulaOwnerType], [FormulaOwnerID], [FormulaKey], [CreatedBy]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[mbbmrulFormulaType]', N'[dbo].[mbbmFormula74].[FormulaType]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmFormula74].[FormulaType]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmFormula74].[InclPrevAlloc]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmFormula74].[InclPrevAlloc]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefEmpty]', N'[dbo].[mbbmFormula74].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefDate]', N'[dbo].[mbbmFormula74].[CreatedTime]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefEmpty]', N'[dbo].[mbbmFormula74].[UpdatedBy]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefDate]', N'[dbo].[mbbmFormula74].[UpdatedTime]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmFormula74].[FormulaFromTemplate]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmFormula74].[FormulaFromTemplate]'
GO
GRANT REFERENCES ON  [dbo].[mbbmFormula74] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmFormula74] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmFormula74] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmFormula74] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmFormula74] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmFormula74] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmFormula74] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmFormula74] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmFormula74] TO [public]
GO
