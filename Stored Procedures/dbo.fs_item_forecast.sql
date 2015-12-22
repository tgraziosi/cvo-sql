SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE PROCEDURE [dbo].[fs_item_forecast]
	(
	@sched_id	INT=NULL,
	@location	VARCHAR(10)=NULL,
	@part_no	VARCHAR(30),
	@beg_date	DATETIME,
	@end_date	DATETIME,
	@period		CHAR(1)
	)
WITH ENCRYPTION
AS
BEGIN




DECLARE	@nxt_date	DATETIME,
	@cus_quantity	FLOAT,
	@con_quantity	FLOAT,
	@for_quantity	FLOAT,
	@inv_quantity	FLOAT,
	@pur_quantity	FLOAT,
	@pro_quantity	FLOAT,
	@min_quantity	FLOAT,
	@ord_quantity	FLOAT
DECLARE	@datetime DATETIME


IF NOT EXISTS (SELECT * FROM dbo.sched_model WHERE sched_id = @sched_id)
	BEGIN
	RaisError 69010 'Schedule model does not exist.'
	RETURN
	END


CREATE TABLE #location
	(
	location	VARCHAR(10)
	)



IF @location IS NOT NULL
	INSERT	#location(location)
	VALUES	(@location)
ELSE
	INSERT	#location(location)
	SELECT	SL.location
	FROM	dbo.sched_location SL
	WHERE	SL.sched_id = @sched_id


IF @period = 'Y'
	
	SELECT	@beg_date = datename(year,@beg_date)+'-01-01'
ELSE IF @period = 'Q'
	
	SELECT	@beg_date = 	CASE datepart(quarter,@beg_date)
				WHEN 1 THEN datename(year,@beg_date)+'-01-01'
				WHEN 2 THEN datename(year,@beg_date)+'-04-01'
				WHEN 3 THEN datename(year,@beg_date)+'-07-01'
				WHEN 4 THEN datename(year,@beg_date)+'-10-01'
				END
ELSE IF @period = 'M'	
	
	SELECT	@beg_date = dateadd(day,1-datepart(day,@beg_date),@beg_date)
ELSE IF @period = 'W'
	
	SELECT	@beg_date = dateadd(day,1-datepart(weekday,@beg_date),@beg_date)
ELSE IF @period <> 'D' 
	BEGIN
	RaisError 69019 'Illegal period specified'
	RETURN
	END


CREATE TABLE #result
	(
	period_date		DATETIME,

	cus_quantity		FLOAT,	
	con_quantity		FLOAT,	
	for_quantity		FLOAT,	
	
	inv_quantity		FLOAT,	
	pur_quantity		FLOAT,	
	pro_quantity		FLOAT,	
	
	min_quantity		FLOAT,	
	ord_quantity		FLOAT	
	)


SELECT	@beg_date = datename(year,@beg_date)+'-'+datename(month,@beg_date)+'-'+datename(day,@beg_date)


SELECT	@inv_quantity = SUM(SI.uom_qty)
FROM	dbo.sched_item SI ,
	#location L
WHERE	SI.sched_id = @sched_id
AND	SI.source_flag = 'I'
AND	SI.part_no = @part_no
AND	SI.location = L.location

SELECT	@pro_quantity = SUM(SI.uom_qty)
FROM	dbo.sched_item SI ,
	#location L
WHERE	SI.sched_id = @sched_id
AND	SI.source_flag IN ('O','P','M')
AND	SI.part_no = @part_no
AND	SI.location = L.location
AND	SI.done_datetime < @beg_date

SELECT	@cus_quantity = SUM(SO.uom_qty)
FROM	dbo.sched_order SO,
	#location L
WHERE	SO.sched_id = @sched_id
AND	SO.part_no = @part_no
AND	SO.source_flag IN ('C','T')
AND	SO.location = L.location
AND	SO.done_datetime < @beg_date

SELECT	@con_quantity = SUM(SOI.uom_qty)
FROM	#location L,
	dbo.sched_item SI,
	dbo.sched_operation_item SOI,
	dbo.sched_operation SO,
	dbo.sched_process SP
WHERE	SI.sched_id = @sched_id
AND	SI.part_no = @part_no
AND	SI.location = L.location
AND	SOI.sched_item_id = SI.sched_item_id
AND	SO.done_datetime < @beg_date
AND	SO.sched_operation_id = SOI.sched_operation_id
AND	SP.sched_id = @sched_id
AND	SP.sched_process_id = SO.sched_process_id


