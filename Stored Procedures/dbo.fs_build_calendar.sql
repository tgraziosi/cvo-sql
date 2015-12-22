SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE PROCEDURE [dbo].[fs_build_calendar]
	(
	@build_mode		CHAR(1) = 'A',
	@beg_date		DATETIME,
	@end_date		DATETIME,
	@calendar_id		INT
	)

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
	@downtime_id		INT






SELECT	@beg_date = datename(year,@beg_date)+'-'+datename(month,@beg_date)+'-'+datename(day,@beg_date),
	@end_date = datename(year,@end_date)+'-'+datename(month,@end_date)+'-'+datename(day,@end_date)





CREATE TABLE #result
	(
	calendar_worktime_id	INT,
	work_date		DATETIME,
	beg_datetime		DATETIME,
	end_datetime		DATETIME,
	downtime_id		INT		NULL
	)





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


FETCH c_worktime INTO @calendar_worktime_id,@eff_date, @exp_date, @beg_time, @end_time, @weekday_mask, @week_multiple, @month_multiple, @monthweek, @monthday

WHILE @@Fetch_Status = 0
	BEGIN
	
	SELECT	@beg_loop_date=@beg_date,
		@end_loop_date=@end_date
	IF @beg_loop_date < @eff_date
		SELECT @beg_loop_date = @eff_date
	IF @end_loop_date > @exp_date
		SELECT @end_loop_date = @exp_date

	
	WHILE @beg_loop_date <= @end_loop_date
		BEGIN
		SELECT	@error=0

		
		SELECT	@beg_datetime = dateadd(minute,@beg_time * 60,@beg_loop_date),
			@end_datetime = dateadd(minute,@end_time * 60,@beg_loop_date)

		
		IF @weekday_mask IS NOT NULL
			IF (@weekday_mask & power(2,datepart(weekday,@beg_loop_date) - 1)) = 0
				SELECT	@error = @error + 1

		
		IF @week_multiple IS NOT NULL
			IF datediff(week,@eff_date,@beg_loop_date) % @week_multiple > 0
				SELECT	@error = @error + 1

		
		IF @month_multiple IS NOT NULL
			IF datediff(month,@eff_date,@beg_loop_date) % @month_multiple > 0
				SELECT	@error = @error + 1

		
		IF @monthweek IS NOT NULL
			IF (datepart(day,@beg_loop_date) - 1) / 7 <> @monthweek - 1
				SELECT	@error = @error + 1

		
		IF @monthday IS NOT NULL
			IF datepart(day,@beg_loop_date) <> @monthday
				SELECT	@error = @error + 1

		
		IF @error = 0
			BEGIN
			INSERT	#result
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

		
		SELECT	@beg_loop_date = dateadd(day,1,@beg_loop_date)
		END

	
	FETCH c_worktime INTO @calendar_worktime_id,@eff_date, @exp_date, @beg_time, @end_time, @weekday_mask, @week_multiple, @month_multiple, @monthweek, @monthday
	END

CLOSE c_worktime

DEALLOCATE c_worktime





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


FETCH c_downtime INTO @downtime_id, @eff_date, @exp_date, @beg_time, @end_time, @weekday_mask, @week_multiple, @month_multiple, @monthweek, @monthday

