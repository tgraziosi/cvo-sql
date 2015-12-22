SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE PROCEDURE [dbo].[fs_mrp_report]
	(
	@sched_id	varchar(50)=NULL,
	@location	VARCHAR(10)=NULL,
	@part_no	VARCHAR(30),
	@beg_date	DATETIME,
	@end_date	DATETIME,
	@period		CHAR(1)
	)
AS
BEGIN

/* This procedure generates MRP information based on the criteria       */
/* passed.  This is a demonstration procedure, not meant for production.*/
/* 03/16/01 Greg H removed a statememnt  SET ANSI_NULLS  ON that prevented AM(Galia) from running 
** 				SCR 99999
*/
declare @x1 int, @xm int
select @xm = datalength(@sched_id)
select @x1 = 1
while @x1 <= @xm
begin
  if substring(@sched_id,@x1,1) not between '0' and '9'
    break
  select @x1 = @x1 + 1
end

if @x1 < @xm
begin
  IF NOT EXISTS (SELECT * FROM dbo.sched_model WHERE sched_name = @sched_id)
	BEGIN
	exec adm_raiserror 69010, 'Schedule model does not exist.'
	RETURN
	END
  select @sched_id = sched_id from sched_model where sched_name = @sched_id
end

DECLARE	@nxt_date	DATETIME,
	@cus_quantity	FLOAT,
	@con_quantity	FLOAT,
	@for_quantity	FLOAT,
	@inv_quantity	FLOAT,
	@pur_quantity	FLOAT,
	@pro_quantity	FLOAT,
	@min_quantity	FLOAT,
	@ord_quantity	FLOAT
DECLARE	@datetime DATETIME,
        @forecast_max_datetime DATETIME

/* Check to make sure model exists */
IF NOT EXISTS (SELECT * FROM dbo.sched_model WHERE sched_id = @sched_id)
	BEGIN
	exec adm_raiserror 69010, 'Schedule model does not exist.'
	RETURN
	END

/* Create table of locations */
CREATE TABLE #location
	(
	location	VARCHAR(10)
	)

/* If a location was specified insert it, */
/* otherwise use all locations in this model */
IF @location IS NOT NULL
	INSERT	#location(location)
	VALUES	(@location)
ELSE
	INSERT	#location(location)
	SELECT	SL.location
	FROM	dbo.sched_location SL
	WHERE	SL.sched_id = @sched_id

/* Determine first day of period */
IF @period = 'Y'
	/* First day of year */
	SELECT	@beg_date = datename(year,@beg_date)+'-01-01'
ELSE IF @period = 'Q'
	/* First day of quarter */
	SELECT	@beg_date = 	CASE datepart(quarter,@beg_date)
				WHEN 1 THEN datename(year,@beg_date)+'-01-01'
				WHEN 2 THEN datename(year,@beg_date)+'-04-01'
				WHEN 3 THEN datename(year,@beg_date)+'-07-01'
				WHEN 4 THEN datename(year,@beg_date)+'-10-01'
				END
ELSE IF @period = 'M'	
	/* First day of month */
	SELECT	@beg_date = dateadd(day,1-datepart(day,@beg_date),@beg_date)
ELSE IF @period = 'W'
	/* First day of week */
	SELECT	@beg_date = dateadd(day,1-datepart(weekday,@beg_date),@beg_date)
ELSE IF @period <> 'D' /* If it is not to the day, then it's and error */
	BEGIN
	exec adm_raiserror 69019, 'Illegal period specified'
	RETURN
	END

/* Create table to report differences */
CREATE TABLE #result
	(
        report_beg_balance      FLOAT, 
	period_date_beg		DATETIME,
        period_date_end         DATETIME,
        report_line_type        CHAR(1),  -- 'F' = Forecast, 'C' = Customer order, 'P' = Planned purchase, "O" = on-order purchase, "R" = Released Purchase (purchase requisition)
        report_line_cust_ord_id INT NULL,      -- The numeric ID of the customer order or the PO
        report_line_po_id       CHAR(16) NULL,	-- mls 6/17/04 SCR 33002 - incr size to 16
        report_line_quantity    FLOAT,
        report_line_date        DATETIME
	
	--cus_quantity		FLOAT,	/* Actual customer demand */--
--	con_quantity		FLOAT,	/* Production consumption demand */
	--for_quantity		FLOAT,	/* Forecasted demand */
	
	--inv_quantity		FLOAT,	/* Inventory stock */
	--pur_quantity		FLOAT,	/* Purchase stock */
	--pro_quantity		FLOAT,	/* Production stock */
	
	--min_quantity		FLOAT,	/* Minimum stocking level */
	--ord_quantity		FLOAT	/* Minimum order quantity level */
	)

