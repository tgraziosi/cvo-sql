SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create proc [dbo].[fs_update_forecast_total]
		@year_quarter int, 
		@part_no varchar(30), 
		@location varchar(10),
		@bucket int, 
		@value decimal(20, 8),
		@online_call int = 1
as 
	DECLARE	@partid int,
		@locid int,
		@timeid int,
		@sessionid int

	SELECT @partid = ISNULL((SELECT PRODUCTID FROM EFORECAST_PRODUCT WHERE PART_NO = @part_no), -1)
	SELECT @locid = ISNULL((SELECT LOCATIONID FROM EFORECAST_LOCATION WHERE LOCATION = @location), -1)
	SELECT @sessionid = ISNULL((SELECT SESSIONID FROM EFORECAST_LOCATION WHERE LOCATION = @location), -1)
	SELECT @timeid = MIN(TIMEID) - 1 + @bucket FROM EFORECAST_TIME WHERE YEAR_QUARTER = @year_quarter

	IF EXISTS(SELECT 1 FROM EFORECAST_FORECAST WHERE TIMEID = @timeid AND LOCATIONID = @locid AND PRODUCTID = @partid AND SESSIONID = @sessionid)
		UPDATE EFORECAST_FORECAST SET ADJUSTMENT = @value WHERE SESSIONID = @sessionid AND TIMEID = @timeid AND LOCATIONID = @locid AND PRODUCTID = @partid
	ELSE
		INSERT INTO EFORECAST_FORECAST (SESSIONID, TIMEID, PRODUCTID, PROMOID, FORECAST, LOCATIONID, ADJUSTMENT) VALUES (@sessionid, @timeid, @partid, 0, 0, @locid, @value)

	if @online_call = 1
		select 1, ''
GO
GRANT EXECUTE ON  [dbo].[fs_update_forecast_total] TO [public]
GO
