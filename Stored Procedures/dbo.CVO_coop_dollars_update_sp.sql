SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.1 CT 22/10/12 - Updated logic to match SP cvo_coop_dollars
-- v1.2	CT 25/02/13 - Coop values no longer updated within Enterprise

CREATE PROCEDURE [dbo].[CVO_coop_dollars_update_sp]
	@customer_code  VARCHAR(10), @eligible CHAR(1), @threshold_flag VARCHAR(1), 
	@threshold_amount DECIMAL(20, 8), @cust_rate INT
            
AS            
BEGIN
	declare @category				INT,
			@id						INT,
			@order_no				INT,
			@ext					INT,
			@amt_order_total		DECIMAL(20, 8),
			@coop_cust_rate			int, 
			@coop_general_rate		DECIMAL(20,8), 
			@coop_general_account	varchar(40),
			@coop_general_minsales	DECIMAL(20,8),
			@order_category			varchar(40),
			@user_category			varchar(40),
			@rate_for_use			DECIMAL(20,8),
			@minsales_for_use		decimal(20,8),
			@coop_dollars_amount	decimal(20,8),
			@total_amt_order_cur	decimal(20,8),
			@coop_points_calculated	decimal(20,8),
			@coop_date				datetime,
			@coop_percentage		decimal(20,8),
			@Do_Update_on_Cust		int

	-- START v1.1
	DECLARE @total_sales			DECIMAL(20,8),    
			@total_sales_hist		DECIMAL(20,8),
			@coop_ytd				DECIMAL(20,8) 
	-- END v1.1

	-- START v1.2
	RETURN
	-- END v1.2

	CREATE TABLE #orders (
			id			INT IDENTITY(1,1),
			order_no	INT,
			ext			INT,
			coop_date	DATETIME, -- v1.1
			order_total	DECIMAL(20,8) -- v1.1
	)

	--Get the values from tables into variables at application level
	select @coop_general_account = ISNULL(value_str, '') from config where flag = 'COOP_ACCOUNT'
	select @coop_general_minsales = CAST(ISNULL(value_str, '0') as DECIMAL(20,8))  from config where flag = 'COOP_MINSALES'
	select @coop_general_rate = CAST(ISNULL(value_str, '0') as DECIMAL(20,8)) from config where flag = 'COOP_RATE' 


	-- ****************** VALIDATIONS **************************/
	-- Verify if customer is eligible
	IF @eligible <> 'Y' 
	BEGIN
		-- Delete all the history for the customer in the current year
		DELETE FROM cvo_coop_dollars_history 
			WHERE	customer_code = @customer_code AND 
					coop_date between (SELECT DATEADD(yy, DATEDIFF(yy,0,getdate()), 0))   
			  and  (SELECT dateadd(year, 1, dateadd(ms,-3,DATEADD(yy, DATEDIFF(yy,0,getdate() ), 0))))

		-- START v1.1 
		-- Write to audit table
		INSERT INTO cvo_coop_audit(
			customer_code,
			from_dollars,
			to_dollars,
			from_ytd,
			to_ytd,
			add_date,
			add_user)
		SELECT
			customer_code,
			coop_dollars,
			0,
			coop_ytd,
			0,
			GETDATE(),
			SUSER_SNAME()
		FROM
			dbo.cvo_armaster_all (NOLOCK)
		WHERE 
			customer_code = @customer_code
			and address_type = 0
		-- END v1.1

		-- Update COOP points since these will be recalculated 
		UPDATE 
			cvo_armaster_all 
		SET 
			coop_dollars = 0,
			coop_ytd = 0 -- v1.1
		WHERE 
			customer_code = @customer_code
			and address_type = 0 -- v1.1

		SELECT 1, 'ok'  --It's not a customer coop eligible
		RETURN
	END
	
	-- Check if the threshold is assigned	----------
	if @threshold_flag = 'Y'  --Then its by customer level
	BEGIN
		IF @threshold_amount = 0
		BEGIN
			IF @coop_general_minsales = 0
			BEGIN
				select 1, 'ok' 	--It's not a threshold amount configured in customer level neither application level
				return
			END
			ELSE
			BEGIN
				SELECT @minsales_for_use = @coop_general_minsales
			END
		END
		ELSE
		BEGIN
			SELECT @minsales_for_use = @threshold_amount
		END
	END
	ELSE	--It's by application level
	BEGIN
		IF @coop_general_minsales = 0
		BEGIN
			select 1, 'ok' 	--It's not a threshold amount configurated at application level
			return
		END
		ELSE
		BEGIN
			SELECT @minsales_for_use = @coop_general_minsales
		END
	END
	  
	-- Check if the Rate is assigned	----------
	IF @cust_rate = 0
	BEGIN
		IF @coop_general_rate = 0
		BEGIN
			select 1, 'ok' 	--It's not a Rate configured in customer level neither application level
			return
		END
		ELSE
		BEGIN
			SELECT @rate_for_use = @coop_general_rate
		END
	END
	ELSE
	BEGIN
		SELECT @rate_for_use = @cust_rate
	END

	select @Do_Update_on_Cust = 1

	--Check if the customer reach the Rate Sales of the year 
	-- START v1.1
	/*
	IF ISNULL((SELECT sum(gross_sales) FROM orders
		WHERE cust_code = @customer_code
		AND orders.status >= 'R' and orders.status <> 'V'
		AND	IsNull(orders.invoice_date,orders.date_shipped)					-- TLM : Fix
		between (SELECT DATEADD(yy, DATEDIFF(yy,0,getdate()), 0))   
		and  (SELECT dateadd(year, 1, dateadd(ms,-3,DATEADD(yy, DATEDIFF(yy,0,getdate() ), 0))))
		), 0) < @minsales_for_use
	*/

	SELECT 
		@total_sales = SUM(CASE WHEN type = 'C' THEN ((ISNULL(gross_sales,0) - ISNULL(total_discount,0)) * -1) ELSE ISNULL(gross_sales,0) - ISNULL(total_discount,0) END) 
	FROM 
		dbo.orders_all orders (NOLOCK)	-- v1.4												-- TLM : Fix
	WHERE 
		cust_code = @customer_code  
		AND orders.status > 'S' 
		AND orders.status <> 'V'												-- TLM : Fix  
		AND orders.invoice_date	BETWEEN (SELECT DATEADD(yy, DATEDIFF(yy,0,getdate()), 0)) AND  (SELECT dateadd(year, 1, dateadd(ms,-3,DATEADD(yy, DATEDIFF(yy,0,getdate() ), 0))))
		AND ((orders.user_category IN (SELECT order_category FROM CVO_order_types WHERE category_eligible = 'Y')) OR (orders.[type] = 'C'))
	
	SELECT 
		@total_sales_hist = SUM(CASE WHEN type = 'C' THEN ((ISNULL(total_amt_order,0) - ISNULL(tot_ord_disc,0)) * -1) ELSE ISNULL(total_amt_order,0) - ISNULL(tot_ord_disc,0) END) 
	FROM 
		dbo.cvo_orders_all_hist orders (NOLOCK)	-- v1.4												
	WHERE 
		cust_code = @customer_code  
		AND orders.status > 'S' 
		AND orders.status <> 'V'												-- TLM : Fix  
		AND orders.invoice_date	BETWEEN (SELECT DATEADD(yy, DATEDIFF(yy,0,getdate()), 0)) AND  (SELECT dateadd(year, 1, dateadd(ms,-3,DATEADD(yy, DATEDIFF(yy,0,getdate() ), 0))))
		AND ((orders.user_category IN (SELECT order_category FROM CVO_order_types WHERE category_eligible = 'Y')) OR (orders.[type] = 'C'))

	SET @total_sales = ISNULL(@total_sales,0) + ISNULL(@total_sales_hist,0)

	IF @total_sales < @minsales_for_use
	-- END v1.1
	BEGIN
		select @Do_Update_on_Cust = 0
		--SELECT 1, 'ok6'  --Do not meet the threshold
		--RETURN
	END

	-- Delete all the history for the customer in the current year
	DELETE FROM cvo_coop_dollars_history 
	WHERE	customer_code = @customer_code AND 
			coop_date between (SELECT DATEADD(yy, DATEDIFF(yy,0,getdate()), 0))   
			and  (SELECT dateadd(year, 1, dateadd(ms,-3,DATEADD(yy, DATEDIFF(yy,0,getdate() ), 0))))

	-- START v1.1 
	-- Write to audit table
	INSERT INTO cvo_coop_audit(
		customer_code,
		from_dollars,
		to_dollars,
		from_ytd,
		to_ytd,
		add_date,
		add_user)
	SELECT
		customer_code,
		coop_dollars,
		0,
		coop_ytd,
		0,
		GETDATE(),
		SUSER_SNAME()
	FROM
		dbo.cvo_armaster_all (NOLOCK)
	WHERE 
		customer_code = @customer_code
		AND address_type = 0
		AND NOT (coop_ytd = 0 AND coop_dollars = 0)
	-- END v1.1

	-- Update COOP points since these will be recalculated 
	UPDATE 
		cvo_armaster_all 
	SET 
		coop_dollars = 0,
		coop_ytd = 0	-- v1.1
	WHERE 
		customer_code = @customer_code 
		AND address_type = 0

	-- Look up for all the orders in the current year for the customer
	-- START v1.1
	/*
	INSERT INTO #orders (order_no, ext)
	SELECT	order_no, ext 
	FROM	orders
	WHERE	cust_code = @customer_code AND orders.status >= 'R' and orders.status <> 'V' AND											-- TLM : Fix  
			IsNull(orders.invoice_date,orders.date_shipped)					-- TLM : Fix
			between (SELECT DATEADD(yy, DATEDIFF(yy,0,getdate()), 0))   
			and  (SELECT dateadd(year, 1, dateadd(ms,-3,DATEADD(yy, DATEDIFF(yy,0,getdate() ), 0))))
	*/
	INSERT INTO #orders (
		order_no, 
		ext,
		coop_date,
		order_total)
	SELECT	
		order_no, 
		ext,
		ISNULL(invoice_date,date_shipped),
		ISNULL(CASE WHEN type = 'C' THEN ((ISNULL(gross_sales,0) - ISNULL(total_discount,0)) * -1) ELSE ISNULL(gross_sales,0) - ISNULL(total_discount,0) END,0) 
	FROM 
		dbo.orders (NOLOCK)
	WHERE 
		cust_code = @customer_code
		AND ((orders.user_category IN (SELECT order_category FROM CVO_order_types WHERE category_eligible = 'Y')) OR (orders.[type] = 'C'))	
		AND orders.invoice_date BETWEEN (SELECT DATEADD(yy, DATEDIFF(yy,0,getdate()), 0)) AND  (SELECT dateadd(year, 1, dateadd(ms,-3,DATEADD(yy, DATEDIFF(yy,0,getdate() ), 0)))) 
	UNION
	SELECT	
		order_no, 
		ext,
		ISNULL(invoice_date,date_shipped),
		ISNULL(CASE WHEN type = 'C' THEN ((ISNULL(total_amt_order,0) - ISNULL(tot_ord_disc,0)) * -1) ELSE ISNULL(total_amt_order,0) - ISNULL(tot_ord_disc,0) END,0)
	FROM 
		dbo.cvo_orders_all_hist (NOLOCK)
	WHERE 
		cust_code = @customer_code
		AND ((user_category IN (SELECT order_category FROM CVO_order_types WHERE category_eligible = 'Y')) OR ([type] = 'C'))	
		AND invoice_date BETWEEN (SELECT DATEADD(yy, DATEDIFF(yy,0,getdate()), 0)) AND  (SELECT dateadd(year, 1, dateadd(ms,-3,DATEADD(yy, DATEDIFF(yy,0,getdate() ), 0))))
	-- END v1.1

	SELECT @coop_dollars_amount = 0, @amt_order_total = 0

	SELECT @id = MIN(id) FROM #orders

	WHILE (@id IS NOT NULL)
	BEGIN
		-- START v1.1
		SELECT	
			@order_no = order_no, 
			@ext = ext,
			@coop_date = coop_date,
			@total_amt_order_cur = order_total
		FROM	
			#orders
		WHERE	
			id = @id
		

		-- Code no longer required
		/*
		SELECT	@user_category = ISNULL(user_category, 'N'), @total_amt_order_cur = ISNULL(gross_sales, 0),
				@coop_date = IsNull(invoice_date,date_shipped)					-- TLM : Fix
		FROM	orders
		WHERE	order_no = @order_no AND
				ext = @ext
				
		-- Check for the order type existence in the coop order type table -if it is there is eligible
		SELECT @order_category = category_eligible	from CVO_order_types where order_category = @user_category

		SELECT @category = 0

		IF @order_category = 'N' OR ISNULL(@order_category, '') = ''
		BEGIN
			SELECT @category = 1
		END

		IF (@category = 0)
		*/
		-- END v1.1
		BEGIN