WHILE @@Fetch_Status = 0
	BEGIN
	
	SELECT	@beg_loop_date=@beg_date,
		@end_loop_date=@end_date
	IF @beg_loop_date < @eff_date
		SELECT @beg_loop_date = @eff_date
	IF @end_loop_date > @exp_date
		SELECT @end_loop_date = @exp_date

	
	WHILE @beg_loop_date <= @end_loop_date
		BEGIN
		SELECT	@error=0

		
		SELECT	@beg_datetime = dateadd(minute,@beg_time * 60,@beg_loop_date),
			@end_datetime = dateadd(minute,@end_time * 60,@beg_loop_date)

		
		IF @weekday_mask IS NOT NULL
			IF (@weekday_mask & power(2,datepart(weekday,@beg_loop_date) - 1)) = 0
				SELECT	@error = @error + 1

		
		IF @week_multiple IS NOT NULL
			IF datediff(week,@eff_date,@beg_loop_date) % @week_multiple > 0
				SELECT	@error = @error + 1

		
		IF @month_multiple IS NOT NULL
			IF datediff(month,@eff_date,@beg_loop_date) % @month_multiple > 0
				SELECT	@error = @error + 1

		
		IF @monthweek IS NOT NULL
			IF (datepart(day,@beg_loop_date) - 1) / 7 <> @monthweek - 1
				SELECT	@error = @error + 1

		
		IF @monthday IS NOT NULL
			IF datepart(day,@beg_loop_date) <> @monthday
				SELECT	@error = @error + 1

		
		IF @error = 0
			BEGIN
			IF @beg_time IS NULL OR @end_time IS NULL
				UPDATE	#result
				SET	downtime_id = @downtime_id
				WHERE	work_date = @beg_loop_date
			ELSE
				BEGIN
				INSERT	#result
					(
					calendar_worktime_id,
					work_date,
					beg_datetime,
					end_datetime,
					downtime_id
					)
				SELECT	R.calendar_worktime_id,
					R.work_date,
					R.beg_datetime,
					@beg_datetime,
					R.downtime_id
				FROM	#result R
				WHERE	R.beg_datetime < @beg_datetime
				AND	R.end_datetime > @beg_datetime

				INSERT	#result
					(
					calendar_worktime_id,
					work_date,
					beg_datetime,
					end_datetime,
					downtime_id
					)
				SELECT	R.calendar_worktime_id,
					R.work_date,
					@end_datetime,
					R.end_datetime,
					R.downtime_id
				FROM	#result R
				WHERE	R.beg_datetime > @end_datetime
				AND	R.end_datetime < @end_datetime

				UPDATE	#result
				SET	downtime_id = @downtime_id,
					beg_datetime = @beg_datetime
				WHERE	beg_datetime < @beg_datetime
				AND	end_datetime > @beg_datetime

				UPDATE	#result
				SET	downtime_id = @downtime_id,
					end_datetime = @end_datetime
				WHERE	beg_datetime > @end_datetime
				AND	end_datetime < @end_datetime


				UPDATE	#result
				SET	downtime_id = @downtime_id
				WHERE	beg_datetime > @beg_datetime
				AND	end_datetime < @end_datetime
				END
			END

		
		SELECT	@beg_loop_date = dateadd(day,1,@beg_loop_date)
		END

	
	FETCH c_downtime INTO @downtime_id, @eff_date, @exp_date, @beg_time, @end_time, @weekday_mask, @week_multiple, @month_multiple, @monthweek, @monthday
	END

CLOSE c_downtime

DEALLOCATE c_downtime





IF @build_mode = 'F'
	SELECT	R.work_date,R.beg_datetime,R.end_datetime,R.downtime_id
	FROM	#result R
	ORDER BY beg_datetime
ELSE IF @build_mode = 'A'
	SELECT	R.work_date,R.beg_datetime,R.end_datetime
	FROM	#result R
	WHERE	R.downtime_id IS NULL
	ORDER BY beg_datetime
ELSE IF @build_mode = 'I'
	SELECT	@calendar_id,R.work_date,R.beg_datetime,R.end_datetime
	FROM	#result R
	WHERE	R.downtime_id IS NULL
	ORDER BY beg_datetime
ELSE IF @build_mode = 'W'
	SELECT	@calendar_id,R.calendar_worktime_id,R.work_date,R.beg_datetime,R.end_datetime
	FROM	#result R
	WHERE	R.downtime_id IS NULL
	ORDER BY beg_datetime

RETURN
END
GO
GRANT EXECUTE ON  [dbo].[fs_build_calendar] TO [public]
GO
