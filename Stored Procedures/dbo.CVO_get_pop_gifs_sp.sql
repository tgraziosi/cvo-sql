SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 05/03/2012 - Fix - Pass in promo_id and level as the order hasn't been save yet  
-- v1.1 CB 14/03/2012 - Fix - Exclude voided orders
-- v1.2 CB 28/03/2012 - Fix - Freq should be the number of orders and not the quantity of items
-- v1.3 CT 18/10/2013 - Issue #1399 - If promo is overridden the don't check frequency on pop gifts
-- v1.4 CT 06/11/2013 - Issue #1399 - Added RETURN into logic from v1.3 to stop duplicates being returned when promo is overriden
-- v1.5 CT 12/02/2014 - Issue #1426 - Check frequency type
--EXEC [CVO_get_pop_gifs_sp] 1418532, 0, '015643','ME VTO','VTO PS'
CREATE PROCEDURE [dbo].[CVO_get_pop_gifs_sp]		@order_no		INT, 
												@ext			INT, 
												@cust_code		varchar(10), -- v1.0
												@promo_id		VARCHAR(40), -- v1.0
												@promo_level	VARCHAR(40), -- v1.0
												@override		SMALLINT = 0 -- v1.3 
AS  
BEGIN  
	 DECLARE --@cust_code   VARCHAR(30),  v1.0
			--   @promo_id			VARCHAR(40),  v1.0
			--   @promo_level		VARCHAR(40),  v1.0
			@pop_gif				VARCHAR(30),  
			@description			VARCHAR(255),  
			@so_ext				VARCHAR(30),  
			@freq				INT,  
			@qty					INT,  
			@id					INT,  
			@total_qty			DECIMAL (20, 0),  
			@t_qty				DECIMAL (20, 0),  
			@promo_start_date	DATETIME,  
			@promo_end_date		DATETIME, 
			-- START v1.5
			@frequency_type		CHAR(1), 
			@date_entered		DATETIME
			-- END v1.5
	     
	  
	 CREATE TABLE #CVO_pop_gifts(  
	  id   INT IDENTITY(1,1),  
	  part  varchar(30) NULL,  
	  description varchar(255) NULL,  
	  qty   int NULL,  
	  freq  int NULL  
	 )   
	  
	 CREATE TABLE #CVO_pop_gifts2(  
	  part  varchar(30) NULL,  
	  description varchar(255) NULL,  
	  qty   DECIMAL NULL  
	 )  
	 
	-- v1.0
	/* 
	 SELECT @cust_code = o.cust_code, @promo_id = co.promo_id, @promo_level = co.promo_level  
	 FROM orders_all o (NOLOCK) 
	   INNER JOIN CVO_orders_all co (NOLOCK) ON o.order_no = co.order_no AND o.ext = co.ext  
	 WHERE o.order_no = @order_no AND o.ext = @ext  
	*/  

	 -- START v1.5
	 SELECT
		@frequency_type = ISNULL(frequency_type,'A')
	 --SELECT @promo_start_date = promo_start_date, @promo_end_date = promo_end_date   
	 -- END v1.5
	 FROM CVO_promotions (NOLOCK) 
	 WHERE promo_id = @promo_id AND promo_level = @promo_level  
	  
	 SELECT @so_ext = CAST(@order_no AS VARCHAR(20)) + '-' + CAST(@ext AS VARCHAR(20))  
	  
	 INSERT INTO #CVO_pop_gifts (part, description, qty, freq)  
	 SELECT part, description, qty, freq  
	 FROM CVO_pop_gifts (NOLOCK) 
	 WHERE promo_ID = @promo_id AND promo_level = @promo_level  
	  
	 -- START v1.3
	 -- If promo is overriden then return all promo parts
	 IF ISNULL(@override,0) <> 0
	 BEGIN
		SELECT part, description, qty FROM #CVO_pop_gifts
		RETURN -- v1.4
	 END 
	 -- END v1.3

	 -- START v1.5
	-- Get order creation date if order number has been passed
	IF @order_no = 0
	BEGIN
		SET @date_entered = GETDATE()
	END
	ELSE
	BEGIN
		SELECT
			@date_entered = date_entered 
		FROM
			dbo.orders_all (NOLOCK)
		WHERE
			order_no = @order_no 
			AND ext = @ext
	END

	SET @date_entered = ISNULL(@date_entered,GETDATE())

	-- Get start and end date
	EXEC cvo_get_promo_frequency_dates_sp @date_entered, @frequency_type, @promo_start_date OUTPUT,	@promo_end_date OUTPUT
	-- END v1.5

	 SELECT @id = MIN(id)  
	 FROM #CVO_pop_gifts  
	  
	 CREATE TABLE #temp (  
	   ord_no  INT,   
	   ext   INT,   
	   part_no  VARCHAR(100),   
	   ordered  DECIMAL(20, 8)  
	 )  
	   
	 WHILE (@id IS NOT NULL)  
	 BEGIN  
	  SELECT @pop_gif = part, @freq = freq, @description = description, @qty = qty  
	  FROM #CVO_pop_gifts  
	  WHERE id = @id  
	  
	  DELETE FROM #temp  
	    
	  INSERT INTO #temp  
	  SELECT l.order_no, l.order_ext, l.part_no, l.ordered  
	  FROM ord_list l (NOLOCK)  
		INNER JOIN orders_all o (NOLOCK) ON l.order_no = o.order_no AND l.order_ext = o.ext  
		INNER JOIN CVO_ord_list co (NOLOCK) ON l.order_no = co.order_no AND l.order_ext = co.order_ext and l.line_no = co.line_no  
	  WHERE l.part_no = @pop_gif AND o.cust_code = @cust_code AND co.is_pop_gif = 1 AND  
		(CAST(l.order_no AS VARCHAR(20)) + '-' + CAST(l.order_ext AS VARCHAR(20)) <> @so_ext) AND  
		(o.date_entered BETWEEN @promo_start_date AND @promo_end_date) 
		AND o.status <> 'V' -- v1.1 
	  
	  INSERT INTO #temp  
	  SELECT l.order_no, l.order_ext, l.orig_part_no, MAX(l.ordered)  
	  FROM ord_list l (NOLOCK)   
		INNER JOIN orders_all o (NOLOCK) ON l.order_no = o.order_no AND l.order_ext = o.ext  
		INNER JOIN CVO_ord_list co (NOLOCK) ON l.order_no = co.order_no AND l.order_ext = co.order_ext and l.line_no = co.line_no  
	  WHERE l.orig_part_no = @pop_gif AND o.cust_code = @cust_code AND co.is_pop_gif = 1 AND  
		(CAST(l.order_no AS VARCHAR(20)) + '-' + CAST(l.order_ext AS VARCHAR(20)) <> @so_ext) AND  
		(o.date_entered BETWEEN @promo_start_date AND @promo_end_date)  
		AND o.status <> 'V' -- v1.1
	  GROUP BY l.order_no, l.order_ext, l.orig_part_no  
	  
	  /*SELECT @total_qty = ISNULL(SUM(l.ordered), 0)  
	  FROM ord_list l   
		INNER JOIN orders_all o ON l.order_no = o.order_no AND l.order_ext = o.ext  
		INNER JOIN CVO_ord_list co ON l.order_no = co.order_no AND l.order_ext = co.order_no and l.line_no = co.line_no  
	  WHERE l.part_no = @pop_gif AND o.cust_code = @cust_code AND co.is_pop_gif = 1 AND  
		(CAST(l.order_no AS VARCHAR(20)) + '-' + CAST(l.order_ext AS VARCHAR(20)) <> @so_ext) AND  
		(o.date_entered BETWEEN @promo_start_date AND @promo_end_date)*/  

	  -- v1.2 Start
	--  SELECT @total_qty = ISNULL(SUM(ordered), 0)  
	--  FROM #temp  
	  
	  SELECT @total_qty = ISNULL(COUNT( distinct ord_no), 0)  
	  FROM #temp  
	  -- v1.2 End
	  
	  IF @total_qty < @freq  
	  BEGIN  
	-- v1.2   SELECT @t_qty = @freq - @total_qty  

	-- v1.2   IF @t_qty < @qty  
	-- v1.2    SELECT @qty = @t_qty       
	  
	   INSERT INTO #CVO_pop_gifts2 VALUES (@pop_gif, @description, @qty)  
	  END  

	  SELECT @id = MIN(id)  
	  FROM #CVO_pop_gifts  
	  WHERE id > @id  
	 END  
	  
	 SELECT part, description, qty FROM #CVO_pop_gifts2  
	  
	 DROP TABLE #CVO_pop_gifts  
	 DROP TABLE #CVO_pop_gifts2  
	 DROP TABLE #temp  
   
END  
GO
GRANT EXECUTE ON  [dbo].[CVO_get_pop_gifs_sp] TO [public]
GO