--			SELECT @amt_order_total = @amt_order_total + @total_amt_order_cur
			
			SET @coop_percentage = @rate_for_use / cast(100 as decimal(20,8))
			SET @coop_points_calculated =  ROUND(@total_amt_order_cur * @coop_percentage,2)
			SET @coop_dollars_amount = @coop_dollars_amount + @coop_points_calculated			-- TLM : Fix
							
			------------- Insert into the history table ----------------------
			INSERT cvo_coop_dollars_history(order_no, order_ext, coop_dollars, coop_date, customer_code)
			VALUES(@order_no, @ext, @coop_points_calculated, @coop_date, @customer_code)
			------------- End Insert into the history table ----------------------

--			------------- Insert into the coop table ----------------------
--			If @Do_Update_on_Cust = 1
--				BEGIN			
--				UPDATE cvo_armaster_all set coop_dollars = @coop_dollars_amount where customer_code = @customer_code and address_type = 0
--				END
--			------------- End Insert into the coop table ----------------------
		END
		
		SELECT	@id = MIN(id) 
		FROM	#orders
		WHERE	id > @id
	END

	------------- Insert into the coop table ----------------------
	If @Do_Update_on_Cust = 1
	BEGIN	
		
		-- START v1.1 
		-- Calculate the coop ytd for the year
		SELECT @coop_ytd = dbo.f_calculate_coop_ytd (@customer_code,0,0)
	
		-- Write to audit table
		INSERT INTO cvo_coop_audit(
			customer_code,
			from_dollars,
			to_dollars,
			from_ytd,
			to_ytd,
			add_date,
			add_user)
		SELECT
			customer_code,
			coop_dollars,
			@coop_dollars_amount,
			coop_ytd,
			@coop_ytd,
			GETDATE(),
			SUSER_SNAME()
		FROM
			dbo.cvo_armaster_all (NOLOCK)
		WHERE 
			customer_code = @customer_code
			and address_type = 0

		-- END v1.1

		UPDATE 
			cvo_armaster_all 
		SET 
			coop_dollars = @coop_dollars_amount,
			coop_ytd = @coop_ytd -- v1.1 
		WHERE 
			customer_code = @customer_code 
			AND address_type = 0
	END
	------------- End Insert into the coop table ----------------------

	DROP TABLE #orders

	SELECT 1, 'ok7'
END


GO
GRANT EXECUTE ON  [dbo].[CVO_coop_dollars_update_sp] TO [public]
GO
