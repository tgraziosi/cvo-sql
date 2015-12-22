SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 1998 Epicor Software, Inc. All Right Reserved.
CREATE PROCEDURE [dbo].[fs_calculate_batch]
	(
	@debug_file	VARCHAR(255) = NULL
	)

AS
BEGIN
DECLARE	@sched_id INT


SELECT	@sched_id=MIN(SM.sched_id)
FROM	dbo.sched_model SM
WHERE	SM.batch_flag = 'B'

WHILE @sched_id IS NOT NULL
	BEGIN
	
	EXECUTE fs_calculate_schedule @sched_id=@sched_id,@debug_file=@debug_file

	
	SELECT	@sched_id=MIN(SM.sched_id)
	FROM	dbo.sched_model SM
	WHERE	SM.batch_flag = 'B'
	AND	SM.sched_id > @sched_id
	END

RETURN
END
GO
GRANT EXECUTE ON  [dbo].[fs_calculate_batch] TO [public]
GO
