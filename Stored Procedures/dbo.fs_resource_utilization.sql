SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE PROCEDURE [dbo].[fs_resource_utilization]
	(
	@sched_resource_id	INT = NULL,
	@sched_id		INT = NULL,
	@resource_id		INT = NULL,
	@location		VARCHAR(10) = NULL,
	@beg_date		DATETIME = NULL,
	@end_date		DATETIME = NULL
	)
WITH ENCRYPTION
AS
BEGIN

DECLARE	@calendar_id	INT,
	@beg_datetime	DATETIME,
	@end_datetime	DATETIME,
	@run_time	FLOAT,
	@set_time	FLOAT,
	@result_id	INT








IF @beg_date IS NULL
	SELECT @beg_date = dateadd(day,-1,getdate())
IF @end_date IS NULL
	SELECT @end_date = dateadd(day,14,@beg_date)


CREATE TABLE #location
	(
	location	VARCHAR(10)
	)

IF @location IS NOT NULL
	
	INSERT	#location(location)
	SELECT	L.location
	FROM	dbo.locations_all L
	WHERE	L.location = @location
ELSE IF @sched_id IS NOT NULL
	
	INSERT	#location(location)
	SELECT	L.location
	FROM	dbo.sched_location SL,
		dbo.locations_all L		
	WHERE	SL.sched_id = @sched_id
	AND	L.location = SL.location
ELSE
	
	INSERT	#location(location)
	SELECT	L.location
	FROM	dbo.locations_all L


CREATE TABLE #resource
	(
	sched_resource_id	INT,
	resource_id		INT	NULL,	
	resource_code		VARCHAR(30),
	resource_name		VARCHAR(255),
	calendar_id		INT,
	pool_qty		FLOAT
	)


IF @sched_resource_id IS NOT NULL
	BEGIN
	
	SELECT	@sched_id=SR.sched_id
	FROM	dbo.sched_resource SR
	WHERE	SR.sched_resource_id = @sched_resource_id

	
	INSERT	#resource(sched_resource_id,resource_id,resource_code,resource_name,calendar_id,pool_qty)
	SELECT	SR.sched_resource_id,
		SR.resource_id,
		IsNull(R.resource_code,RT.resource_type_code),
		IsNull(R.resource_name,RT.resource_type_name),
		IsNull(SR.calendar_id,R.calendar_id),
		R.pool_qty
	FROM	dbo.sched_resource SR
	left outer join dbo.resource R (nolock) on SR.resource_id = R.resource_id
	join dbo.resource_type RT (nolock) on SR.resource_type_id = RT.resource_type_id
	WHERE	SR.sched_resource_id = @sched_resource_id
	END
ELSE IF @sched_id IS NOT NULL AND @resource_id IS NOT NULL
	
	INSERT	#resource(sched_resource_id,resource_id,resource_code,resource_name,calendar_id,pool_qty)
	SELECT	SR.sched_resource_id,
		SR.resource_id,
		IsNull(R.resource_code,RT.resource_type_code),
		IsNull(R.resource_name,RT.resource_type_name),
		IsNull(SR.calendar_id,R.calendar_id),
		R.pool_qty
	FROM	dbo.sched_resource SR,
		dbo.resource R,
		dbo.resource_type RT
	WHERE	SR.sched_id = @sched_id
	AND	SR.resource_id = @resource_id
	AND	R.resource_id = @resource_id
	AND	RT.resource_type_id = SR.resource_type_id
	AND	RT.resource_type_id = R.resource_type_id
ELSE IF @sched_id IS NOT NULL
	
	INSERT	#resource(sched_resource_id,resource_id,resource_code,resource_name,calendar_id,pool_qty)
	SELECT	SR.sched_resource_id,
		SR.resource_id,
		IsNull(R.resource_code,RT.resource_type_code),
		IsNull(R.resource_name,RT.resource_type_name),
		IsNull(SR.calendar_id,R.calendar_id),
		R.pool_qty
	FROM	dbo.sched_resource SR
	left outer join dbo.resource R (nolock) on SR.resource_id = R.resource_id
	join dbo.resource_type RT (nolock) on SR.resource_type_id = RT.resource_type_id
	join #location L (nolock) on SR.location = L.location
	WHERE	SR.sched_id = @sched_id


DROP TABLE #location

CREATE TABLE #calendar
	(
	calendar_id		INT,
	calendar_worktime_id	INT,
	work_date		DATETIME,
	beg_datetime		DATETIME,
	end_datetime		DATETIME
	)

SELECT	@calendar_id=MIN(R.calendar_id)
FROM	#resource R

WHILE @calendar_id IS NOT NULL
	BEGIN
	INSERT	#calendar(calendar_id,calendar_worktime_id,work_date,beg_datetime,end_datetime)
	EXECUTE	dbo.fs_build_calendar @build_mode='W',@calendar_id=@calendar_id,@beg_date=@beg_date,@end_date=@end_date

	SELECT	@calendar_id=MIN(R.calendar_id)
	FROM	#resource R
	WHERE	R.calendar_id > @calendar_id
	END


