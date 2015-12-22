SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







--v2.0	TM	Performance
--v2.1  tg - increase size of location in #rtns
--  Exec cvo_returns_vw " where part_no like '%BCTESTOR49156%' AND cust_code like '%029857%'"

CREATE PROCEDURE [dbo].[CVO_Returns_vw] @whereclause VARCHAR(8000)
AS

DECLARE @SQL	varchar(8000),
		@rowID	int,
		@YTDS	decimal(20,8),
		@cust	varchar(8),
		@part	varchar(32),
		@PctRtn	decimal(20,8),
		@ShpQ	decimal(20,8),
		@RtnQ	decimal(20,8)

DECLARE	@sPart_no varchar(32),	@sCust_code varchar(8),
		@StrPart varchar(100),	@StrCust varchar(100)

SELECT @StrPart = SUBSTRING(@whereclause,CHARINDEX('part_no',@whereclause)+15,1000)
SELECT @sPart_no = SUBSTRING(@StrPart,1,CHARINDEX('%',@StrPart)-1)

SELECT @StrCust = SUBSTRING(@whereclause,CHARINDEX('cust_code',@whereclause)+17,1000)
SELECT @sCust_code = SUBSTRING(@StrCust,1,CHARINDEX('%',@StrCust)-1)


CREATE TABLE #Rtns
(row_id			int	IDENTITY(1,1),
 order_no		int,
 order_ext		int,
 cust_code		varchar(8),
 trx_type		varchar(8),
 order_type		varchar(8),
 date_shipped	datetime,
 shipped		decimal(20,8),
 part_no		varchar(32),
 price			decimal(20,8),
 extended_price	decimal(20,8),
 YTD_sales		decimal(20,8),
 Return_code	varchar(8), 
 pct_returns	decimal(20,8),
 location		varchar(10), -- tag - 071212 - increase location from 8 to 10 characters
 vendor			varchar(12),
 Xflag			varchar(1),
 List_Price		decimal(20,8)								--v3.0
)

CREATE INDEX rt1_idx ON #Rtns (order_no, order_ext)					--v2.0
CREATE INDEX rt2_idx ON #Rtns (part_no)								--v2.0
CREATE INDEX rt3_idx ON #Rtns (cust_code, part_no)					--v2.0


-- Insert Invoices
INSERT INTO #Rtns
SELECT	l.order_no,
		l.order_ext,
		o.cust_code,
		'Invoice' as trx_type,
		o.user_category as order_type,
		o.date_shipped,
		qty_shipped = l.shipped,
		l.part_no,
		--l.price,
		--l.shipped * l.price as extended_price,
-- updated from just price to fix BG pricing with extra discounting issues EL 1/15/2013
		CASE O.type WHEN 'I' THEN 
			CASE isnull(c.is_amt_disc,'N')   
			WHEN 'Y' THEN round((l.curr_price - isnull(c.amt_disc,0)), 2)		
			ELSE round(l.curr_price - (l.curr_price * (l.discount / 100.00)),2) END	
		    ELSE round(l.curr_price -  (l.curr_price *  (l.discount / 100.00)),2)		
			END as Price,
		CASE O.type WHEN 'I' THEN 
			CASE isnull(c.is_amt_disc,'N')   
			WHEN 'Y' THEN round(l.shipped * l.curr_price,2) -  round((l.shipped * isnull(c.amt_disc,0)),2)
			ELSE	round(l.shipped * l.curr_price,2) -   
					round(( (l.shipped * l.curr_price) * (l.discount / 100.00)),2) END
		    ELSE	round(-l.cr_shipped * l.curr_price,2) -  
				      round(( (-l.cr_shipped * l.curr_price) * (l.discount / 100.00)),2)
			END as Extended_price,	
		0,
		' ' as Return_code, 
		0,
		l.location,
		i.vendor,
		'O',
		c.list_price
FROM
	orders o (NOLOCK), ord_list l (NOLOCK)
	LEFT OUTER JOIN inv_master i (NOLOCK) ON l.part_no = i.part_no				-- v2.0
	LEFT OUTER JOIN cvo_ord_list c ON l.order_no = c.order_no AND l.order_ext = c.order_ext AND l.line_no = c.line_no
WHERE l.order_no = o.order_no
AND l.order_ext = o.ext
AND o.type = 'I'
AND (o.status > 'S' and o.status < 'V')
AND l.shipped > 0
AND o.cust_code = @sCust_code
AND l.part_no = @sPart_no


-- Insert Invoice History
INSERT INTO #Rtns
SELECT	l.order_no,
		l.order_ext,
		substring(o.cust_code,1,8),
		'Invoice' as trx_type,
		o.user_category as order_type,
		o.date_shipped,
		qty_shipped = l.shipped,
		l.part_no,
		l.price,
		l.shipped * l.price as extended_price,
		0,
		' ' as Return_code, 
		0,
		l.location,
		i.vendor,
		'H',
		l.cost as List_Price
FROM
	cvo_orders_all_hist o (NOLOCK), cvo_ord_list_hist l (NOLOCK)
	LEFT OUTER JOIN inv_master i (NOLOCK) ON l.part_no = i.part_no
