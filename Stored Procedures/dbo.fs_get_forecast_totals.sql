SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[fs_get_forecast_totals]
	@part_no	varchar (30), 
	@location	varchar (20), 
	@year		int,
	@quarter	int
AS

DECLARE @config_bucket varchar(1),
		@config_month varchar(2),
		@config_week varchar(2),
		@config_day varchar(1),
		@count int,
		@config_str varchar(6),
		@year_quarter int,
		@timeid int,
		@sqlstr nvarchar(1000),
		@partid int,
		@locid int,
		@cust_forecast decimal(20, 8),
		@calc_forecast real,
		@adj_forecast decimal(20, 8),
		@po_qty decimal(20,8),
		@on_hand_qty decimal(20, 8),
		@open_so_qty decimal(20, 8),
		@shp_so_qty decimal(20, 8),
		@roll_forward decimal(20, 8),
		@lost_sales_qty decimal(20, 8),
		@total_sales_qty decimal(20, 8),
		@first_day datetime,
		@last_day datetime,
		@sessionid int
		

	SELECT	@config_bucket = substring(dbo.config.value_str, 1, 1),
			@config_month = CAST(substring(dbo.config.value_str, 2, 2) AS INT),
			@config_week = CAST(substring(dbo.config.value_str, 4, 2) AS INT),
			@config_day = CAST(substring(dbo.config.value_str, 6, 1) AS INT),
			@config_str = LEFT(value_str, 6)
		FROM dbo.config (nolock) 
		WHERE dbo.config.flag = 'EFORECAST_CONFIG'

	SELECT @first_day = GETDATE()

	SELECT @partid = ISNULL((SELECT PRODUCTID FROM EFORECAST_PRODUCT WHERE PART_NO = @part_no), -1)
	IF @partid = -1
	BEGIN
		--RAISERROR 99999 'No history was found for this part.'
		-- SCR 33096 - 06/29/04 - CNASH
		-- If there is no history for this part, we record a dummy sale
		EXEC fs_eforecast_record_sale @part_no, @location, @first_day, 0, 0, 0
		SELECT @partid = PRODUCTID FROM EFORECAST_PRODUCT WHERE PART_NO = @part_no
	END

	SELECT @locid = ISNULL((SELECT LOCATIONID FROM EFORECAST_LOCATION WHERE LOCATION = @location), -1)
	IF @locid = -1
	BEGIN
		-- RAISERROR 99999 'No history was found for this Location.'
		-- SCR 33096 - 06/29/04 - CNASH
		-- If there is no history for this location, we record a dummy sale
		EXEC fs_eforecast_record_sale @part_no, @location, @first_day, 0, 0, 0
		SELECT @locid = LOCATIONID FROM EFORECAST_LOCATION WHERE LOCATION = @location
	END
	
	SELECT @sessionid = SESSIONID FROM EFORECAST_LOCATION WHERE LOCATION = @location

	create table #retvals ( 
		rownum int NOT NULL,
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
		
	--This populates the temptable with default values
	SELECT @count = 0
	WHILE (@count < 12)
	BEGIN
		INSERT INTO #retvals (rownum) values (@count)
		SELECT @count = @count + 1
	END

	--Set up some variables.  
	SELECT @count = 1, 
		@roll_forward = 0, 
		--for monthly, year_quarter is the year.  For weekly its the year with the quarter tagged on the end.
		@year_quarter = CASE @config_bucket 
					WHEN 'W' THEN (@year * 10) + @quarter 
					ELSE @year END
	
	-- Iterate through the columns (which correspond to time buckets) and update each row.
	-- since we are doing the column-name dynamically, we construct the SQL string on the fly.
	DECLARE time_cursor CURSOR FOR SELECT TIMEID, FIRST_DAY FROM EFORECAST_TIME  (nolock) WHERE YEAR_QUARTER = @year_quarter
	OPEN time_cursor
	FETCH NEXT FROM time_cursor INTO @timeid, @first_day
	WHILE @@FETCH_STATUS = 0
	BEGIN
		--get the last day of this period
		SELECT @last_day = DATEADD(dd, -1, FIRST_DAY) FROM EFORECAST_TIME  (nolock) WHERE TIMEID = @timeid + 1
		
		select @last_day = DateAdd(hh, 23, @last_day)	-- mls 4/10/06 SCR 36434
		select @last_day = DateAdd(mi, 59, @last_day)
		select @last_day = DateAdd(ss, 59, @last_day)

		--row 0 Get customer forecast
		SELECT @cust_forecast = ISNULL(SUM(QTY), 0) FROM EFORECAST_CUSTOMER_FORECAST (nolock)  WHERE PRODUCTID = @partid AND LOCATIONID = @locid AND TIMEID = @timeid
		--row 1 Get Calculated Forecast
		--row 2 Get Adjustment to Forecast
		SELECT @calc_forecast = ISNULL(SUM(FORECAST), 0), @adj_forecast = ISNULL(SUM(ADJUSTMENT), 0) FROM EFORECAST_FORECAST (nolock)  WHERE  SESSIONID = @sessionid AND PRODUCTID = @partid AND LOCATIONID = @locid AND TIMEID = @timeid
				
		--row 3 Show Sum of the last three values
		
		--row 4 Get Open POs
		SELECT @po_qty = ISNULL(SUM(quantity-received * conv_factor), 0) 
			FROM releases  (nolock) 
			WHERE part_no=@part_no 
			AND location = @location
			AND status = 'O'
			AND due_date BETWEEN @first_day AND @last_day
			
		--row 5 Get On Hand Qty
		IF (GETDATE() between @first_day and @last_day)
			SELECT @on_hand_qty = in_stock + @roll_forward FROM inventory (nolock)  WHERE part_no = @part_no and location = @location
		ELSE
			SELECT @on_hand_qty = @roll_forward
		
		--row 6 Total inventory
		
		--row 7 Open Sales
		SELECT @open_so_qty = 
			(SELECT ISNULL(SUM(ordered * conv_factor), 0) 
			FROM orders_all o (nolock) , ord_list (nolock)
			where o.order_no = ord_list.order_no
			 and o.ext = ord_list.order_ext 
			 and ord_list.part_no = @part_no
			 and ord_list.location = @location
			 and ord_list.status < 'T' and o.type = 'I'
			 and req_ship_date BETWEEN @first_day and @last_day)
			 +
			(SELECT ISNULL(SUM(ordered * conv_factor), 0) 
			FROM orders_all o (nolock) , ord_list_kit (nolock)
			where o.order_no = ord_list_kit.order_no
			 and o.ext = ord_list_kit.order_ext 
			 and ord_list_kit.part_no = @part_no
			 and ord_list_kit.location = @location
			 and ord_list_kit.status < 'T' and o.type = 'I'
			 and req_ship_date BETWEEN @first_day and @last_day)
			 
		--row 8 Shipped Sales
		SELECT @shp_so_qty = 
			(SELECT ISNULL(SUM(shipped * conv_factor), 0)
			from orders_all o (nolock) , ord_list (nolock)
			where o.order_no = ord_list.order_no 
			and o.ext = ord_list.order_ext 
			and ord_list.part_no = @part_no
			and ord_list.location = @location
			and ord_list.status = 'T'
			and date_shipped BETWEEN @first_day and @last_day)
			+
			(SELECT ISNULL(SUM(shipped * conv_factor), 0)
			from orders_all o (nolock) , ord_list_kit (nolock)
			where o.order_no = ord_list_kit.order_no 
			and o.ext = ord_list_kit.order_ext 
			and ord_list_kit.part_no = @part_no
			and ord_list_kit.location = @location
			and ord_list_kit.status = 'T'
			and date_shipped BETWEEN @first_day and @last_day)

		--row 9 Total sales
		
		--row 10 Lost Sales
		SELECT @lost_sales_qty = ISNULL(SUM(qty * conv_factor), 0)
			FROM lost_sales
			WHERE part_no = @part_no
			AND location = @location
			AND date_entered BETWEEN @first_day AND @last_day
		
		--row 11 Roll forward (inventory - sales)
		select @roll_forward = @on_hand_qty + @po_qty - @open_so_qty
		
		IF EXISTS (SELECT 1 FROM config WHERE flag = 'INV_LOSTSALES_HIST' AND value_str = 'YES')
			SELECT @total_sales_qty = @open_so_qty + @shp_so_qty + @lost_sales_qty
		ELSE
			SELECT @total_sales_qty = @open_so_qty + @shp_so_qty
		
		SELECT @sqlstr = N' UPDATE #retvals SET bkt' + LTRIM(STR(@count)) + '= CASE rownum WHEN 0 THEN ' + STR(@cust_forecast)
			+ ' WHEN 1 THEN ' + STR(@calc_forecast)
			+ ' WHEN 2 THEN ' + STR(@adj_forecast)
			+ ' WHEN 3 THEN ' + STR(@cust_forecast + @calc_forecast + @adj_forecast)
			+ ' WHEN 4 THEN ' + STR(@po_qty)
			+ ' WHEN 5 THEN ' + STR(@on_hand_qty)
			+ ' WHEN 6 THEN ' + STR(@po_qty + @on_hand_qty)
			+ ' WHEN 7 THEN ' + STR(@open_so_qty)
			+ ' WHEN 8 THEN ' + STR(@shp_so_qty)
			+ ' WHEN 9 THEN ' + STR(@lost_sales_qty)
			+ ' WHEN 10 THEN ' + STR(@total_sales_qty)
			+ ' WHEN 11 THEN ' + STR(@roll_forward) + ' END'

		EXEC sp_executesql @statement=@sqlstr

	 	FETCH NEXT FROM time_cursor INTO @timeid, @first_day
		SELECT @count = @count + 1
	END
	CLOSE time_cursor
	DEALLOCATE time_cursor

	SELECT	rownum, bkt1, bkt2, bkt3, bkt4, bkt5, bkt6, 
			bkt7, bkt8, bkt9, bkt10, bkt11, bkt12, bkt13, bkt14, bkt15 
		FROM #retvals order by rownum
return 0
GO
GRANT EXECUTE ON  [dbo].[fs_get_forecast_totals] TO [public]
GO
