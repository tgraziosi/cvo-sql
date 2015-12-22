CREATE TABLE [dbo].[calendar_downtime]
(
[timestamp] [timestamp] NOT NULL,
[calendar_downtime_id] [int] NOT NULL IDENTITY(1, 1),
[calendar_id] [int] NOT NULL,
[downtime_id] [int] NOT NULL,
[beg_time] [float] NULL,
[end_time] [float] NULL,
[eff_date] [datetime] NULL,
[exp_date] [datetime] NULL,
[weekday_mask] [int] NOT NULL CONSTRAINT [DF__calendar___weekd__3CFFF597] DEFAULT ((127)),
[week_multiple] [int] NOT NULL CONSTRAINT [DF__calendar___week___3DF419D0] DEFAULT ((1)),
[month_multiple] [int] NOT NULL CONSTRAINT [DF__calendar___month__3EE83E09] DEFAULT ((1)),
[monthweek] [int] NULL,
[monthday] [int] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE TRIGGER [dbo].[calendar_downtime_iu]
ON [dbo].[calendar_downtime]

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
		exec adm_raiserror 89600 ,'Illegal column value. CALENDAR_ID not found in CALENDAR'
		RETURN
		END
	END


IF UPDATE(downtime_id)
	BEGIN
	SELECT	@tstcount=COUNT(*)
	FROM	inserted I,
		dbo.downtime D
	WHERE	I.downtime_id = D.downtime_id

	IF @tstcount <> @rowcount
		BEGIN
		ROLLBACK TRANSACTION
		exec adm_raiserror 89601, 'Illegal column value. DOWNTIME_ID not found in DOWNTIME'
		RETURN
		END
	END

RETURN
END
GO
GRANT REFERENCES ON  [dbo].[calendar_downtime] TO [public]
GO
GRANT SELECT ON  [dbo].[calendar_downtime] TO [public]
GO
GRANT INSERT ON  [dbo].[calendar_downtime] TO [public]
GO
GRANT DELETE ON  [dbo].[calendar_downtime] TO [public]
GO
GRANT UPDATE ON  [dbo].[calendar_downtime] TO [public]
GO
