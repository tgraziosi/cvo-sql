SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[fs_get_forecast_history]
	@part_no	varchar (30), 
	@location	varchar (20), 
	@year	int,
	@quarter int

AS

DECLARE @config_bucket varchar(1),
		@config_month varchar(2),
		@config_week varchar(2),
		@config_day varchar(1),
		@count int,
		@config_str varchar(6),
		@year_quarter int,
		@min_year_quarter int,
		@max_year_quarter int,
		@colstr nvarchar(1000),
		@valstr nvarchar(1000),
		@partid int,
		@locid int,
		@timeid int,
		@sqlstr nvarchar(2000)
		
	SELECT	@config_bucket = substring(dbo.config.value_str, 1, 1),
			@config_month = CAST(substring(dbo.config.value_str, 2, 2) AS INT),
			@config_week = CAST(substring(dbo.config.value_str, 4, 2) AS INT),
			@config_day = CAST(substring(dbo.config.value_str, 6, 1) AS INT),
			@config_str = LEFT(value_str, 6)
		FROM dbo.config
		WHERE dbo.config.flag = 'EFORECAST_CONFIG'

	SELECT @partid = ISNULL((SELECT PRODUCTID FROM EFORECAST_PRODUCT WHERE PART_NO = @part_no), -1)
	IF @partid = -1
	BEGIN
		SELECT @year, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	--	RAISERROR 99999 'No history was found for this part.'
		RETURN
	END

	SELECT @locid = ISNULL((SELECT LOCATIONID FROM EFORECAST_LOCATION WHERE LOCATION = @location), -1)
	IF @locid = -1
	BEGIN
		SELECT @year, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	--	RAISERROR 99999 'No history was found for this Location.'
		RETURN
	END

	create table #retvals ( 
		[year] int not null,
		--promotion codes
		pc1 int not null default 0,
		pc2 int not null default 0,
		pc3 int not null default 0,
		pc4 int not null default 0,
		pc5 int not null default 0,
		pc6 int not null default 0,
		pc7 int not null default 0,
		pc8 int not null default 0,
		pc9 int not null default 0,
		pc10 int not null default 0,
		pc11 int not null default 0,
		pc12 int not null default 0,
		pc13 int null,
		pc14 int null,
		pc15 int null,
		--sales
		s1 decimal(20, 8) not null default 0,
		s2 decimal(20, 8) not null default 0,
		s3 decimal(20, 8) not null default 0,
		s4 decimal(20, 8) not null default 0,
		s5 decimal(20, 8) not null default 0,
		s6 decimal(20, 8) not null default 0,
		s7 decimal(20, 8) not null default 0,
		s8 decimal(20, 8) not null default 0,
		s9 decimal(20, 8) not null default 0,
		s10 decimal(20, 8) not null default 0,
		s11 decimal(20, 8) not null default 0,
		s12 decimal(20, 8) not null default 0,
		s13 decimal(20, 8) null,
		s14 decimal(20, 8) null,
		s15 decimal(20, 8) null,
		--returns
		r1 decimal(20, 8) not null default 0,
		r2 decimal(20, 8) not null default 0,
		r3 decimal(20, 8) not null default 0,
		r4 decimal(20, 8) not null default 0,
		r5 decimal(20, 8) not null default 0,
		r6 decimal(20, 8) not null default 0,
		r7 decimal(20, 8) not null default 0,
		r8 decimal(20, 8) not null default 0,
		r9 decimal(20, 8) not null default 0,
		r10 decimal(20, 8) not null default 0,
		r11 decimal(20, 8) not null default 0,
		r12 decimal(20, 8) not null default 0,
		r13 decimal(20, 8) null,
		r14 decimal(20, 8) null,
		r15 decimal(20, 8) null,
		--adjustments
		a1 decimal(20, 8) not null default 0,
		a2 decimal(20, 8) not null default 0,
		a3 decimal(20, 8) not null default 0,
		a4 decimal(20, 8) not null default 0,
		a5 decimal(20, 8) not null default 0,
		a6 decimal(20, 8) not null default 0,
		a7 decimal(20, 8) not null default 0,
		a8 decimal(20, 8) not null default 0,
		a9 decimal(20, 8) not null default 0,
		a10 decimal(20, 8) not null default 0,
		a11 decimal(20, 8) not null default 0,
		a12 decimal(20, 8) not null default 0,
		a13 decimal(20, 8) null,
		a14 decimal(20, 8) null,
		a15 decimal(20, 8) null)

	SELECT @min_year_quarter = YEAR_QUARTER
		FROM EFORECAST_TIME
		WHERE TIMEID = (SELECT MIN(TIMEID) FROM EFORECAST_SALESALL) -- WHERE LOCATIONID = @locid AND PRODUCTID = @partid)

--	SELECT @max_year_quarter = YEAR_QUARTER
--		FROM EFORECAST_TIME
--		WHERE TIMEID = (SELECT MAX(TIMEID) FROM EFORECAST_SALESALL) -- WHERE LOCATIONID = @locid AND PRODUCTID = @partid)

	SELECT @max_year_quarter = MAX(YEAR_QUARTER)
		FROM EFORECAST_TIME
		WHERE FIRST_DAY <= GETDATE()

	IF (@config_bucket = 'W') --we only want to look at this quarter in previous years
	BEGIN
		SELECT @min_year_quarter = ((@min_year_quarter / 10) * 10) + @quarter,
			@max_year_quarter = ((@max_year_quarter / 10) * 10) + @quarter 
	END


	SELECT @year_quarter = @min_year_quarter
	WHILE @year_quarter <= @max_year_quarter
	BEGIN
		SELECT @colstr = N'', @valstr = STR(@year_quarter), @count = 1
		DECLARE time_cursor cursor for
			select TIMEID FROM EFORECAST_TIME WHERE YEAR_QUARTER = 	@year_quarter

		OPEN time_cursor
		FETCH NEXT FROM time_cursor INTO @timeid
		WHILE @@FETCH_STATUS = 0
		BEGIN
			
			select @colstr = @colstr + ', pc' + LTRIM(STR(@count)) 
						+ ', s' + LTRIM(STR(@count)) 
						+ ', r' + LTRIM(STR(@count)) 
						+ ', a' + LTRIM(STR(@count)),
				@valstr = @valstr + ', ' + STR(ISNULL(MAX(PROMOID), 0))
						+ ', ' + STR(ISNULL(SUM(GROSS_SOLD_QTY), 0))
						+ ', ' + STR(ISNULL(SUM(RETURN_QTY), 0))
						+ ', ' + STR(ISNULL(SUM(ADJUSTMENT_QTY), 0))
				FROM EFORECAST_SALESALL 
				WHERE TIMEID = @timeid
				AND PRODUCTID = @partid
				AND LOCATIONID = @locid

			select @count = @count + 1
			FETCH NEXT FROM time_cursor INTO @timeid
		END 
		close time_cursor
		deallocate time_cursor
		select @sqlstr = N'INSERT INTO #retvals ( [year]' + @colstr
						+ N') VALUES (' + @valstr + N')'
		exec sp_executesql @statement = @sqlstr

		IF (@config_bucket = 'W') select @year_quarter = @year_quarter + 10
		ELSE SELECT @year_quarter = @year_quarter + 1
	END

	SELECT [year], pc1, pc2, pc3, pc4, pc5, pc6, pc7, pc8, pc9, pc10, pc11, pc12, pc13, pc14, pc15,
			s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12, s13, s14, s15,
			r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13, r14, r15,
			a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15
		FROM #retvals

return 0
GO
GRANT EXECUTE ON  [dbo].[fs_get_forecast_history] TO [public]
GO
