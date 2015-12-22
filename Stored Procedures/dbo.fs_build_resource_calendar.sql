SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE PROCEDURE [dbo].[fs_build_resource_calendar]
	(
	@sched_resource_id	INT,
	@beg_date		DATETIME,
	@end_date		DATETIME
	)
WITH ENCRYPTION
AS
BEGIN

DECLARE	@calendar_worktime_id	INT,
	@eff_date		DATETIME,
	@exp_date		DATETIME,
	@beg_time		FLOAT,
	@end_time		FLOAT,
	@weekday_mask		INT,
	@week_multiple		INT,
	@month_multiple		INT,
	@monthweek		INT,
	@monthday		INT,
	@beg_loop_date		DATETIME,
	@end_loop_date		DATETIME,
	@beg_datetime		DATETIME,
	@end_datetime		DATETIME,
	@error			INT,
	@downtime_id		INT,
	@sequence_id		INT,
	@resource_id		INT,
	@calendar_id		INT,
	@pool_qty		FLOAT

-- Determine resource calendar
SELECT	@calendar_id=SR.calendar_id,
	@resource_id = SR.resource_id
FROM	dbo.sched_resource SR
WHERE	SR.sched_resource_id = @sched_resource_id

SELECT	@calendar_id=IsNull(@calendar_id,R.calendar_id),
	@pool_qty=R.pool_qty
FROM	dbo.resource R
WHERE	R.resource_id = @resource_id

-- Create table to hold base calendar
CREATE TABLE #resource_calendar
	(
	calendar_worktime_id	INT,
	work_date		DATETIME,
	beg_datetime		DATETIME,
	end_datetime		DATETIME,
	downtime_id		INT		NULL
	)

-- =================================================
-- Make sure that the passed variables actual are
-- dates without time
-- =================================================

SELECT	@beg_date = datename(year,@beg_date)+'-'+datename(month,@beg_date)+'-'+datename(day,@beg_date),
	@end_date = datename(year,@end_date)+'-'+datename(month,@end_date)+'-'+datename(day,@end_date)

-- =================================================
-- Build base calendar
-- =================================================

DECLARE c_worktime CURSOR FOR
SELECT	CW.calendar_worktime_id,
	CW.eff_date,
	CW.exp_date,
	CW.beg_time,
	CW.end_time,
	CW.weekday_mask,
	CW.week_multiple,
	CW.month_multiple,
	CW.monthweek,
	CW.monthday
FROM	dbo.calendar_worktime CW
WHERE	CW.calendar_id = @calendar_id
AND	(	CW.eff_date IS NULL
	OR	CW.eff_date < @end_date )
AND	(	CW.exp_date IS NULL
	OR	CW.exp_date > @beg_date )

OPEN c_worktime

-- Get first calendar range
FETCH c_worktime INTO @calendar_worktime_id,@eff_date,@exp_date,@beg_time,@end_time,@weekday_mask,@week_multiple,@month_multiple,@monthweek,@monthday

WHILE @@Fetch_Status = 0
	BEGIN
	-- Build effective range
	SELECT	@beg_loop_date=@beg_date,
		@end_loop_date=@end_date
	IF @beg_loop_date < @eff_date
		SELECT @beg_loop_date = @eff_date
	IF @end_loop_date > @exp_date
		SELECT @end_loop_date = @exp_date

	-- Loop looking for days that match criteria
	WHILE @beg_loop_date <= @end_loop_date
		BEGIN
		SELECT	@error=0

		-- Prepare the beginning and ending date/time, in case their needed
		SELECT	@beg_datetime = dateadd(minute,@beg_time * 60,@beg_loop_date),
			@end_datetime = dateadd(minute,@end_time * 60,@beg_loop_date)

		-- Does the day of week match?
		IF @weekday_mask IS NOT NULL
			IF (@weekday_mask & power(2,datepart(weekday,@beg_loop_date) - 1)) = 0
				SELECT	@error = @error + 1

		-- Is this a valid week?
		IF @week_multiple IS NOT NULL
			IF datediff(week,@eff_date,@beg_loop_date) % @week_multiple > 0
				SELECT	@error = @error + 1

		-- Is this a valid month?
		IF @month_multiple IS NOT NULL
			IF datediff(month,@eff_date,@beg_loop_date) % @month_multiple > 0
				SELECT	@error = @error + 1

		-- If the week of the month valid?
		IF @monthweek IS NOT NULL
			IF (datepart(day,@beg_loop_date) - 1) / 7 <> @monthweek - 1
				SELECT	@error = @error + 1

		-- If the day of the month valid?
		IF @monthday IS NOT NULL
			IF datepart(day,@beg_loop_date) <> @monthday
				SELECT	@error = @error + 1

		-- If we made it here matching everything, do the deed
		IF @error = 0
			BEGIN
			INSERT	#resource_calendar
				(
				calendar_worktime_id,
				work_date,
				beg_datetime,
				end_datetime
				)
			VALUES	(
				@calendar_worktime_id,
				@beg_loop_date,
				@beg_datetime,
				@end_datetime
				)
			END

		-- Move to next day
		SELECT	@beg_loop_date = dateadd(day,1,@beg_loop_date)
		END

	-- Get next calendar range
	FETCH c_worktime INTO @calendar_worktime_id,@eff_date, @exp_date, @beg_time, @end_time, @weekday_mask, @week_multiple, @month_multiple, @monthweek, @monthday
	END

