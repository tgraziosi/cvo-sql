SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- EXEC CVO_validate_manual_pop_freq_sp 'CB', '20', 'BCZBANNERNR', '035192', 0, 0

CREATE PROCEDURE [dbo].[CVO_validate_manual_pop_freq_sp] @promo_id varchar(40),
													 @promo_level varchar(40),
													 @part_no varchar(30),
													 @cust_code varchar(10),
													 @order_no int,
													 @order_ext int
AS  
BEGIN  
	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARATIONS
	 DECLARE @pop_gif				VARCHAR(30),  
			@description			VARCHAR(255),  
			@so_ext				VARCHAR(30),  
			@freq				INT,  
			@qty					INT,  
			@id					INT,  
			@total_qty			DECIMAL (20, 0),  
			@t_qty				DECIMAL (20, 0),  
			@promo_start_date	DATETIME,  
			@promo_end_date		DATETIME, 
			@frequency_type		CHAR(1), 
			@date_entered		DATETIME

	-- WORKING TABLE
	CREATE TABLE #temp (  
	   ord_no	int,   
	   ext		int,   
	   part_no  varchar(100),   
	   ordered  decimal(20,8))  

	-- PROCESSING
	SELECT	@frequency_type = ISNULL(frequency_type,'A')
	FROM	CVO_promotions (NOLOCK) 
	WHERE	promo_id = @promo_id 
	AND		promo_level = @promo_level  
	     
	SET @date_entered = ISNULL(@date_entered,GETDATE())

	EXEC cvo_get_promo_frequency_dates_sp @date_entered, @frequency_type, @promo_start_date OUTPUT,	@promo_end_date OUTPUT

	SELECT	@freq = freq,
			@qty = qty
	FROM	CVO_pop_gifts (NOLOCK)
	WHERE	promo_id = @promo_id 
	AND		promo_level = @promo_level 
	AND		part = @part_no

	INSERT  #temp  
	SELECT	l.order_no, l.order_ext, l.part_no, l.ordered  
	FROM	ord_list l (NOLOCK)  
	JOIN	orders_all o (NOLOCK) 
	ON		l.order_no = o.order_no 
	AND		l.order_ext = o.ext  
	JOIN	CVO_ord_list co (NOLOCK) 
	ON		l.order_no = co.order_no 
	AND		l.order_ext = co.order_ext 
	AND		l.line_no = co.line_no  
	WHERE	l.part_no = @part_no 
	AND		o.cust_code = @cust_code 
	AND		co.is_pop_gif = 1 
	AND		o.date_entered BETWEEN @promo_start_date AND @promo_end_date
	AND		CAST(@order_no as varchar(20)) + '-' + CAST(@order_ext as varchar(20)) <> CAST(l.order_no as varchar(20)) + '-' + CAST(l.order_ext as varchar(20))
	AND		o.status <> 'V'  
  
	UNION
	
	SELECT	l.order_no, l.order_ext, l.orig_part_no, MAX(l.ordered)  
	FROM	ord_list l (NOLOCK)   
	JOIN	orders_all o (NOLOCK) 
	ON		l.order_no = o.order_no 
	AND		l.order_ext = o.ext  
	JOIN	CVO_ord_list co (NOLOCK) 
	ON		l.order_no = co.order_no 
	AND		l.order_ext = co.order_ext 
	AND		l.line_no = co.line_no  
	WHERE	l.orig_part_no = @part_no 
	AND		o.cust_code = @cust_code 
	AND		co.is_pop_gif = 1 
	AND		o.date_entered BETWEEN @promo_start_date AND @promo_end_date
	AND		CAST(@order_no as varchar(20)) + '-' + CAST(@order_ext as varchar(20)) <> CAST(l.order_no as varchar(20)) + '-' + CAST(l.order_ext as varchar(20))
	AND		o.status <> 'V'
	GROUP BY l.order_no, l.order_ext, l.orig_part_no  

	SELECT @total_qty = ISNULL(COUNT( distinct ord_no), 0)  
	FROM #temp  
	  
	IF @total_qty >= @freq  
		SELECT -1
	ELSE
		SELECT 0

	DROP TABLE #temp  
   
END  
GO
GRANT EXECUTE ON  [dbo].[CVO_validate_manual_pop_freq_sp] TO [public]
GO