/* Determine start of day */
SELECT	@beg_date = datename(year,@beg_date)+'-'+datename(month,@beg_date)+'-'+datename(day,@beg_date)

/* Determine initial inventory */
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
AND	SO.source_flag = 'C'
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

/* Totalling in's and out's */
SELECT	@inv_quantity = IsNull(@inv_quantity,0.0) + IsNull(@pro_quantity,0.0) - IsNull(@cus_quantity,0.0) - IsNull(@con_quantity,0.0)

-- @@inv_quantity is the starting balance projected into the future to reflect the starting date.

/* Get minimum stocking and reorder levels
SELECT	@min_quantity = SUM(I.min_stock),
	@ord_quantity = SUM(I.min_order)
FROM	dbo.inventory I,
	#location L
WHERE	I.part_no = @part_no
AND	I.location = L.location

SELECT	@min_quantity = IsNull(@min_quantity,0.0),
	@ord_quantity = IsNull(@ord_quantity,0.0)*/

WHILE	@beg_date < @end_date
	BEGIN
	/* Determine next period start */
	IF @period = 'D'	SELECT	@nxt_date = dateadd(day,1,@beg_date)
	ELSE IF @period = 'W'	SELECT	@nxt_date = dateadd(week,1,@beg_date)
	ELSE IF @period = 'M'	SELECT	@nxt_date = dateadd(month,1,@beg_date)
	ELSE IF @period = 'Q'	SELECT	@nxt_date = dateadd(quarter,1,@beg_date)
	ELSE IF @period = 'Y'	SELECT	@nxt_date = dateadd(year,1,@beg_date)

	/* Get the forecasted demand total */
	SELECT	@for_quantity = SUM(SO.uom_qty)
	FROM	dbo.sched_order SO,
		#location L
	WHERE	SO.sched_id = @sched_id
	AND	SO.part_no = @part_no
	AND	SO.source_flag = 'F'
	AND	SO.location = L.location
	AND	SO.done_datetime >= @beg_date
	AND	SO.done_datetime <  @nxt_date

        SELECT	@for_quantity=IsNull(@for_quantity,0.0)

        /* Get the greatest forecast (FPO) detail date (there could be multiples within this period)*/
        SELECT	@forecast_max_datetime = MAX(SO.done_datetime)
	FROM	dbo.sched_order SO,
		#location L
	WHERE	SO.sched_id = @sched_id
	AND	SO.part_no = @part_no
	AND	SO.source_flag = 'F'
	AND	SO.location = L.location
	AND	SO.done_datetime >= @beg_date
	AND	SO.done_datetime <  @nxt_date

	-- Sum the customer demand for the same details that will be retrieved below
        SELECT	@cus_quantity=SUM(SO.uom_qty)
	FROM	#location L,
		dbo.sched_order SO
	WHERE	SO.sched_id = @sched_id
	AND	SO.part_no = @part_no
	AND	SO.source_flag = 'C'
	AND	SO.location = L.location
	AND	SO.done_datetime >= @beg_date
	AND	SO.done_datetime <  @nxt_date

        SELECT	@cus_quantity=IsNull(@cus_quantity,0.0)

        SELECT @for_quantity = @for_quantity - @cus_quantity -- for the demo, they wanted the forecast amount to show the excess forecast not yet consumed.

        SELECT @for_quantity = (@for_quantity * -1)

        INSERT #result(report_beg_balance,period_date_beg,period_date_end,report_line_type,report_line_cust_ord_id,report_line_po_id,report_line_quantity,report_line_date)
	VALUES (@inv_quantity,@beg_date,@nxt_date,'B',NULL,NULL,@for_quantity,@forecast_max_datetime)

	/* Get customer demand details */
        INSERT #result(report_beg_balance,period_date_beg,period_date_end,report_line_type,report_line_cust_ord_id,report_line_po_id,report_line_quantity,report_line_date)
	SELECT	@inv_quantity,@beg_date,@nxt_date,'C',SO.order_no,NULL,SO.uom_qty * -1,SO.done_datetime
	FROM	#location L,
		dbo.sched_order SO
	WHERE	SO.sched_id = @sched_id
	AND	SO.part_no = @part_no
	AND	SO.source_flag = 'C'
	AND	SO.location = L.location
	AND	SO.done_datetime >= @beg_date
	AND	SO.done_datetime <  @nxt_date

	/* Get production materials demand */
        INSERT #result(report_beg_balance,period_date_beg,period_date_end,report_line_type,report_line_cust_ord_id,report_line_po_id,report_line_quantity,report_line_date)
	SELECT	@inv_quantity,@beg_date,@nxt_date,'D',SP.prod_no,NULL,SOI.uom_qty * -1,SO.work_datetime