CLOSE c_worktime

DEALLOCATE c_worktime

-- =================================================
-- Remove downtime
-- =================================================

DECLARE c_downtime CURSOR FOR
SELECT	CD.downtime_id,
	CD.eff_date,
	CD.exp_date,
	CD.beg_time,
	CD.end_time,
	CD.weekday_mask,
	CD.week_multiple,
	CD.month_multiple,
	CD.monthweek,
	CD.monthday
FROM	dbo.calendar_downtime CD
WHERE	CD.calendar_id = @calendar_id
AND	(	CD.eff_date IS NULL
	OR	CD.eff_date < @end_date )
AND	(	CD.exp_date IS NULL
	OR	CD.exp_date > @beg_date )

OPEN c_downtime

-- Get first calendar range
FETCH c_downtime INTO @downtime_id, @eff_date, @exp_date, @beg_time, @end_time, @weekday_mask, @week_multiple, @month_multiple, @monthweek, @monthday

WHILE @@Fetch_Status = 0
	BEGIN
	-- Build effective range
	SELECT	@beg_loop_date=@beg_date,
		@end_loop_date=@end_date
	IF @beg_loop_date < @eff_date
		SELECT @beg_loop_date = @eff_date
	IF @end_loop_date > @exp_date
		SELECT @end_loop_date = @exp_date

	-- Loop looking for days that match criteria
	WHILE @beg_loop_date <= @end_loop_date
		BEGIN
		SELECT	@error=0

		-- Prepare the beginning and ending date/time, in case their needed
		SELECT	@beg_datetime = dateadd(minute,@beg_time * 60,@beg_loop_date),
			@end_datetime = dateadd(minute,@end_time * 60,@beg_loop_date)

		-- Does the day of week match?
		IF @weekday_mask IS NOT NULL
			IF (@weekday_mask & power(2,datepart(weekday,@beg_loop_date) - 1)) = 0
				SELECT	@error = @error + 1

		-- Is this a valid week?
		IF @week_multiple IS NOT NULL
			IF datediff(week,@eff_date,@beg_loop_date) % @week_multiple > 0
				SELECT	@error = @error + 1

		-- Is this a valid month?
		IF @month_multiple IS NOT NULL
			IF datediff(month,@eff_date,@beg_loop_date) % @month_multiple > 0
				SELECT	@error = @error + 1

		-- If the week of the month valid?
		IF @monthweek IS NOT NULL
			IF (datepart(day,@beg_loop_date) - 1) / 7 <> @monthweek - 1
				SELECT	@error = @error + 1

		-- If the day of the month valid?
		IF @monthday IS NOT NULL
			IF datepart(day,@beg_loop_date) <> @monthday
				SELECT	@error = @error + 1

		-- If we made it here matching everything, do the deed
		IF @error = 0
			BEGIN
			IF @beg_time IS NULL OR @end_time IS NULL
				UPDATE	#resource_calendar
				SET	downtime_id = @downtime_id
				WHERE	work_date = @beg_loop_date
			ELSE
				BEGIN
				INSERT	#resource_calendar
					(
					calendar_worktime_id,
					work_date,
					beg_datetime,
					end_datetime,
					downtime_id
					)
				SELECT	RC.calendar_worktime_id,
					RC.work_date,
					RC.beg_datetime,
					@beg_datetime,
					RC.downtime_id
				FROM	#resource_calendar RC
				WHERE	RC.beg_datetime < @beg_datetime
				AND	RC.end_datetime > @beg_datetime

				INSERT	#resource_calendar
					(
					calendar_worktime_id,
					work_date,
					beg_datetime,
					end_datetime,
					downtime_id
					)
				SELECT	RC.calendar_worktime_id,
					RC.work_date,
					@end_datetime,
					RC.end_datetime,
					RC.downtime_id
				FROM	#resource_calendar RC
				WHERE	RC.beg_datetime > @end_datetime
				AND	RC.end_datetime < @end_datetime

				UPDATE	#resource_calendar
				SET	downtime_id = @downtime_id,
					beg_datetime = @beg_datetime
				WHERE	beg_datetime < @beg_datetime
				AND	end_datetime > @beg_datetime

				UPDATE	#resource_calendar
				SET	downtime_id = @downtime_id,
					end_datetime = @end_datetime
				WHERE	beg_datetime > @end_datetime
				AND	end_datetime < @end_datetime


				UPDATE	#resource_calendar
				SET	downtime_id = @downtime_id
				WHERE	beg_datetime > @beg_datetime
				AND	end_datetime < @end_datetime
				END
			END

		-- Move to next day
		SELECT	@beg_loop_date = dateadd(day,1,@beg_loop_date)
		END

	-- Get next calendar range
	FETCH c_downtime INTO @downtime_id, @eff_date, @exp_date, @beg_time, @end_time, @weekday_mask, @week_multiple, @month_multiple, @monthweek, @monthday
	END

