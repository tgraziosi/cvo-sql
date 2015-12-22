SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE proc [dbo].[fs_populate_eforecast_time_table]
as
--select distinct * from #time 

DECLARE @config_bucket varchar(1),
		@config_month varchar(2),
		@config_week varchar(2),
		@config_day varchar(1),
		@count int,
		@timeid int, @sequence_no int, @firstday datetime, @year int, @quarter int

delete EFORECAST_SALESALL
delete EFORECAST_FORECAST
delete EFORECAST_CUSTOMER_FORECAST
delete EFORECAST_TIME

if exists( SELECT 1 FROM dbo.config WHERE dbo.config.flag = 'EFORECAST_CONFIG')
	SELECT	@config_bucket = substring(dbo.config.value_str, 1, 1),
			@config_month = CAST(substring(dbo.config.value_str, 2, 2) AS INT),
			@config_week = CAST(substring(dbo.config.value_str, 4, 2) AS INT),
			@config_day = CAST(substring(dbo.config.value_str, 6, 1) AS INT)
	FROM dbo.config
	WHERE dbo.config.flag = 'EFORECAST_CONFIG'
ELSE
	SELECT	@config_bucket = 'M',
			@config_month = 1,
			@config_week = 1,
			@config_day = 1


SELECT @year = 2005, @sequence_no = 1, @quarter = 1, @count = 1
----SELECT @year = 1996, @sequence_no = 1, @quarter = 1, @count = 1 - TAG - 12/30/2011

WHILE @year <= YEAR(GETDATE()) + 20
BEGIN
	IF (@config_bucket = 'W')
	BEGIN
		IF @config_week = 1
		BEGIN
			SELECT @firstday = '1/1/' + cast(@year as varchar(4))
			IF (DATEPART(dw, @firstday) <> @config_day)
			BEGIN
				INSERT INTO EFORECAST_TIME (TIMEID, YEAR_QUARTER, FIRST_DAY)
				VALUES (@sequence_no, (10*@year + @quarter), @firstday)
				SELECT @sequence_no = @sequence_no + 1, @count = @count + 1
				WHILE DATEPART(dw, @firstday) <> @config_day
					SELECT @firstday = DATEADD(day, 1, @firstday)
			END
				
		END
		ELSE IF @config_week = 2
		BEGIN
			SELECT @firstday = '1/1/' + cast(@year as varchar(4))
			WHILE DATEPART(dw, @firstday) <> @config_day
				SELECT @firstday = DATEADD(day, 1, @firstday)
			IF DATEDIFF(day, '1/1/' + cast(@year as varchar(4)), @firstday) >= 4
			BEGIN
				INSERT INTO EFORECAST_TIME (TIMEID, YEAR_QUARTER, FIRST_DAY)
				VALUES (@sequence_no, (10*@year + @quarter), '1/1/' + cast(@year as varchar(4)))
				SELECT @sequence_no = @sequence_no + 1, @count = @count + 1
			END
		END
		ELSE --@config_week = 3
		BEGIN
			SELECT @firstday = '1/1/' + cast(@year as varchar(4))
			WHILE DATEPART(dw, @firstday) <> @config_day
				SELECT @firstday = DATEADD(day, 1, @firstday)
		END
	
		WHILE (YEAR(@firstday) = @year)
		BEGIN
			INSERT INTO EFORECAST_TIME (TIMEID, YEAR_QUARTER, FIRST_DAY)
			VALUES (@sequence_no, (10*@year + @quarter), @firstday)
			SELECT @firstday = DATEADD(week, 1, @firstday),
				@sequence_no = @sequence_no + 1, 
				@count = @count + 1
			IF @count > 13 and @quarter < 4 SELECT @count = 1, @quarter = @quarter + 1
	
		END
	
	END
	ELSE
	BEGIN
		SELECT @firstday = CAST(@config_month as varchar(2)) + '/01/' + CAST(@year as varchar(4)),
			@count = 0
		WHILE @count < 12
		BEGIN
			INSERT INTO EFORECAST_TIME (TIMEID, YEAR_QUARTER, FIRST_DAY)
			VALUES (@sequence_no+1, @year, DATEADD(month, @count, @firstday))
			SELECT @sequence_no = @sequence_no + 1, @count = @count + 1
		END
	END
	SELECT @year = @year + 1, @quarter = 1, @count = 1
END


/**/
GO
GRANT EXECUTE ON  [dbo].[fs_populate_eforecast_time_table] TO [public]
GO