CREATE TABLE #result
	(
	result_id		INT		IDENTITY,
	sched_resource_id	INT,
	fence_name		VARCHAR(32)	NULL,
	work_date		DATETIME,
	beg_datetime		DATETIME,
	end_datetime		DATETIME,
	tot_time		FLOAT,
	set_time		FLOAT,
	run_time		FLOAT 
	)

IF @sched_id IS NOT NULL
	BEGIN
	
	INSERT	#result
		(
		sched_resource_id,
		work_date,
		beg_datetime,
		end_datetime,
		tot_time,
		set_time,
		run_time
		)
	SELECT	R.sched_resource_id,	
		C.work_date,		
		C.beg_datetime,		
		C.end_datetime,		
		datediff(minute,C.beg_datetime,C.end_datetime)	
		* IsNull((SELECT RP.pool_qty FROM dbo.resource_pool RP WHERE RP.resource_id = R.resource_id AND RP.calendar_worktime_id = C.calendar_worktime_id),R.pool_qty)
		/ 60.0,
		0.0,			
		0.0			
	FROM	#resource R,
		#calendar C
	WHERE	C.calendar_id = R.calendar_id
	ORDER BY R.sched_resource_id,C.work_date
	END


DROP TABLE #calendar

CREATE CLUSTERED INDEX #primary ON #result(result_id)


IF @sched_id IS NOT NULL
	BEGIN
	
	SELECT	@result_id=MIN(R.result_id)
	FROM	#result R

	WHILE @result_id IS NOT NULL
		BEGIN
		
		SELECT	@sched_resource_id = R.sched_resource_id,
			@beg_datetime = R.beg_datetime,
			@end_datetime = R.end_datetime
		FROM	#result R
		WHERE	R.result_id = @result_id

		
		SELECT	@run_time = SUM (( datediff(minute,SO.work_datetime,SO.done_datetime)
					 + datediff(minute,@beg_datetime,@end_datetime)
					 - datediff(minute,SO.work_datetime,@beg_datetime)
					 * sign(datediff(minute,SO.work_datetime,@beg_datetime))
					 - datediff(minute,SO.done_datetime,@end_datetime)
					 * sign(datediff(minute,SO.done_datetime,@end_datetime))) * SOR.pool_qty) / 120.0
		FROM	dbo.sched_process SP ,
			dbo.sched_operation SO ,
			dbo.sched_operation_resource SOR 
		WHERE	SP.sched_id = @sched_id
		AND	SO.sched_process_id = SP.sched_process_id
		AND	SOR.sched_operation_id = SO.sched_operation_id
		AND	SOR.sched_resource_id = @sched_resource_id
		AND	SO.work_datetime < @end_datetime
		AND	SO.done_datetime > @beg_datetime

		SELECT	@set_time = SUM (( datediff(minute,SOR.setup_datetime,SO.work_datetime)
					 + datediff(minute,@beg_datetime,@end_datetime)
					 - datediff(minute,SOR.setup_datetime,@beg_datetime)
					 * sign(datediff(minute,SOR.setup_datetime,@beg_datetime))
					 - datediff(minute,SO.work_datetime,@end_datetime)
					 * sign(datediff(minute,SO.work_datetime,@end_datetime))) * SOR.pool_qty) / 120.0
		FROM	dbo.sched_process SP,
			dbo.sched_operation SO,
			dbo.sched_operation_resource SOR
		WHERE	SP.sched_id = @sched_id
		AND	SO.sched_process_id = SP.sched_process_id
		AND	SOR.sched_operation_id = SO.sched_operation_id
		AND	SOR.sched_resource_id = @sched_resource_id
		AND	SOR.setup_datetime < @end_datetime
		AND	SO.work_datetime > @beg_datetime

		UPDATE	#result
		SET	run_time = IsNull(@run_time,0),
			set_time = IsNull(@set_time,0)
		WHERE	result_id = @result_id

		
		SELECT	@result_id=MIN(R.result_id)
		FROM	#result R
		WHERE	R.result_id > @result_id
		END

	END



UPDATE	#result
SET	fence_name = (	SELECT	MIN(SF1.fence_name)
			FROM	dbo.sched_fence SF1
			WHERE	SF1.fence_time=(SELECT	MIN(SF2.fence_time)
						FROM	dbo.sched_fence SF2
						WHERE	datediff(day,getdate(),R.work_date) < SF2.fence_time))
FROM	#result R

UPDATE	#result
SET	fence_name = 'Free Zone'
WHERE	fence_name IS NULL


SELECT	R.sched_resource_id,
	R.resource_id,
	R.resource_code,
	R.resource_name,
	D.fence_name,
	D.work_date,
	D.tot_time,
	D.set_time,
	D.run_time
FROM	#resource R
left outer join #result D on R.sched_resource_id = D.sched_resource_id
ORDER BY resource_id,work_date


DROP TABLE #resource
DROP TABLE #result

END
GO
GRANT EXECUTE ON  [dbo].[fs_resource_utilization] TO [public]
GO
