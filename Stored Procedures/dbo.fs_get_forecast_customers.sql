SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[fs_get_forecast_customers]
	@part_no	varchar (30), 
	@location	varchar (20), 
	@year		int,
	@quarter 	int
AS
DECLARE @config_bucket varchar(1),
		@config_month varchar(2),
		@config_week varchar(2),
		@config_day varchar(1),
		@count int,
		@config_str varchar(6),
		@year_quarter int,
		@timeid int,
		@sqlstr varchar(1000),
		@partid int,
		@locid int,
		@cust_forecast decimal(20, 8),
		@calc_forecast real,
		@open_so_qty decimal(20, 8),
		@shp_so_qty decimal(20, 8),
		@return_qty decimal(20, 8),
		@first_day datetime,
		@last_day datetime,
		@cust_code varchar(8),
		@cust_name varchar(40),
		@adj_forecast decimal(20, 8),	
	@sessionid int

SELECT	@config_bucket = substring(dbo.config.value_str, 1, 1),
		@config_month = CAST(substring(dbo.config.value_str, 2, 2) AS INT),
		@config_week = CAST(substring(dbo.config.value_str, 4, 2) AS INT),
		@config_day = CAST(substring(dbo.config.value_str, 6, 1) AS INT),
		@config_str = LEFT(value_str, 6)
	FROM dbo.config (nolock) 
	WHERE dbo.config.flag = 'EFORECAST_CONFIG'

SELECT @partid = ISNULL((SELECT PRODUCTID FROM EFORECAST_PRODUCT WHERE PART_NO = @part_no), -1)
IF @partid = -1
BEGIN
	RAISERROR 99999 'No history was found for this part.'
	RETURN
END

SELECT @locid = ISNULL((SELECT LOCATIONID FROM EFORECAST_LOCATION WHERE LOCATION = @location), -1)
IF @locid = -1
BEGIN
	RAISERROR 99999 'No history was found for this Location.'
	RETURN
END

	SELECT @sessionid = SESSIONID FROM EFORECAST_LOCATION WHERE LOCATION = @location

 --for monthly, year_quarter is the year.  For weekly its the year with the quarter tagged on the end.
SELECT @year_quarter = CASE @config_bucket 
			WHEN 'W' THEN (@year * 10) + @quarter 
			ELSE @year END
	

create table #retvals (
	cust_code varchar(8),
	cust_name varchar(40),
	rownum int not null,
	bkt1 decimal(20,8) default(0),
	bkt2 decimal(20,8) default(0),
	bkt3 decimal(20,8) default(0),
	bkt4 decimal(20,8) default(0),
	bkt5 decimal(20,8) default(0),
	bkt6 decimal(20,8) default(0),
	bkt7 decimal(20,8) default(0),
	bkt8 decimal(20,8) default(0),
	bkt9 decimal(20,8) default(0),
	bkt10 decimal(20,8) default(0),
	bkt11 decimal(20,8) default(0),
	bkt12 decimal(20,8) default(0),
	bkt13 decimal(20,8) null,
	bkt14 decimal(20,8) null,
	bkt15 decimal(20,8) null)
	
declare custcursor cursor for 
	select customer_code, customer_name
	from adm_cust_all
	where customer_code in (select distinct CUST_CODE from EFORECAST_CUSTOMER_FORECAST WHERE LOCATIONID = @locid AND PRODUCTID = @partid)

