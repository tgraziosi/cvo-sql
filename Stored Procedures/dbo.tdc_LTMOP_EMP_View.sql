SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[tdc_LTMOP_EMP_View](@employee_pin varchar(15), @date_start datetime, @date_end datetime, @select int) 
AS

SET NOCOUNT ON

TRUNCATE TABLE #tdc_LTMOP_Review

BEGIN	
DECLARE @counter 	int, 
	@I		int,
	@temp_day	varchar(3),		
	@temp_date	varchar(11),
	@clock_in	varchar(5),
	@clock_off	varchar(5),
	@break1		decimal(4,2),
	@break2		decimal(4,2),
	@break3		decimal(4,2),
	@lunch_on	varchar(5),
	@lunch_off	varchar(5),
	@lunch_elapsed	decimal(4,2),
	@total_time	decimal(4,2),
	@shift		varchar(15), 
	@tolerance_end 	int,
	@tolerance_start int,
	@max_hour	int,
	@date		datetime,
	@adhoc 		decimal(4,2), 
	@paylunch	varchar(1),
	@lunchvalue	int,
	@On		datetime,
	@Off		datetime,
	@ClockLunch 	char(1)
	
	SELECT @counter = datediff(dd, @date_start, @date_end)
	SELECT @I	= 0	

	TRUNCATE TABLE #tdc_shift			
	WHILE (@I <= @counter)
	BEGIN
		-- find out the shift_code from employee_pin
		-- could use the shift_code assigned to the employee_pin from tdc_employee_profile 
		-- however, in case employee happens to come in different shift, and selecting shift from 
		-- tdc_employee_profile could miss this case
		SELECT @adhoc = 0
		TRUNCATE TABLE #temp_shift
		INSERT INTO #temp_shift (shift_code)  SELECT DISTINCT shift_code
					FROM tdc_labor_tx_queue WHERE employee_pin = @employee_pin
					AND activity_code in ('shift', 'Adhoc') AND activity_direction in('ON', 'ADH')
					AND activity_time >= @date_start 
					AND activity_time <= dateadd(hh, 24, @date_start)

		DECLARE shift_cursor CURSOR FOR SELECT * FROM #temp_shift
		OPEN shift_cursor
		FETCH NEXT FROM shift_cursor INTO @shift

		-- Find shift_on 
		WHILE (@@FETCH_STATUS = 0)
		BEGIN
			-- Find the tolerance if applied
			SELECT 	@tolerance_start= tolerance_start, 
				@tolerance_end 	= tolerance_end,
				@max_hour	= maximum_hours
			FROM tdc_shift_profile WHERE shift_code = @shift
			
			INSERT INTO #tdc_shift (shift_code, activity_code)
				SELECT @shift, activity_time FROM tdc_labor_tx_queue
						WHERE employee_pin = @employee_pin AND shift_code = @shift 
						AND activity_code = 'shift' AND activity_direction = 'ON'
						AND activity_time >= @date_start
						AND activity_time <= dateadd(hh, 24, @date_start) 			

			FETCH NEXT FROM shift_cursor INTO @shift
		END 
		DEALLOCATE shift_cursor

		-- From shift on, get shift_off, lunch, break
		DECLARE shift_cursor CURSOR FOR SELECT * FROM #tdc_shift
		OPEN shift_cursor
		FETCH NEXT FROM shift_cursor INTO @shift, @date	
		WHILE (@@FETCH_STATUS = 0)
		BEGIN
			SELECT 	@max_hour	= maximum_hours,
				@paylunch	= pay_lunch,
				@lunchvalue	= lunch_value
				FROM tdc_shift_profile WHERE shift_code = @shift

			IF @paylunch = 'N' 
			BEGIN
				SELECT @max_hour = @max_hour + @lunchvalue/60
			END

			-- Day
			SELECT @temp_day 	= datename(dw, @date)
			-- Date
			SELECT @temp_date 	= convert(varchar(11), @date, 101)
			
			-- Break1
			SELECT @On		= (SELECT activity_time FROM tdc_labor_tx_queue
							WHERE employee_pin = @employee_pin AND activity_code = 'break1'
							AND activity_direction = 'ON' AND activity_time >= @date
							AND activity_time <= dateadd(hh, @max_hour, @date) ) 
			SELECT @Off		= (SELECT activity_time FROM tdc_labor_tx_queue
							WHERE employee_pin = @employee_pin AND activity_code = 'break1'
							AND activity_direction = 'OFF' AND activity_time >= @date
							AND activity_time <= dateadd(hh, @max_hour, @date) ) 
			IF @On = '1900-01-01 00:00:00.000'
			BEGIN
				SELECT @break1 = 0.0
			END

			IF @On <> '1900-01-01 00:00:00.000' AND @Off <> '1900-01-01 00:00:00.000'
			BEGIN
				SELECT @break1		= CONVERT(decimal(18,2), datediff(mi,@On, @Off)) / 60
			END 	

			-- Lunch
			SELECT @On 		= (SELECT activity_time FROM tdc_labor_tx_queue
							WHERE employee_pin = @employee_pin AND activity_code = 'lunch'
							AND activity_direction = 'ON' AND activity_time >= @date
							AND activity_time <= dateadd(hh, @max_hour, @date) ) 
			SELECT @Off		= (SELECT activity_time FROM tdc_labor_tx_queue
							WHERE employee_pin = @employee_pin AND activity_code = 'lunch'
							AND activity_direction = 'OFF' AND activity_time >= @date
							AND activity_time <= dateadd(hh, @max_hour, @date) ) 
			IF @On = '1900-01-01 00:00:00.000'
			BEGIN
				SELECT @lunch_elapsed = 0.0
			END

			IF @On <> '1900-01-01 00:00:00.000' AND @Off <> '1900-01-01 00:00:00.000'
			BEGIN
				SELECT @lunch_elapsed	= CONVERT(decimal(18, 2), datediff(mi,@On, @Off)) / 60
			END 	

			-- Break2
			SELECT @On		= (SELECT activity_time FROM tdc_labor_tx_queue
							WHERE employee_pin = @employee_pin AND activity_code = 'break2'
							AND activity_direction = 'ON' AND activity_time >= @date
							AND activity_time <= dateadd(hh, @max_hour, @date) )
			SELECT @Off		= (SELECT activity_time FROM tdc_labor_tx_queue
							WHERE employee_pin = @employee_pin AND activity_code = 'break2'
							AND activity_direction = 'OFF' AND activity_time >= @date
							AND activity_time <= dateadd(hh, @max_hour, @date) )
			IF @On = '1900-01-01 00:00:00.000'
			BEGIN
				SELECT @break2 = 0.0
			END

			IF @On <> '1900-01-01 00:00:00.000' AND @Off <> '1900-01-01 00:00:00.000'
			BEGIN
				SELECT @break2	= CONVERT(decimal(18,2), datediff(mi,@On, @Off)) / 60
			END

			-- Break3
			SELECT @On		= (SELECT activity_time FROM tdc_labor_tx_queue
							WHERE employee_pin = @employee_pin AND activity_code = 'break3'
							AND activity_direction = 'ON' AND activity_time >= @date
							AND activity_time <= dateadd(hh, @max_hour, @date) )
			SELECT @Off		= (SELECT activity_time FROM tdc_labor_tx_queue
							WHERE employee_pin = @employee_pin AND activity_code = 'break3'
							AND activity_direction = 'OFF' AND activity_time >= @date
							AND activity_time <= dateadd(hh, @max_hour, @date) )
			IF @On = '1900-01-01 00:00:00.000'
			BEGIN
				SELECT @break3 = 0.0
			END

			IF @On <> '1900-01-01 00:00:00.000' AND @Off <> '1900-01-01 00:00:00.000'
			BEGIN
				SELECT @break3	= CONVERT(decimal(18,2), datediff(mi,@On, @Off)) / 60
			END

			SELECT @adhoc		= (SELECT activity_elapsed_time FROM tdc_labor_tx_queue
							WHERE employee_pin = @employee_pin AND trans = 'ADHOC'
							AND shift_code = @shift AND activity_time >= @date
							AND activity_time <= dateadd(hh, 24, @date) ) 

			SELECT @Off		= (SELECT activity_time FROM tdc_labor_tx_queue
							WHERE employee_pin = @employee_pin AND activity_code = 'shift'
							AND activity_direction = 'OFF' AND activity_time >= @date
							AND activity_time <= dateadd(hh, @max_hour, @date) )

			IF @Off <> '1900-01-01 00:00:00.000'
			BEGIN
				IF @paylunch = 'Y'
				BEGIN
					IF @ClockLunch = 'Y'
					BEGIN
						IF @lunch_elapsed > CONVERT(decimal(18,2), @lunchvalue)/60
						BEGIN
							SELECT @total_time	= CONVERT(decimal(18,2), datediff(mi, @date, @Off)) / 60 - @lunch_elapsed + CONVERT(decimal(18,2), @lunchvalue)/60
						END
						ELSE
						BEGIN
							SELECT @total_time	= CONVERT(decimal(18,2), datediff(mi, @date, @Off)) / 60
						END
					END
					ELSE
					BEGIN
						SELECT @total_time	= CONVERT(decimal(18,2), datediff(mi, @date, @Off)) / 60
					END
				END
				ELSE
				BEGIN
					IF @ClockLunch = 'Y'
					BEGIN
						IF @lunch_elapsed < CONVERT(decimal(18,2),@lunchvalue)/60
						BEGIN
							SELECT @total_time	= CONVERT(decimal(18,2), (datediff(mi, @date, @Off) - @lunchvalue)) / 60  
						END
						ELSE
						BEGIN
							SELECT @total_time	= CONVERT(decimal(18,2), datediff(mi, @date, @Off)) / 60 - @lunch_elapsed
						END
					END
					ELSE
					BEGIN
						SELECT @total_time	= CONVERT(decimal(18,2), datediff(mi, @date, @Off)) / 60 - @lunch_elapsed
					END
				END
				
			END
			ELSE
			BEGIN
				SELECT @total_time = 0.0
			END

			IF @adhoc <> NULL
			BEGIN
				SELECT @total_time = @total_time + @adhoc
			END

			-- Detail Round Time
			if @select = 1
			BEGIN
				SELECT @clock_in 	= (SELECT convert(varchar(7), activity_time, 108) FROM tdc_labor_tx_queue
							WHERE employee_pin = @employee_pin AND activity_code = 'shift'
							AND activity_direction = 'ON' AND activity_time >= @date
							AND activity_time <= dateadd(hh, @max_hour, @date) )

				SELECT @lunch_on	= (SELECT convert(varchar(7), activity_time, 108) FROM tdc_labor_tx_queue
							WHERE employee_pin = @employee_pin AND activity_code = 'lunch'
							AND activity_direction = 'ON' AND activity_time >= @date
							AND activity_time <= dateadd(hh, @max_hour, @date) )
				SELECT @lunch_off	= (SELECT convert(varchar(7), activity_time, 108) FROM tdc_labor_tx_queue
							WHERE employee_pin = @employee_pin AND activity_code = 'lunch'
							AND activity_direction = 'OFF' AND activity_time >= @date
							AND activity_time <= dateadd(hh, @max_hour, @date) )

				SELECT @clock_off	= (SELECT convert(varchar(7), activity_time, 108) FROM tdc_labor_tx_queue
							WHERE employee_pin = @employee_pin AND activity_code = 'shift'
							AND activity_direction = 'OFF' AND activity_time >= @date
							AND activity_time <= dateadd(hh, @max_hour, @date) ) 
			END

			-- Detail Actual Time
			IF @select = 2 
			BEGIN
				SELECT @clock_in 	= (SELECT convert(varchar(7), transaction_time, 108) FROM tdc_labor_tx_queue
							WHERE employee_pin = @employee_pin AND activity_code = 'shift'
							AND activity_direction = 'ON' AND activity_time >= @date
							AND activity_time <= dateadd(hh, @max_hour, @date) )

				SELECT @lunch_on	= (SELECT convert(varchar(7), transaction_time, 108) FROM tdc_labor_tx_queue
							WHERE employee_pin = @employee_pin AND activity_code = 'lunch'
							AND activity_direction = 'ON' AND activity_time >= @date
							AND activity_time <= dateadd(hh, @max_hour, @date) )

				SELECT @lunch_off	= (SELECT convert(varchar(7), transaction_time, 108) FROM tdc_labor_tx_queue
							WHERE employee_pin = @employee_pin AND activity_code = 'lunch'
							AND activity_direction = 'OFF' AND activity_time >= @date
							AND activity_time <= dateadd(hh, @max_hour, @date) )

				SELECT @clock_off	= (SELECT convert(varchar(7), transaction_time, 108) FROM tdc_labor_tx_queue
							WHERE employee_pin = @employee_pin AND activity_code = 'shift'
							AND activity_direction = 'OFF' AND activity_time >= @date
							AND activity_time <= dateadd(hh, @max_hour, @date) ) 										
			END
	
			INSERT INTO #tdc_LTMOP_Review(temp_day, temp_date, shift_on, break1, lunch_on, lunch_off, lunch_elapsed, break2, break3, shift_off, adhoc, total_time)  
			VALUES(@temp_day, @temp_date, @clock_in, @break1, @lunch_on, @lunch_off, @lunch_elapsed, @break2,@break3, @clock_off, @adhoc, @total_time)
			
			FETCH NEXT FROM shift_cursor INTO @shift, @date	
		END
		DEALLOCATE shift_cursor

		SELECT @I = @I + 1
		SELECT @date_start = dateadd(dd, 1, @date_start)			
		TRUNCATE TABLE #tdc_shift
	END
END	
GO
GRANT EXECUTE ON  [dbo].[tdc_LTMOP_EMP_View] TO [public]
GO
