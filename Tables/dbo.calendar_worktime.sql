CREATE TABLE [dbo].[calendar_worktime]
(
[timestamp] [timestamp] NOT NULL,
[calendar_worktime_id] [int] NOT NULL IDENTITY(1, 1),
[calendar_id] [int] NOT NULL,
[beg_time] [float] NOT NULL,
[end_time] [float] NOT NULL,
[eff_date] [datetime] NULL,
[exp_date] [datetime] NULL,
[weekday_mask] [int] NOT NULL CONSTRAINT [DF__calendar___weekd__41C4AAB4] DEFAULT ((127)),
[week_multiple] [int] NOT NULL CONSTRAINT [DF__calendar___week___42B8CEED] DEFAULT ((1)),
[month_multiple] [int] NOT NULL CONSTRAINT [DF__calendar___month__43ACF326] DEFAULT ((1)),
[monthweek] [int] NULL,
[monthday] [int] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE TRIGGER [dbo].[calendar_worktime_d]
ON [dbo].[calendar_worktime]

FOR DELETE
AS
BEGIN


DELETE	dbo.resource_pool
FROM	deleted D,
	dbo.resource_pool RP
WHERE	RP.calendar_worktime_id = D.calendar_worktime_id

RETURN
END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE TRIGGER [dbo].[calendar_worktime_iu]
ON [dbo].[calendar_worktime]

FOR INSERT, UPDATE
AS
BEGIN
DECLARE	@rowcount INT,
	@tstcount INT


SELECT @rowcount=@@rowcount


IF UPDATE(calendar_id)
	BEGIN
	SELECT	@tstcount = COUNT(*)
	FROM	dbo.calendar C,
		inserted I
	WHERE	C.calendar_id = I.calendar_id

	IF @tstcount <> @rowcount
		BEGIN
		ROLLBACK TRANSACTION
		exec adm_raiserror 89604 ,'Illegal column value. CALENDAR_ID not found in CALENDAR'
		RETURN
		END
	END

RETURN
END
GO
GRANT REFERENCES ON  [dbo].[calendar_worktime] TO [public]
GO
GRANT SELECT ON  [dbo].[calendar_worktime] TO [public]
GO
GRANT INSERT ON  [dbo].[calendar_worktime] TO [public]
GO
GRANT DELETE ON  [dbo].[calendar_worktime] TO [public]
GO
GRANT UPDATE ON  [dbo].[calendar_worktime] TO [public]
GO
