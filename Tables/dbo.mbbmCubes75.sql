CREATE TABLE [dbo].[mbbmCubes75]
(
[TimeStamp] [timestamp] NOT NULL,
[HostCompany] [dbo].[mbbmudtCompanyCode] NOT NULL,
[Name] [dbo].[mbbmudtOLAPCubeName] NOT NULL,
[PlanID] [int] NOT NULL,
[DimensionSet] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ValuationMethod] [dbo].[mbbmudtValMethod] NOT NULL,
[OLAPServer] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[OLAPDatabase] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[CubeStorage] [tinyint] NOT NULL,
[DesignMethod] [tinyint] NOT NULL,
[Reach] [int] NOT NULL,
[Magnitude] [tinyint] NOT NULL,
[SegmentBreakouts] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Measures] [varchar] (2200) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[OLAPDimensions] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ProcessNeeded] [dbo].[mbbmudtYesNo] NOT NULL,
[LastProcessed] [smalldatetime] NULL,
[CreatedBy] [dbo].[mbbmudtUser] NOT NULL,
[CreatedTime] [dbo].[mbbmudtTagDate] NOT NULL,
[UpdatedBy] [dbo].[mbbmudtUser] NOT NULL,
[UpdatedTime] [dbo].[mbbmudtTagDate] NOT NULL,
[WBTableRounding] [dbo].[mbbmudtYesNo] NOT NULL,
[WBTableRoundDec] [tinyint] NOT NULL,
[AutoPublish] [dbo].[mbbmudtYesNo] NOT NULL,
[OLAPServerVersion] [float] NOT NULL,
[CubeManager] [dbo].[mbbmudtUser] NOT NULL,
[DimensionSetViewable] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE TRIGGER [dbo].[mbbmCubes75_Ins] ON [dbo].[mbbmCubes75] FOR INSERT 
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
	UPDATE	mbbmCubes75
	SET	mbbmCubes75.CreatedBy		= (SELECT hostname FROM master..sysprocesses WHERE spid = @@SPID),
		mbbmCubes75.CreatedTime		= GETDATE(),
		mbbmCubes75.UpdatedBy		= (SELECT hostname FROM master..sysprocesses WHERE spid = @@SPID),
		mbbmCubes75.UpdatedTime		= GETDATE()
	FROM	mbbmCubes75, inserted 
	WHERE	mbbmCubes75.Name			= inserted.Name 
		AND mbbmCubes75.CreatedBy		= ''
END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE TRIGGER [dbo].[mbbmCubes75_Upd] ON [dbo].[mbbmCubes75] FOR UPDATE 
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

	UPDATE  mbbmCubes75
	SET     mbbmCubes75.UpdatedBy		= (SELECT hostname FROM master..sysprocesses WHERE spid = @@SPID),
		mbbmCubes75.UpdatedTime		= GETDATE()
	FROM    mbbmCubes75, inserted 
	WHERE   mbbmCubes75.Name			= inserted.Name
END
GO
ALTER TABLE [dbo].[mbbmCubes75] ADD CONSTRAINT [PK_mbbmCubes75] UNIQUE NONCLUSTERED  ([HostCompany], [Name]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IDX_mbbmCubes75] ON [dbo].[mbbmCubes75] ([HostCompany]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmCubes75] ADD CONSTRAINT [FK_mbbmCubes75_PlanID] FOREIGN KEY ([PlanID]) REFERENCES [dbo].[mbbmPlan74] ([PlanID])
GO
EXEC sp_bindrule N'[dbo].[mbbmrulValMethod]', N'[dbo].[mbbmCubes75].[ValuationMethod]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef3]', N'[dbo].[mbbmCubes75].[ValuationMethod]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmCubes75].[ProcessNeeded]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmCubes75].[ProcessNeeded]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefEmpty]', N'[dbo].[mbbmCubes75].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefDate]', N'[dbo].[mbbmCubes75].[CreatedTime]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefEmpty]', N'[dbo].[mbbmCubes75].[UpdatedBy]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefDate]', N'[dbo].[mbbmCubes75].[UpdatedTime]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmCubes75].[WBTableRounding]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmCubes75].[WBTableRounding]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmCubes75].[AutoPublish]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmCubes75].[AutoPublish]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefEmpty]', N'[dbo].[mbbmCubes75].[CubeManager]'
GO
GRANT REFERENCES ON  [dbo].[mbbmCubes75] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmCubes75] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmCubes75] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmCubes75] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmCubes75] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmCubes75] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmCubes75] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmCubes75] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmCubes75] TO [public]
GO
