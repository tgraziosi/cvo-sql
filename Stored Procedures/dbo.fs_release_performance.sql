SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE PROCEDURE [dbo].[fs_release_performance]
	(
	@vendor_no	VARCHAR(12)=NULL,
	@location	VARCHAR(10)=NULL,
	@part_no	VARCHAR(30)=NULL,
	@beg_date	DATETIME=NULL,
	@end_date	DATETIME=NULL,
	@days_early	INT=1,
	@days_late	INT=1
	)
AS
BEGIN


IF @end_date IS NULL
	SELECT	@end_date = getdate()
IF @beg_date IS NULL
	SELECT	@beg_date = dateadd(day,30,@end_date)


CREATE TABLE #location
	(
	location	VARCHAR(10)
	)


IF @location IS NULL
	
	INSERT INTO #location(location)
	SELECT	L.location
	FROM	dbo.locations L
ELSE
	
	INSERT INTO #location(location)
	SELECT	L.location
	FROM	dbo.locations_all L
	WHERE	L.location = @location


CREATE INDEX location ON #location(location)


CREATE TABLE #item
	(
	location	VARCHAR(10),
	item_id		VARCHAR(30),
	item_name	VARCHAR(255),
	lead_time	INT,
	price		DECIMAL(20,8)		NULL,
	vendor_id	VARCHAR(12)	NULL
	)


IF @part_no IS NULL
	
	INSERT INTO #item(location,item_id,item_name,lead_time,vendor_id)
	SELECT	L.location,I.part_no,IsNull(I.description,I.part_no),I.lead_time,I.vendor
	FROM	dbo.inventory I,
		#location L
	WHERE	I.location = L.location
ELSE
	
	INSERT INTO #item(location,item_id,item_name,lead_time,vendor_id)
	SELECT	L.location,I.part_no,IsNull(I.description,I.part_no),I.lead_time,I.vendor
	FROM	dbo.inventory I,
		#location L
	WHERE	I.location = L.location
	AND	I.part_no = @part_no


DROP TABLE #location


CREATE INDEX item ON #item(location,item_id)


CREATE TABLE #vendor
	(
	vendor_id	VARCHAR(12),
	vendor_name	VARCHAR(255)
	)


IF @vendor_no IS NULL
	
	INSERT INTO #vendor(vendor_id,vendor_name)
	SELECT	V.vendor_code,V.vendor_name
	FROM	dbo.adm_vend_all V
ELSE
	
	INSERT INTO #vendor(vendor_id,vendor_name)
	SELECT	V.vendor_code,V.vendor_name
	FROM	dbo.adm_vend_all V
	WHERE	V.vendor_code = @vendor_no


CREATE INDEX vendor ON #vendor(vendor_id)


CREATE TABLE #result
	(
	vendor_id	VARCHAR(12),
	vendor_name	VARCHAR(255),
	location	VARCHAR(10),
	item_id		VARCHAR(30),
	item_name	VARCHAR(255),
	effective_date	DATETIME	NULL,
	price		DECIMAL(20,8)		NULL,
	lead_time	INT,
	order_total	INT,
	order_early	INT,
	order_ontime	INT,
	order_late	INT,
	order_cancel	INT,
	item_total	FLOAT,
	item_fail	FLOAT
	)


INSERT INTO #result
	(
	vendor_id,
	vendor_name,
	location,
	item_id,
	item_name,
	effective_date,
	price,
	lead_time,
	order_total,
	order_early,
	order_ontime,
	order_late,
	order_cancel,
	item_total,
	item_fail
	)
SELECT	DISTINCT
	V.vendor_id,	
	V.vendor_name,	
	I.location,	
	I.item_id,	
	I.item_name,	
	NULL,		
	NULL,		
	I.lead_time,	
	0,		
	0,		
	0,		
	0,		
	0,		
	0.0,		
	0.0		
FROM	#vendor V,
	#item I
WHERE	V.vendor_id = I.vendor_id
OR	EXISTS (SELECT	*
		FROM	dbo.purchase_all P,
			dbo.pur_list PL
		WHERE	PL.part_no = I.item_id
		AND	PL.po_no = P.po_no
		AND	P.vendor_no = V.vendor_id)
OR	EXISTS (SELECT	*
		FROM	dbo.vendor_sku S
		WHERE	S.sku_no = I.item_id
		AND	S.vendor_no = V.vendor_id)


CREATE UNIQUE INDEX result ON #result(location,item_id,vendor_id)


DROP TABLE #item
DROP TABLE #vendor


UPDATE	#result
SET	price = S.last_price
FROM	#result R,
	dbo.vendor_sku S
WHERE	S.sku_no = R.item_id
AND	S.vendor_no = R.vendor_id


UPDATE	#result
SET	order_total=(	SELECT	COUNT(*)
			FROM	dbo.receipts_all R
			WHERE	R.vendor = #result.vendor_id
			AND	R.part_no = #result.item_id
			AND	R.location = #result.location
			AND	R.release_date BETWEEN @beg_date AND @end_date),
	order_early=(	SELECT	COUNT(*)
			FROM	dbo.receipts_all R
			WHERE	R.vendor = #result.vendor_id
			AND	R.part_no = #result.item_id
			AND	R.location = #result.location
			AND	R.release_date BETWEEN @beg_date AND @end_date
			AND	datediff(day,R.release_date,R.recv_date) > @days_early),
	order_ontime=(	SELECT	COUNT(*)
			FROM	dbo.receipts_all R
			WHERE	R.vendor = #result.vendor_id
			AND	R.part_no = #result.item_id
			AND	R.location = #result.location
			AND	R.release_date BETWEEN @beg_date AND @end_date
			AND	datediff(day,R.release_date,R.recv_date) BETWEEN -@days_late AND @days_early),
	order_late=(	SELECT	COUNT(*)
			FROM	dbo.receipts_all R
			WHERE	R.vendor = #result.vendor_id
			AND	R.part_no = #result.item_id
			AND	R.location = #result.location
			AND	R.release_date BETWEEN @beg_date AND @end_date
			AND	datediff(day,R.release_date,R.recv_date) < -@days_late),
	order_cancel = 	0,
	item_total=IsNull((	SELECT	SUM(quantity)
				FROM	dbo.receipts_all R
				WHERE	R.vendor = #result.vendor_id
				AND	R.part_no = #result.item_id
				AND	R.location = #result.location
				AND	R.release_date BETWEEN @beg_date AND @end_date),0),
	item_fail = 0.0

SELECT	effective_date,
	vendor_id,
	vendor_name,
	location,
	item_id,
	item_name,
	price,
	lead_time,
	order_total,
	order_early,
	order_ontime,
	order_late,
	order_cancel,
	item_total,
	item_fail
FROM	#result


DROP TABLE #result

RETURN
END
GO
GRANT EXECUTE ON  [dbo].[fs_release_performance] TO [public]
GO
