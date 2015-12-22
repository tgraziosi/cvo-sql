SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create proc [dbo].[fs_eforecast_record_sale]
	@part_no VARCHAR(30),
	@location VARCHAR(10),
	@record_date datetime,
	@gross_sold_qty DECIMAL(20, 8),
	@return_qty DECIMAL(20, 8),
	@adjustment_qty DECIMAL(20, 8)
as
BEGIN
	DECLARE @timeid int,
		@locationid int,
		@productid int,
		@units DECIMAL(20, 8),
		@tot_units real,
		@tot_gross_sold_qty DECIMAL(20, 8),
		@tot_return_qty DECIMAL(20, 8),
		@tot_adjustment_qty DECIMAL(20, 8),
		@promoid int,
		@CROSS_REF_PART_NO varchar(30),
		@CROSS_REF_PRODUCTID int
		
	--Get the timeid
	SELECT @timeid = MAX(TIMEID) FROM EFORECAST_TIME WHERE FIRST_DAY <= @record_date
	
	-- check if the location exists in EFORECAST_STORE table
	select @locationid = isnull((select LOCATIONID 
		from EFORECAST_LOCATION where LOCATION = @location), NULL)

	if @locationid is NULL
	begin
		select @locationid = isnull(MAX(LOCATIONID), 0) + 1 FROM EFORECAST_LOCATION
		
		INSERT INTO EFORECAST_LOCATION (LOCATIONID, LOCATION, LOCATION_NAME) 
			SELECT @locationid, location, [name] 
				FROM locations_all
				WHERE location = @location
				
		if @@error <> 0 
		begin
			rollback tran
			raiserror 91353 'Error inserting a record in EFORECAST_LOCATION'
		end
		
		select @locationid = LOCATIONID 
			from EFORECAST_LOCATION where LOCATION = @location
	end

	-- check if the part is not in the PRODUCT table
	select @productid = isnull( (SELECT min(PRODUCTID )
							from EFORECAST_PRODUCT 
							where PART = @part_no), NULL)
	
	if @productid is null
	begin
		insert EFORECAST_PRODUCT ( PART , PART_NO , FORECAST_FLAG ) 
			select @part_no , @part_no , 0
			
		if @@error <> 0 
		begin
			rollback tran
			raiserror 91353 'Error inserting a record in EFORECAST_PRODUCT'
		end
		
		select @productid = PRODUCTID 
			from EFORECAST_PRODUCT 
			where PART = @part_no 
	end 

	--"units" column is the total
	SELECT @units = @gross_sold_qty - @return_qty + @adjustment_qty

	IF EXISTS (SELECT 1 FROM EFORECAST_SALESALL WHERE TIMEID = @timeid AND PRODUCTID = @productid AND LOCATIONID = @locationid)
	BEGIN
		UPDATE EFORECAST_SALESALL 
		SET UNITS = UNITS + @units,
			GROSS_SOLD_QTY = GROSS_SOLD_QTY + @gross_sold_qty,
			RETURN_QTY = RETURN_QTY + @return_qty,
			ADJUSTMENT_QTY = ADJUSTMENT_QTY + @adjustment_qty
			WHERE TIMEID = @timeid 
			AND PRODUCTID = @productid 
			AND LOCATIONID = @locationid 
	END
	ELSE 
	BEGIN
		INSERT INTO EFORECAST_SALESALL 
			(TIMEID, PRODUCTID, LOCATIONID, PROMOID, UNITS, GROSS_SOLD_QTY, RETURN_QTY, ADJUSTMENT_QTY)
		 VALUES
		 	(@timeid, @productid, @locationid, 0, @units, @gross_sold_qty, @return_qty, @adjustment_qty)
	END


	-- if the current part_no was cross-referenced to another part we need to update ADJUSTMENT_QTY column
	-- for the new part
	select @CROSS_REF_PART_NO = CROSS_REF_PART_NO
		from EFORECAST_PRODUCT
		where PRODUCTID = @productid 
		and FORECAST_FLAG = 1	-- mls 4/20/01 SCR 26758
	
	select @CROSS_REF_PRODUCTID = isnull (( select PRODUCTID  
		from EFORECAST_PRODUCT 
		where PART = @CROSS_REF_PART_NO), 0)

	if @CROSS_REF_PRODUCTID > 0 AND @units <> 0
	BEGIN
		IF EXISTS (SELECT 1 FROM EFORECAST_SALESALL WHERE TIMEID = @timeid AND PRODUCTID = @CROSS_REF_PRODUCTID AND LOCATIONID = @locationid)
		BEGIN
			UPDATE EFORECAST_SALESALL 
				SET UNITS = UNITS + @units,
				ADJUSTMENT_QTY = ADJUSTMENT_QTY + @units
				WHERE TIMEID = @timeid 
				AND PRODUCTID = @CROSS_REF_PRODUCTID 
				AND LOCATIONID = @locationid 
		END
		ELSE 
		BEGIN
			INSERT INTO EFORECAST_SALESALL 
				(TIMEID, PRODUCTID, LOCATIONID, PROMOID, UNITS, GROSS_SOLD_QTY, RETURN_QTY, ADJUSTMENT_QTY)
			 VALUES
			 	(@timeid, @CROSS_REF_PRODUCTID, @locationid, 0, @units, 0, 0, @units)
		END
	END
END
GO
GRANT EXECUTE ON  [dbo].[fs_eforecast_record_sale] TO [public]
GO