WHERE l.order_no = o.order_no
AND l.order_ext = o.ext
AND o.type = 'I'
AND (o.status > 'S' and o.status < 'V')
AND l.shipped > 0
AND substring(o.cust_code,1,8) = @sCust_code
AND l.part_no = @sPart_no


IF (SELECT count(*) FROM #Rtns) > 0
BEGIN
	DECLARE rtn01 CURSOR FOR Select DISTINCT cust_code, part_no from #Rtns
	OPEN rtn01
	FETCH NEXT from rtn01 INTO @cust, @part
	while @@fetch_status = 0
	begin
		SELECT @ytds = ROUND(SUM(l.shipped * l.price),2)
		  FROM	orders o (NOLOCK), ord_list l (NOLOCK)
	--v2.0		LEFT OUTER JOIN inventory i (NOLOCK) ON l.part_no = i.part_no and l.location = i.location
		 WHERE l.order_no = o.order_no AND l.order_ext = o.ext
		   AND o.type = 'I' AND l.status > 'S' and l.status < 'V'
		   AND o.cust_code = @cust AND l.part_no = @part

		UPDATE #Rtns SET ytd_sales = @ytds WHERE cust_code = @cust AND part_no = @part
	
		FETCH NEXT from rtn01 INTO @cust, @part
	end 
	close rtn01 
	deallocate rtn01
END


-- Insert Credits
INSERT INTO #Rtns
SELECT	l.order_no,
		l.order_ext,
		o.cust_code,
		'Return' as trx_type,
		' ' as order_type,
		o.invoice_date as date_shipped,
		qty_shipped = (l.cr_shipped * -1),
		l.part_no,
		l.price * -1 as price,
		(l.cr_shipped * l.price) * -1 as extended_price,
		0,
		l.return_code as return_code,
		0,
		l.location,
		i.vendor,
		'O',
		c.list_price * -1 as List_Price
FROM
	orders o (NOLOCK), ord_list l (NOLOCK)
	LEFT OUTER JOIN inv_master i (NOLOCK) ON l.part_no = i.part_no			--v2.0
	LEFT OUTER JOIN cvo_ord_list c ON l.order_no = c.order_no AND l.order_ext = c.order_ext AND l.line_no = c.line_no
WHERE l.order_no = o.order_no
AND l.order_ext = o.ext
AND o.type = 'C'
AND (o.status > 'S' and o.status < 'V')
AND o.cust_code = @sCust_code
AND l.part_no = @sPart_no
-- Insert Credit History
INSERT INTO #Rtns
SELECT	l.order_no,
		l.order_ext,
		Substring(o.cust_code,1,8),
		'Return' as trx_type,
		' ' as order_type,
		o.invoice_date as date_shipped,
		qty_shipped = (IsNull(l.cr_shipped,1) * -1),
		l.part_no,
		l.price * -1 as price,
		(IsNull(l.cr_shipped,1) * l.price) * -1 as extended_price,
		0,
		l.return_code as return_code,
		0,
		l.location,
		i.vendor,
		'H',
		l.cost * -1 as List_Price
FROM
	cvo_orders_all_hist o (NOLOCK), cvo_ord_list_hist l (NOLOCK)
	LEFT OUTER JOIN inv_master i (NOLOCK) ON l.part_no = i.part_no				--v2.0
WHERE l.order_no = o.order_no
AND l.order_ext = o.ext
AND o.type = 'C'
AND (o.status > 'S' and o.status < 'V')
AND substring(o.cust_code,1,8) = @sCust_code
AND l.part_no = @sPart_no


IF (SELECT count(*) FROM #Rtns) > 0
BEGIN
	DECLARE rtn02 CURSOR FOR Select DISTINCT cust_code, part_no from #Rtns
	OPEN rtn02
	FETCH NEXT from rtn02 INTO @cust, @part
	while @@fetch_status = 0
	begin
		SELECT @ShpQ = SUM(shipped) FROM #Rtns WHERE cust_code = @cust AND part_no = @part AND trx_type = 'Invoice'
		SELECT @RtnQ = SUM(shipped) * -1 FROM #Rtns WHERE cust_code = @cust AND part_no = @part AND trx_type = 'Return'
		SELECT @PctRtn = ROUND(@RtnQ / @ShpQ,2)
	
		UPDATE #Rtns SET pct_returns = @PctRtn WHERE cust_code = @cust AND part_no = @part AND trx_type = 'Return'
	
		FETCH NEXT from rtn02 INTO @cust, @part
	end 
	close rtn02 
	deallocate rtn02
END

--
--
If @whereclause > ' '
BEGIN
	SELECT @SQL = 'SELECT order_no,order_ext,cust_code,trx_type,order_type,date_shipped,shipped,part_no,price,List_Price,extended_price,YTD_sales,Return_code,pct_returns,location,vendor, x_date_shipped = date_shipped FROM #Rtns '+@whereclause
END
ELSE
BEGIN
	SELECT @SQL = 'SELECT order_no,order_ext,cust_code,trx_type,order_type,date_shipped,shipped,part_no,price,List_Price,extended_price,YTD_sales,Return_code,pct_returns,location,vendor, x_date_shipped = date_shipped FROM #Rtns '
END

EXEC (@SQL)
--
--
GO
GRANT EXECUTE ON  [dbo].[CVO_Returns_vw] TO [public]
GO