SELECT	@inv_quantity = IsNull(@inv_quantity,0.0) + IsNull(@pro_quantity,0.0) - IsNull(@cus_quantity,0.0) - IsNull(@con_quantity,0.0)


SELECT	@min_quantity = SUM(I.min_stock),
	@ord_quantity = SUM(I.min_order)
FROM	dbo.inventory I,
	#location L
WHERE	I.part_no = @part_no
AND	I.location = L.location

SELECT	@min_quantity = IsNull(@min_quantity,0.0),
	@ord_quantity = IsNull(@ord_quantity,0.0)

WHILE	@beg_date < @end_date
	BEGIN
	
	IF @period = 'D'	SELECT	@nxt_date = dateadd(day,1,@beg_date)
	ELSE IF @period = 'W'	SELECT	@nxt_date = dateadd(week,1,@beg_date)
	ELSE IF @period = 'M'	SELECT	@nxt_date = dateadd(month,1,@beg_date)
	ELSE IF @period = 'Q'	SELECT	@nxt_date = dateadd(quarter,1,@beg_date)
	ELSE IF @period = 'Y'	SELECT	@nxt_date = dateadd(year,1,@beg_date)

	
	SELECT	@cus_quantity=SUM(SO.uom_qty)
	FROM	#location L,
		dbo.sched_order SO
	WHERE	SO.sched_id = @sched_id
	AND	SO.part_no = @part_no
	AND	SO.source_flag IN ('C','T')
	AND	SO.location = L.location
	AND	SO.done_datetime >= @beg_date
	AND	SO.done_datetime <  @nxt_date

	
	SELECT	@con_quantity = SUM(SOI.uom_qty)
	FROM	#location L,
		dbo.sched_item SI,
		dbo.sched_operation_item SOI,
		dbo.sched_operation SO,
		dbo.sched_process SP
	WHERE	SI.sched_id = @sched_id
	AND	SI.part_no = @part_no
	AND	SI.location = L.location
	AND	SOI.sched_item_id = SI.sched_item_id
	AND	SO.sched_operation_id = SOI.sched_operation_id
	AND	SO.done_datetime >= @beg_date
	AND	SO.done_datetime <  @nxt_date
	AND	SP.sched_id = @sched_id
	AND	SP.sched_process_id = SO.sched_process_id

	
	SELECT	@for_quantity = SUM(SO.uom_qty)
	FROM	dbo.sched_order SO,
		#location L
	WHERE	SO.sched_id = @sched_id
	AND	SO.part_no = @part_no
	AND	SO.source_flag = 'F'
	AND	SO.location = L.location
	AND	SO.done_datetime >= @beg_date
	AND	SO.done_datetime <  @nxt_date

	
	SELECT	@pur_quantity=SUM(SI.uom_qty)
	FROM	dbo.sched_item SI,
		#location L
	WHERE	SI.sched_id = @sched_id
	AND	SI.part_no = @part_no
	AND	SI.source_flag IN ('O','P')
	AND	SI.location = L.location
	AND	SI.done_datetime >= @beg_date
	AND	SI.done_datetime <  @nxt_date

	
	SELECT	@pro_quantity = SUM(SI.uom_qty)
	FROM	dbo.sched_item SI,
		#location L
	WHERE	SI.sched_id = @sched_id
	AND	SI.part_no = @part_no
	AND	SI.source_flag = 'M'
	AND	SI.location = L.location
	AND	SI.done_datetime >= @beg_date
	AND	SI.done_datetime <  @nxt_date

	
	SELECT	@cus_quantity=IsNull(@cus_quantity,0.0),
		@con_quantity=IsNull(@con_quantity,0.0),
		@for_quantity=IsNull(@for_quantity,0.0),
		@pur_quantity=IsNull(@pur_quantity,0.0),
		@pro_quantity=IsNull(@pro_quantity,0.0)

	
	INSERT	#result(period_date,cus_quantity,con_quantity,for_quantity,inv_quantity,pur_quantity,pro_quantity,min_quantity,ord_quantity)
	VALUES (@beg_date,@cus_quantity,@con_quantity,@for_quantity,@inv_quantity,@pur_quantity,@pro_quantity,@min_quantity,@ord_quantity)

	
	SELECT	@beg_date=@nxt_date,
		@inv_quantity = 0.0
	END


SELECT	period_date,
	cus_quantity,
	con_quantity,
	for_quantity,
	inv_quantity,
	pur_quantity,
	pro_quantity,
	min_quantity,
	ord_quantity
FROM	#result
ORDER BY period_date

RETURN
END
GO
GRANT EXECUTE ON  [dbo].[fs_item_forecast] TO [public]
GO