--	SELECT	@con_quantity = SUM(SOI.uom_qty)
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
	AND	SO.work_datetime >= @beg_date
	AND	SO.work_datetime <  @nxt_date
	AND	SP.sched_id = @sched_id
	AND	SP.sched_process_id = SO.sched_process_id


	/* Get on-order purchases */
	INSERT #result(report_beg_balance,period_date_beg,period_date_end,report_line_type,report_line_cust_ord_id,report_line_po_id,report_line_quantity,report_line_date)
	SELECT	@inv_quantity,@beg_date,@nxt_date,'O',NULL,SP.po_no,SI.uom_qty,SI.done_datetime
--@pur_quantity=SUM(SI.uom_qty)
	FROM	dbo.sched_item SI, dbo.sched_purchase SP,
		#location L
	WHERE	SI.sched_id = @sched_id
	AND	SI.part_no = @part_no
	AND	SI.source_flag = 'O'
	AND	SI.location = L.location
        AND     SI.sched_item_id = SP.sched_item_id
	AND	SI.done_datetime >= @beg_date
	AND	SI.done_datetime <  @nxt_date

/* Get requisitioned purchases */
	INSERT #result(report_beg_balance,period_date_beg,period_date_end,report_line_type,report_line_cust_ord_id,report_line_po_id,report_line_quantity,report_line_date)
	SELECT	@inv_quantity,@beg_date,@nxt_date,'R',NULL,SP.po_no,SI.uom_qty,SI.done_datetime
--@pur_quantity=SUM(SI.uom_qty)
	FROM	dbo.sched_item SI, dbo.sched_purchase SP,
		#location L
	WHERE	SI.sched_id = @sched_id
	AND	SI.part_no = @part_no
	AND	SI.source_flag = 'R'
	AND	SI.location = L.location
        AND     SI.sched_item_id = SP.sched_item_id
	AND	SI.done_datetime >= @beg_date
	AND	SI.done_datetime <  @nxt_date

/* Get planned purchases */
	INSERT #result(report_beg_balance,period_date_beg,period_date_end,report_line_type,report_line_cust_ord_id,report_line_po_id,report_line_quantity,report_line_date)
	SELECT	@inv_quantity,@beg_date,@nxt_date,'P',NULL,SP.po_no,SI.uom_qty,SI.done_datetime
--@pur_quantity=SUM(SI.uom_qty)
	FROM	dbo.sched_item SI, dbo.sched_purchase SP,
		#location L
	WHERE	SI.sched_id = @sched_id
	AND	SI.part_no = @part_no
	AND	SI.source_flag = 'P'
	AND	SI.location = L.location
        AND     SI.sched_item_id = SP.sched_item_id
	AND	SI.done_datetime >= @beg_date
	AND	SI.done_datetime <  @nxt_date


	/* Get production output from released and planned production*/
        INSERT #result(report_beg_balance,period_date_beg,period_date_end,report_line_type,report_line_cust_ord_id,report_line_po_id,report_line_quantity,report_line_date)
   	SELECT	@inv_quantity,@beg_date,@nxt_date,'W',SP.prod_no,NULL,SI.uom_qty,SI.done_datetime
	--SELECT	@pro_quantity = SUM(SI.uom_qty)
	FROM	dbo.sched_item SI,
		#location L,
                dbo.sched_process SP
	WHERE	SI.sched_id = @sched_id
	AND	SI.part_no = @part_no
	AND	SI.source_flag = 'M'
	AND	SI.location = L.location
	AND	SI.done_datetime >= @beg_date
	AND	SI.done_datetime <  @nxt_date
        AND     SP.sched_process_id = SI.sched_process_id


	--Correct for NULLs
	--SELECT	@cus_quantity=IsNull(@cus_quantity,0.0),
		--@con_quantity=IsNull(@con_quantity,0.0),
	--	@for_quantity=IsNull(@for_quantity,0.0),
	--	@pur_quantity=IsNull(@pur_quantity,0.0),
	--	@pro_quantity=IsNull(@pro_quantity,0.0)*/

	/*Insert into table */
	--INSERT	#result(period_date,cus_quantity,con_quantity,for_quantity,inv_quantity,pur_quantity,pro_quantity,min_quantity,ord_quantity)
	--VALUES (@beg_date,@cus_quantity,@con_quantity,@for_quantity,@inv_quantity,@pur_quantity,@pro_quantity,@min_quantity,@ord_quantity)

	/* Move to next date */
	SELECT	@beg_date=@nxt_date
	END

/* Return result set */
SELECT * FROM #result
ORDER BY period_date_beg,report_line_type,report_line_date
DROP TABLE #result

RETURN
END

GO
GRANT EXECUTE ON  [dbo].[fs_mrp_report] TO [public]
GO