OPEN custcursor
fetch next from custcursor into @cust_code, @cust_name
while @@FETCH_STATUS = 0
begin
	--This populates the temp-table with default values
	SELECT @count = 0
	WHILE (@count < 6)
	BEGIN
		INSERT INTO #retvals (cust_code, cust_name, rownum) values (@cust_code, @cust_name, @count)
		SELECT @count = @count + 1
	END

	SELECT @count = 1
 
	-- Iterate through the columns (which correspond to time buckets) and update each row.
	-- since we are doing the column-name dynamically, we construct the SQL string on the fly.
	DECLARE time_cursor CURSOR FOR 
		SELECT a.TIMEID, a.FIRST_DAY, 
		       LAST_DAY = (SELECT DATEADD(dd, -1, FIRST_DAY) FROM EFORECAST_TIME  (nolock) WHERE TIMEID = a.TIMEID + 1)
		  FROM EFORECAST_TIME a(NOLOCK)
		 WHERE YEAR_QUARTER = @year_quarter
	OPEN time_cursor
	FETCH NEXT FROM time_cursor INTO @timeid, @first_day, @last_day
	WHILE @@FETCH_STATUS = 0
	BEGIN

		--row 0 forecast
		select @cust_forecast = ISNULL((SELECT QTY
			from EFORECAST_CUSTOMER_FORECAST 
			WHERE TIMEID = @timeid
			AND LOCATIONID = @locid 
			AND PRODUCTID = @partid
			AND CUST_CODE = @cust_code), 0)

		--row 1 Open
		SELECT @open_so_qty = 
			(SELECT ISNULL(SUM(ordered * conv_factor), 0) 
			FROM orders_all (nolock) , ord_list (nolock)
			where orders_all.order_no = ord_list.order_no
			 and orders_all.ext = ord_list.order_ext 
			 and ord_list.part_no = @part_no
			 and ord_list.location = @location
			 and ord_list.status < 'T' and orders_all.type = 'I'
			 and req_ship_date BETWEEN @first_day and @last_day
			 and orders_all.cust_code = @cust_code)
			 +
			(SELECT ISNULL(SUM(ordered * conv_factor), 0) 
			FROM orders_all (nolock) , ord_list_kit (nolock)
			where orders_all.order_no = ord_list_kit.order_no
			 and orders_all.ext = ord_list_kit.order_ext 
			 and ord_list_kit.part_no = @part_no
			 and ord_list_kit.location = @location
			 and ord_list_kit.status < 'T' and orders_all.type = 'I'
			 and req_ship_date BETWEEN @first_day and @last_day
			 and orders_all.cust_code = @cust_code)
		 
		--row 2	Shipped
		SELECT @shp_so_qty = 
			(SELECT ISNULL(SUM(shipped * conv_factor), 0)
			from orders_all (nolock) , ord_list (nolock)
			where orders_all.order_no = ord_list.order_no 
			and orders_all.ext = ord_list.order_ext 
			and ord_list.part_no = @part_no
			and ord_list.location = @location
			and ord_list.status = 'T'
			and date_shipped BETWEEN @first_day and @last_day
			and orders_all.cust_code = @cust_code)
			+
			(SELECT ISNULL(SUM(shipped * conv_factor), 0)
			from orders_all (nolock) , ord_list_kit (nolock)
			where orders_all.order_no = ord_list_kit.order_no 
			and orders_all.ext = ord_list_kit.order_ext 
			and ord_list_kit.part_no = @part_no
			and ord_list_kit.location = @location
			and ord_list_kit.status = 'T'
			and date_shipped BETWEEN @first_day and @last_day
			and orders_all.cust_code = @cust_code)
			
		--row 3	Returns
		SELECT @return_qty = 
			(SELECT ISNULL(SUM(cr_shipped * conv_factor), 0)
			from orders_all o (nolock) , ord_list (nolock)
			where o.order_no = ord_list.order_no 
			and o.ext = ord_list.order_ext 
			and ord_list.part_no = @part_no
			and ord_list.location = @location
			and ord_list.status = 'T'
			and date_shipped BETWEEN @first_day and @last_day
			and o.cust_code = @cust_code)
			+
			(SELECT ISNULL(SUM(cr_shipped * conv_factor), 0)
			from orders_all o (nolock) , ord_list_kit (nolock)
			where o.order_no = ord_list_kit.order_no 
			and o.ext = ord_list_kit.order_ext 
			and ord_list_kit.part_no = @part_no
			and ord_list_kit.location = @location
			and ord_list_kit.status = 'T'
			and date_shipped BETWEEN @first_day and @last_day
			and o.cust_code = @cust_code)
				
		--row 4 Total  row 1 + row 2 - row 3
		--row 5 Actual Vs. Forecast  row 0 - row 4
		SELECT @sqlstr = ' UPDATE #retvals SET bkt' + LTRIM(STR(@count)) + '= CASE rownum '
			+ ' WHEN 0 THEN ' + STR(@cust_forecast)
			+ ' WHEN 1 THEN ' + STR(@open_so_qty)
			+ ' WHEN 2 THEN ' + STR(@shp_so_qty)
			+ ' WHEN 3 THEN ' + STR(@return_qty)
			+ ' WHEN 4 THEN ' + STR(@open_so_qty + @shp_so_qty - @return_qty)
			+ ' WHEN 5 THEN ' + STR(@cust_forecast - (@open_so_qty + @shp_so_qty - @return_qty))
			+ ' END WHERE cust_code = ''' + @cust_code + ''''
		EXEC (@sqlstr)

	 	FETCH NEXT FROM time_cursor INTO @timeid, @first_day, @last_day
		SELECT @count = @count + 1
	END
	CLOSE time_cursor
	DEALLOCATE time_cursor

	fetch next from custcursor into @cust_code, @cust_name
end
CLOSE custcursor
DEALLOCATE custcursor

-- now for the default row. 
SELECT @count = 0
WHILE (@count < 6)
BEGIN
	INSERT INTO #retvals (cust_code, cust_name, rownum) values ('', 'All Other Customers', @count)
	SELECT @count = @count + 1
END

SELECT @count = 1

-- Iterate through the columns (which correspond to time buckets) and update each row.
-- since we are doing the column-name dynamically, we construct the SQL string on the fly.
DECLARE time_cursor CURSOR FOR 
	SELECT a.TIMEID, a.FIRST_DAY, 
	       LAST_DAY = (SELECT DATEADD(dd, -1, FIRST_DAY) FROM EFORECAST_TIME  (nolock) WHERE TIMEID = a.TIMEID + 1)
	  FROM EFORECAST_TIME a(NOLOCK)
	 WHERE YEAR_QUARTER = @year_quarter
OPEN time_cursor
FETCH NEXT FROM time_cursor INTO @timeid, @first_day, @last_day
WHILE @@FETCH_STATUS = 0
BEGIN

	--row 0 forecast
	select @calc_forecast = ISNULL((SELECT SUM(FORECAST + ADJUSTMENT)
		from EFORECAST_FORECAST 
		WHERE SESSIONID = @sessionid
		AND TIMEID = @timeid
		AND LOCATIONID = @locid 
		AND PRODUCTID = @partid), 0)

	--row 1 Open
	SELECT @open_so_qty = 
		(SELECT ISNULL(SUM(ordered * conv_factor), 0) 
		FROM orders_all o (nolock) , ord_list (nolock)
		where o.order_no = ord_list.order_no
		 and o.ext = ord_list.order_ext 
		 and ord_list.location = @location
		 and ord_list.part_no = @part_no
		 and ord_list.status < 'T' and o.type = 'I'
		 and req_ship_date BETWEEN @first_day and @last_day
		 and o.cust_code NOT IN (SELECT DISTINCT CUST_CODE FROM EFORECAST_CUSTOMER_FORECAST WHERE LOCATIONID = @locid AND PRODUCTID = @partid))
		 +
		(SELECT ISNULL(SUM(ordered * conv_factor), 0) 
		FROM orders_all o (nolock) , ord_list_kit (nolock)
		where o.order_no = ord_list_kit.order_no
		 and o.ext = ord_list_kit.order_ext 
		 and ord_list_kit.location = @location
		 and ord_list_kit.part_no = @part_no
		 and ord_list_kit.status < 'T' and o.type = 'I'
		 and req_ship_date BETWEEN @first_day and @last_day
		 and o.cust_code NOT IN (SELECT DISTINCT CUST_CODE FROM EFORECAST_CUSTOMER_FORECAST WHERE LOCATIONID = @locid AND PRODUCTID = @partid))
		 
	 
	--row 2	Shipped
	SELECT @shp_so_qty = 
		(SELECT ISNULL(SUM(shipped * conv_factor), 0)
		from orders_all o (nolock) , ord_list (nolock)
		where o.order_no = ord_list.order_no 
		and o.ext = ord_list.order_ext 
		and ord_list.location = @location
		and ord_list.part_no = @part_no
		and ord_list.status = 'T'
		and date_shipped BETWEEN @first_day and @last_day
		and o.cust_code NOT IN (SELECT DISTINCT CUST_CODE FROM EFORECAST_CUSTOMER_FORECAST WHERE LOCATIONID = @locid AND PRODUCTID = @partid))
		+
		(SELECT ISNULL(SUM(shipped * conv_factor), 0)
		from orders_all o (nolock) , ord_list_kit (nolock)
		where o.order_no = ord_list_kit.order_no 
		and o.ext = ord_list_kit.order_ext 
		and ord_list_kit.location = @location
		and ord_list_kit.part_no = @part_no
		and ord_list_kit.status = 'T'
		and date_shipped BETWEEN @first_day and @last_day
		and o.cust_code NOT IN (SELECT DISTINCT CUST_CODE FROM EFORECAST_CUSTOMER_FORECAST WHERE LOCATIONID = @locid AND PRODUCTID = @partid))
		
	--row 3	Returns
	SELECT @return_qty = 
		(SELECT ISNULL(SUM(cr_shipped * conv_factor), 0)
		from orders_all o (nolock) , ord_list (nolock)
		where o.order_no = ord_list.order_no 
		and o.ext = ord_list.order_ext 
		and ord_list.part_no = @part_no
		and ord_list.location = @location
		and ord_list.status = 'T'
		and date_shipped BETWEEN @first_day and @last_day
		and o.cust_code NOT IN (SELECT DISTINCT CUST_CODE FROM EFORECAST_CUSTOMER_FORECAST WHERE LOCATIONID = @locid AND PRODUCTID = @partid))
		+
		(SELECT ISNULL(SUM(cr_shipped * conv_factor), 0)
		from orders_all o (nolock) , ord_list_kit (nolock)
		where o.order_no = ord_list_kit.order_no 
		and o.ext = ord_list_kit.order_ext 
		and ord_list_kit.part_no = @part_no
		and ord_list_kit.location = @location
		and ord_list_kit.status = 'T'
		and date_shipped BETWEEN @first_day and @last_day
		and o.cust_code NOT IN (SELECT DISTINCT CUST_CODE FROM EFORECAST_CUSTOMER_FORECAST WHERE LOCATIONID = @locid AND PRODUCTID = @partid))
			
	--row 4 Total  row 1 + row 2 - row 3
	--row 5 Actual Vs. Forecast  row 0 - row 4
	SELECT @sqlstr = ' UPDATE #retvals SET bkt' + LTRIM(STR(@count)) + '= CASE rownum '
		+ ' WHEN 0 THEN ' + STR(@calc_forecast)
		+ ' WHEN 1 THEN ' + STR(@open_so_qty)
		+ ' WHEN 2 THEN ' + STR(@shp_so_qty)
		+ ' WHEN 3 THEN ' + STR(@return_qty)
		+ ' WHEN 4 THEN ' + STR(@open_so_qty + @shp_so_qty - @return_qty)
		+ ' WHEN 5 THEN ' + STR(@calc_forecast - (@open_so_qty + @shp_so_qty - @return_qty))
		+ ' END WHERE cust_code = '''''
	EXEC (@sqlstr)

 	FETCH NEXT FROM time_cursor INTO @timeid, @first_day, @last_day
	SELECT @count = @count + 1
END
CLOSE time_cursor
DEALLOCATE time_cursor

SELECT	cust_code, rownum, cust_name, bkt1, bkt2, bkt3, bkt4, bkt5, bkt6, 
		bkt7, bkt8, bkt9, bkt10, bkt11, bkt12, bkt13, bkt14, bkt15 
	FROM #retvals order by cust_code, rownum
drop table #retvals

return 0
GO
GRANT EXECUTE ON  [dbo].[fs_get_forecast_customers] TO [public]
GO
