CREATE TABLE [dbo].[calendar]
(
[timestamp] [timestamp] NOT NULL,
[calendar_id] [int] NOT NULL IDENTITY(1, 1),
[calendar_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[calendar_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[usage_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__calendar__usage___3A2388EC] DEFAULT ('A')
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE TRIGGER [dbo].[calendar_d]
ON [dbo].[calendar]

FOR DELETE
AS
BEGIN

IF EXISTS(SELECT * FROM deleted D, dbo.resource R WHERE R.calendar_id = D.calendar_id)
	BEGIN
	ROLLBACK TRANSACTION
	exec adm_raiserror 79630,'The calendar to be deleted is in use by one or more resources'
	RETURN
	END


IF EXISTS(SELECT * FROM deleted D, dbo.sched_resource SR WHERE SR.calendar_id = D.calendar_id)
	BEGIN
	ROLLBACK TRANSACTION
	exec adm_raiserror 79631, 'The calendar to be deleted is in use by one or more schedule resources'
	RETURN
	END


DELETE	dbo.calendar_worktime
FROM	deleted D,
	dbo.calendar_worktime CW
WHERE	CW.calendar_id = D.calendar_id


DELETE	dbo.calendar_downtime
FROM	deleted D,
	dbo.calendar_downtime CD
WHERE	CD.calendar_id = D.calendar_id

RETURN
END
GO
ALTER TABLE [dbo].[calendar] ADD CONSTRAINT [calendar_usage_flag_cc1] CHECK (([usage_flag]='A' OR [usage_flag]='D'))
GO
CREATE UNIQUE CLUSTERED INDEX [calendar] ON [dbo].[calendar] ([calendar_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[calendar] TO [public]
GO
GRANT SELECT ON  [dbo].[calendar] TO [public]
GO
GRANT INSERT ON  [dbo].[calendar] TO [public]
GO
GRANT DELETE ON  [dbo].[calendar] TO [public]
GO
GRANT UPDATE ON  [dbo].[calendar] TO [public]
GO
