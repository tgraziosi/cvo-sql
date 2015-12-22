CREATE TABLE [dbo].[sched_fence_user]
(
[timestamp] [timestamp] NOT NULL,
[sched_fence_id] [int] NOT NULL,
[kys] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE TRIGGER [dbo].[sched_fence_user_iu]
ON [dbo].[sched_fence_user]

FOR INSERT, UPDATE
AS
BEGIN
DECLARE	@rowcount INT,
	@tstcount INT


SELECT @rowcount=@@rowcount


IF UPDATE(sched_fence_id)
	BEGIN
	SELECT	@tstcount = COUNT(*)
	FROM	dbo.sched_fence SF,
		inserted I
	WHERE	SF.sched_fence_id = I.sched_fence_id

	IF @tstcount <> @rowcount
		BEGIN
		ROLLBACK TRANSACTION
		exec adm_raiserror 89009 ,'Illegal column value. SCHED_FENCE_ID not found in SCHED_FENCE'
		RETURN
		END
	END


IF UPDATE(kys)
	BEGIN
	SELECT	@tstcount = COUNT(*)
	FROM	dbo.sec_user SU,
		inserted I
	WHERE	SU.kys = I.kys

	IF @tstcount <> @rowcount
		BEGIN
		ROLLBACK TRANSACTION
		exec adm_raiserror 89008, 'Illegal column value. KYS not found in SEC_USER'
		RETURN
		END
	END

RETURN
END
GO
CREATE UNIQUE CLUSTERED INDEX [sched_fence_user] ON [dbo].[sched_fence_user] ([sched_fence_id], [kys]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[sched_fence_user] TO [public]
GO
GRANT SELECT ON  [dbo].[sched_fence_user] TO [public]
GO
GRANT INSERT ON  [dbo].[sched_fence_user] TO [public]
GO
GRANT DELETE ON  [dbo].[sched_fence_user] TO [public]
GO
GRANT UPDATE ON  [dbo].[sched_fence_user] TO [public]
GO
