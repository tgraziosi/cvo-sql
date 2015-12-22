CREATE TABLE [dbo].[mbbmPlanHist]
(
[TimeStamp] [timestamp] NOT NULL,
[PlanID] [int] NOT NULL CONSTRAINT [DF__mbbmPlanH__PlanI__431FE7AF] DEFAULT ((0)),
[SheetID] [int] NOT NULL CONSTRAINT [DF__mbbmPlanH__Sheet__44140BE8] DEFAULT ((0)),
[RevisionID] [int] NOT NULL CONSTRAINT [DF__mbbmPlanH__Revis__45083021] DEFAULT ((0)),
[ChangeTime] [datetime] NOT NULL CONSTRAINT [DF__mbbmPlanH__Chang__45FC545A] DEFAULT (getdate()),
[EventCode] [int] NOT NULL,
[UserID] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__mbbmPlanH__UserI__46F07893] DEFAULT (''),
[OldValue] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__mbbmPlanH__OldVa__47E49CCC] DEFAULT (''),
[NewValue] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__mbbmPlanH__NewVa__48D8C105] DEFAULT (''),
[Description] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__mbbmPlanH__Descr__49CCE53E] DEFAULT ('')
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE TRIGGER [dbo].[mbbmPlanHist_Ins] ON [dbo].[mbbmPlanHist] FOR INSERT
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
	DECLARE	@Ok		tinyint,
		@DateStamp	datetime

	SELECT	@Ok = 0

	WHILE @Ok = 0 BEGIN
		SELECT	@DateStamp = getdate()
		IF NOT EXISTS(SELECT * FROM mbbmPlanHist h, inserted i WHERE h.PlanID = i.PlanID AND h.SheetID = i.SheetID AND h.RevisionID = i.RevisionID AND h.ChangeTime = @DateStamp)
			SELECT @Ok = 1
	END

	UPDATE  mbbmPlanHist
	SET     mbbmPlanHist.ChangeTime = @DateStamp,
		mbbmPlanHist.UserID	= (SELECT hostname FROM master..sysprocesses WHERE spid = @@SPID)
	FROM    mbbmPlanHist, inserted 
	WHERE   mbbmPlanHist.PlanID = inserted.PlanID
		AND mbbmPlanHist.SheetID = inserted.SheetID
		AND mbbmPlanHist.RevisionID = inserted.RevisionID
		AND mbbmPlanHist.ChangeTime = inserted.ChangeTime

END
GO
ALTER TABLE [dbo].[mbbmPlanHist] ADD CONSTRAINT [PK_mbbmPlanHist] PRIMARY KEY CLUSTERED  ([PlanID], [SheetID], [RevisionID], [ChangeTime], [EventCode]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[mbbmPlanHist] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmPlanHist] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmPlanHist] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmPlanHist] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmPlanHist] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmPlanHist] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmPlanHist] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmPlanHist] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmPlanHist] TO [public]
GO
