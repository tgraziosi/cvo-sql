SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_LTMOP_RES_View](@by_Emp_Res varchar(15), @date_start datetime, @date_end datetime, @select int) 
AS
-- ###############################################################################################
-- @select = 0 to display resource based on employee who used that resource during the working day
-- @select = 1 to display a specific resource and the employee(s) who used that resource
-- @select = 2 to display work order and the employee(s) associated with that WO
-- ###############################################################################################
SET NOCOUNT ON
BEGIN
	DECLARE @counter 	int, 
		@I		int,
		@temp_day	varchar(3),		
		@temp_date	varchar(11),
		@resource_on	varchar(5),
		@resource_off	varchar(5),
		@total_time	decimal(4,2),
		@resource	varchar(15),
		@downtime	varchar(15),
		@employee	varchar(15),
		@description	varchar(80),
		@date		datetime,
		@temp_shift	varchar(15),
		@maxHours	decimal(4,2),
		@shiftStart	datetime,
		@id		int

	SELECT @counter = datediff(dd, @date_start, @date_end)
	SELECT @I	= 0	
		
	WHILE (@I <= @counter)
	BEGIN
		TRUNCATE TABLE #tdc_resource
		SELECT @shiftStart = ''
		-- Day
		SELECT @temp_day 	= datename(dw, @date_start)
		-- Date
		SELECT @temp_date 	= convert(varchar(11), @date_start, 101)

		-- By Employee_pin : @by_Emp_Res = employee_pin
		-- From employee_pin, find resources, descriptions, downtimes, ON/OFF/ELP times 
		-- used by that employee during [@date_start, @date_end] period
		IF @select = 0 
		BEGIN
			IF EXISTS(SELECT * FROM tdc_labor_tx_queue q, tdc_shift_profile s WHERE employee_pin = @by_Emp_Res
					AND q.shift_code = s.shift_code AND q.activity_time >= @date_start 
					AND q.activity_time <= dateadd(hh, 24, @date_start))
			BEGIN 
				SELECT 	@temp_shift	= q.shift_code,
					@maxHours	= s.maximum_hours,
					@shiftStart	= q.activity_time 
					FROM tdc_labor_tx_queue q, tdc_shift_profile s
					WHERE employee_pin = @by_Emp_Res AND q.shift_code = s.shift_code
					AND activity_code = 'Shift' AND activity_direction = 'ON'
					AND q.activity_time >= @date_start AND q.activity_time <= dateadd(hh, 24, @date_start)

				-- For ELP resource, there is no need to find Time_On/OFF
				INSERT 	INTO #tdc_LTMOP_RES_View(temp_day, temp_date, resource, [description], downtime_code, resource_on, resource_off, total_time)
					SELECT 	@temp_day, @temp_date, l.resource_code, t.resource_description, l.downtime_code, NULL, convert(varchar(5), l.activity_time, 108),
						l.activity_elapsed_time
					FROM tdc_labor_tx_queue l, tdc_resource_profile t
					WHERE 	l.employee_pin = @by_Emp_Res AND l.activity_direction = 'ELP'
					AND shift_code = @temp_shift
					AND l.resource_code = t.resource_code AND l.activity_time >= @shiftStart
					AND activity_time <= dateadd(hh, @maxHours, @shiftStart)

				-- ELP resource for WO
				INSERT 	INTO #tdc_LTMOP_RES_View(temp_day, temp_date, resource, [description], downtime_code, resource_on, resource_off, total_time)
					SELECT 	@temp_day, @temp_date, l.resource_code, t.resource_description, l.downtime_code, NULL, convert(varchar(5), l.activity_time, 108),
						l.activity_elapsed_time
					FROM tdc_labor_tx_queue l, tdc_resource_profile t
					WHERE 	l.employee_pin = @by_Emp_Res AND l.activity_direction = 'ELP'
					AND shift_code = @temp_shift AND l.resource_code LIKE 'WO_%'
					AND t.resource_code = 'MFGWOVALID' AND l.activity_time >= @shiftStart
					AND activity_time <= dateadd(hh, @maxHours, @shiftStart)
			END

			-- ON/OFF resource
			INSERT INTO #tdc_resource (resource, activity_time, downtime_code, shift_code, line_no)
				SELECT resource_code, activity_time, downtime_code, NULL, row_id
						FROM tdc_labor_tx_queue
						WHERE employee_pin = @by_Emp_Res
						AND activity_code = 'Resource'
						AND activity_direction = 'ON'
						AND activity_time >= @shiftStart
						AND activity_time <= dateadd(hh, @maxHours, @shiftStart)

			DECLARE resource_cursor CURSOR FOR SELECT resource, activity_time, downtime_code, line_no FROM #tdc_resource
			OPEN resource_cursor
			FETCH NEXT FROM resource_cursor INTO @resource, @date, @downtime, @id

			WHILE (@@FETCH_STATUS = 0)
			BEGIN
				SELECT @description = (SELECT resource_description FROM tdc_resource_profile WHERE resource_code = @resource)
				SELECT @resource_on = convert(varchar(5), @date, 108)
				SELECT 	@resource_off 	= convert(varchar(5), activity_time, 108),
			  		@total_time 	= activity_elapsed_time  
							FROM tdc_labor_tx_queue
							WHERE employee_pin = @by_Emp_Res AND resource_code = @resource
							AND activity_direction = 'OFF'
							AND activity_time >= @date AND activity_time <= dateadd(hh, @maxHours, @date)
							AND row_id = (SELECT min(row_id) FROM tdc_labor_tx_queue WHERE
									resource_code = @resource AND employee_pin = @by_Emp_Res
									AND activity_direction = 'OFF' AND activity_time >= @date 
									AND activity_time <= dateadd(hh, @maxHours, @date)
									AND row_id > @id AND shift_code = @temp_shift)
				INSERT 	INTO #tdc_LTMOP_RES_View(temp_day, temp_date, resource, [description], downtime_code, resource_on, resource_off, total_time)
					VALUES(@temp_day, @temp_date, @resource, @description, @downtime, @resource_on, @resource_off, @total_time)

				FETCH NEXT FROM resource_cursor INTO @resource, @date, @downtime, @id		

			END
			DEALLOCATE resource_cursor
		END
		-- By resource - @by_Emp_Res : resource_code
		-- From resource, find  employees using that resource during [@date_start, @date_end]
		--			downtime associated with at resource (if existed)
		--			ON/OFF/ELP time
		ELSE
		BEGIN
			-- For ELP resource, there is not need to find Time_On/OFF
			INSERT INTO #tdc_LTMOP_RES_View(temp_day, temp_date, resource, [description], downtime_code, resource_on, resource_off, total_time)
				SELECT @temp_day, @temp_date, @by_Emp_Res, employee_pin, downtime_code, NULL, convert(varchar(5), activity_time, 108),
					activity_elapsed_time
				FROM tdc_labor_tx_queue
				WHERE  resource_code = @by_Emp_Res AND activity_direction = 'ELP'
				AND activity_time >= @date_start AND activity_time <= dateadd(hh, 24, @date_start)

			-- ON/OFF resource
			INSERT INTO #tdc_resource (resource, activity_time, downtime_code, shift_code, line_no)
				SELECT employee_pin, activity_time, downtime_code, shift_code, row_id 
						FROM tdc_labor_tx_queue
						WHERE resource_code = @by_Emp_Res
						AND activity_code = 'Resource'
						AND activity_direction = 'ON'
						AND activity_time >= @date_start
						AND activity_time <= dateadd(hh, 24, @date_start)

			DECLARE resource_cursor CURSOR FOR SELECT * FROM #tdc_resource
			OPEN resource_cursor
			FETCH NEXT FROM resource_cursor INTO @employee, @date, @downtime, @temp_shift, @id

			WHILE (@@FETCH_STATUS = 0)
			BEGIN
				SELECT @maxHours = maximum_hours FROM tdc_shift_profile WHERE shift_code = @temp_shift
				SELECT @resource_on = convert(varchar(5), @date, 108)
				SELECT 	@resource_off 	= convert(varchar(5), activity_time, 108),
			  		@total_time 	= activity_elapsed_time  
							FROM tdc_labor_tx_queue
							WHERE resource_code = @by_Emp_Res AND employee_pin = @employee
							AND activity_direction = 'OFF'
							AND activity_time >= @date AND activity_time <= dateadd(hh, @maxHours, @date)
							AND row_id = (SELECT min(row_id) FROM tdc_labor_tx_queue WHERE resource_code = @by_Emp_Res
									AND employee_pin = @employee AND activity_direction = 'OFF' 
									AND activity_time >= @date AND activity_time <= dateadd(hh, @maxHours, @date)
									AND shift_code = @temp_shift AND row_id > @id)
				INSERT 	INTO #tdc_LTMOP_RES_View(temp_day, temp_date, resource, [description], downtime_code, resource_on, resource_off, total_time)
					VALUES(@temp_day, @temp_date, @by_Emp_Res, @employee, @downtime, @resource_on, @resource_off, @total_time)
				FETCH NEXT FROM resource_cursor INTO @employee, @date, @downtime, @temp_shift, @id	
			END
			DEALLOCATE resource_cursor
		END 

		SELECT @I = @I + 1
		SELECT @date_start = dateadd(dd, 1, @date_start)		
	END
END
GO
GRANT EXECUTE ON  [dbo].[tdc_LTMOP_RES_View] TO [public]
GO
