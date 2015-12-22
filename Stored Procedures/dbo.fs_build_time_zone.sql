SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE PROCEDURE [dbo].[fs_build_time_zone]

AS
BEGIN

CREATE TABLE #result
	(
	sched_fence_id		INT,
	fence_time		INT,
	fence_mode		CHAR(1),
	fence_date		DATETIME,
	fence_datetime		DATETIME
	)


INSERT	#result
	(
	sched_fence_id,
	fence_time,
	fence_mode,
	fence_date,
	fence_datetime
	)
SELECT	SF.sched_fence_id,
	SF.fence_time,
	SF.fence_mode,
	getdate(),
	getdate()
FROM	dbo.sched_fence SF


UPDATE	#result
SET	fence_datetime = dateadd(day,fence_time,fence_datetime)
WHERE	fence_mode = 'D'


UPDATE	#result
SET	fence_date	= CONVERT(varchar(4),datepart(year,fence_datetime))
			+ '-'
			+ CONVERT(varchar(2),datepart(month,fence_datetime))
			+ '-'
			+ CONVERT(varchar(2),datepart(day,fence_datetime))


SELECT	SF.sched_fence_id,
	SF.fence_name,
	SF.fence_time,
	SF.fence_mode,
	SF.plan_mode,
	R.fence_date,
	R.fence_datetime
FROM	dbo.sched_fence SF,
	#result R
WHERE	SF.sched_fence_id = R.sched_fence_id

RETURN
END
GO
GRANT EXECUTE ON  [dbo].[fs_build_time_zone] TO [public]
GO