CLOSE c_downtime

DEALLOCATE c_downtime

-- =================================================
-- Build availability table
-- =================================================

CREATE TABLE #resource_pool
	(
	beg_datetime		DATETIME,
	end_datetime		DATETIME,
	pool_qty		FLOAT
	)

-- Retrieve the available pool qty
INSERT	#resource_pool(beg_datetime,end_datetime,pool_qty)
SELECT	beg_datetime,end_datetime,IsNull(RP.pool_qty,@pool_qty)
FROM	#resource_calendar RC
left outer join dbo.resource_pool RP (nolock) on RP.calendar_worktime_id = RC.calendar_worktime_id and RP.resource_id = @resource_id
WHERE	RC.downtime_id IS NULL

-- The calendar is no longer necessary
DROP TABLE #resource_calendar

-- =================================================
-- Determine all scheduled operations for resource
-- =================================================

CREATE TABLE #resource_work
	(
	sequence_id		INT IDENTITY,
	beg_datetime		DATETIME,
	end_datetime		DATETIME,
	pool_qty		FLOAT
	)

-- Get all the jobs running in the region
INSERT	#resource_work(beg_datetime,end_datetime,pool_qty)
SELECT	SOR.setup_datetime,SO.done_datetime,SOR.pool_qty
FROM	dbo.sched_operation_resource SOR,
	dbo.sched_operation SO
WHERE	SOR.sched_resource_id = @sched_resource_id
AND	SOR.setup_datetime < @end_date
AND	SO.sched_operation_id = SOR.sched_operation_id
AND	SO.done_datetime > @beg_date


-- =================================================
-- Apply schedule jobs to availability
-- =================================================

SELECT	@sequence_id=MIN(RW.sequence_id)
FROM	#resource_work RW

WHILE @sequence_id IS NOT NULL
	BEGIN
	-- Get the pool quantity
	SELECT	@beg_datetime = RW.beg_datetime,
		@end_datetime = RW.end_datetime,
		@pool_qty = RW.pool_qty
	FROM	#resource_work RW
	WHERE	RW.sequence_id = @sequence_id

	-- Break up the start span into included and excluded
	INSERT	#resource_pool(beg_datetime,end_datetime,pool_qty)
	SELECT	RP.beg_datetime,@beg_datetime,RP.pool_qty
	FROM	#resource_pool RP
	WHERE	RP.beg_datetime < @beg_datetime
	AND	RP.end_datetime > @beg_datetime

	INSERT	#resource_pool(beg_datetime,end_datetime,pool_qty)
	SELECT	@beg_datetime,RP.end_datetime,RP.pool_qty
	FROM	#resource_pool RP
	WHERE	RP.beg_datetime < @beg_datetime
	AND	RP.end_datetime > @beg_datetime

	DELETE	#resource_pool
	FROM	#resource_pool RP
	WHERE	RP.beg_datetime < @beg_datetime
	AND	RP.end_datetime > @beg_datetime

	-- Break up the finish span into included and excluded
	INSERT	#resource_pool(beg_datetime,end_datetime,pool_qty)
	SELECT	RP.beg_datetime,@end_datetime,RP.pool_qty
	FROM	#resource_pool RP
	WHERE	RP.beg_datetime < @end_datetime
	AND	RP.end_datetime > @end_datetime

	INSERT	#resource_pool(beg_datetime,end_datetime,pool_qty)
	SELECT	@end_datetime,RP.end_datetime,RP.pool_qty
	FROM	#resource_pool RP
	WHERE	RP.beg_datetime < @end_datetime
	AND	RP.end_datetime > @end_datetime

	DELETE	#resource_pool
	FROM	#resource_pool RP
	WHERE	RP.beg_datetime < @end_datetime
	AND	RP.end_datetime > @end_datetime

	-- Subtract out all pool quantity
	UPDATE	#resource_pool
	SET	pool_qty = pool_qty - @pool_qty
	FROM	#resource_pool RP
	WHERE	RP.end_datetime > @beg_datetime
	AND	RP.beg_datetime < @end_datetime

	-- Get next scheduled work sequence to subtract from availability
	SELECT	@sequence_id=MIN(RW.sequence_id)
	FROM	#resource_work RW
	WHERE	RW.sequence_id > @sequence_id
	END

-- We are done with the resource scheduled jobs
DROP TABLE #resource_work

-- =================================================
-- Report back our findings
-- =================================================

SELECT	@sched_resource_id,RP.beg_datetime,RP.end_datetime,RP.pool_qty
FROM	#resource_pool RP
ORDER BY RP.beg_datetime

-- Clean up last table
DROP TABLE #resource_pool

RETURN
END
GO
GRANT EXECUTE ON  [dbo].[fs_build_resource_calendar] TO [public]
GO
