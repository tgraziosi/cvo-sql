CREATE TABLE [dbo].[resource_pool]
(
[timestamp] [timestamp] NOT NULL,
[resource_id] [int] NOT NULL,
[calendar_worktime_id] [int] NOT NULL,
[pool_qty] [float] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE TRIGGER [dbo].[resource_pool_iu]
ON [dbo].[resource_pool]
FOR INSERT, UPDATE
AS
BEGIN
DECLARE	@rowcount INT,
	@tstcount INT


SELECT @rowcount=@@rowcount


IF UPDATE(resource_id)
	BEGIN
	SELECT	@tstcount = COUNT(*)
	FROM	dbo.resource R,
		inserted I
	WHERE	R.resource_id = I.resource_id

	IF @tstcount <> @rowcount
		BEGIN
		ROLLBACK TRANSACTION
		exec adm_raiserror 89703, 'Illegal column value. RESOURCE_ID not found in RESOURCE'
		RETURN
		END
	END


IF UPDATE(calendar_worktime_id)
	BEGIN
	SELECT	@tstcount = COUNT(*)
	FROM	dbo.calendar_worktime CW,
		inserted I
	WHERE	CW.calendar_worktime_id = I.calendar_worktime_id

	IF @tstcount <> @rowcount
		BEGIN
		ROLLBACK TRANSACTION
		exec adm_raiserror 89704 ,'Illegal column value. CALENDAR_WORKTIME_ID not found in CALENDAR_WORKTIME'
		RETURN
		END
	END

RETURN
END
GO
CREATE UNIQUE CLUSTERED INDEX [resource] ON [dbo].[resource_pool] ([resource_id], [calendar_worktime_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[resource_pool] TO [public]
GO
GRANT SELECT ON  [dbo].[resource_pool] TO [public]
GO
GRANT INSERT ON  [dbo].[resource_pool] TO [public]
GO
GRANT DELETE ON  [dbo].[resource_pool] TO [public]
GO
GRANT UPDATE ON  [dbo].[resource_pool] TO [public]
GO
