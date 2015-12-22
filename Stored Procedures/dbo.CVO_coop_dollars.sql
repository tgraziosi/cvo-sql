SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================          
-- Author:  <Abraham M. Mtz>          
-- Create date: <Tuesday July, 2009>          
-- Description: <Co-Op Accumulations>   
/*
BEGIN TRAN
EXEC CVO_coop_dollars  1418656,0  
select * from CVO_armaster_all where customer_code = 'coop1'   
ROLLBACK
COMMIT
*/
-- v1.1 CB 12/15/2010 - Fix issue with coop dollars being sent when threshold not reached
--						This was due to an ISNULL missing
-- v1.2 CB 14/06/2012 - Move to posting routine and include credits
-- v1.3	CT 05/07/2012 - Calculate coop_ytd value
-- v1.4 CT 17/07/2012 - The figure for calculating Co-Op should be after discount has been applied
-- v1.5	CT 17/07/2012 - When recalculating coop from scratch, only use orders which are of the correct order category
-- v1.6 CT 17/10/2012 - When calculating if customer has reached coop threshold, only use orders which are of the correct order category
-- v1.7 CT 17/10/2012 - When recalculaing coop from scratch, write history for all valid orders
-- v1.8 CT 17/10/2012 - When deciding if history exists for a customer, use the customer code when checking coop history table
-- v1.9 CT 17/10/2012 - Check order status when processing an additional order
-- v2.0 CT 17/10/2012 - When recalculating coop from scratch, include orders in historic orders table
-- v2.1	CT 22/10/2012 - When recalculating coop from scratch, use invoice date for coop history table
-- v2.2 CT 24/10/2012 - If customer does not reach threshold, this may be because a credit has dropped them beneath it, if so reset coop_dollars and coop history
-- v2.3	CT 25/02/2013 - Coop values no longer updated within Enterprise
-- =============================================          
          
CREATE PROCEDURE [dbo].[CVO_coop_dollars]
  (@order_no  int, @ext   int)          
            
AS            
BEGIN

SET NOCOUNT ON

	declare @coop_eligible varchar(8), 
			@coop_threshold_flag char(1), 
			@coop_threshold_amount decimal(20,8), 
			@coop_dollars decimal(20,8), 
			@coop_notes varchar(255), 
			@coop_cust_rate_flag char(1), 
			@coop_cust_rate int, 

			@coop_general_rate DECIMAL(20,8), 
			@coop_general_account varchar(40),
			@coop_general_minsales DECIMAL(20,8),

			@order_category	varchar(40),
			@user_category varchar(40),
			@status CHAR(1), -- v1.9

			@rate_for_use	DECIMAL(20,8),
			@minsales_for_use	decimal(20,8),
			@cust_code varchar(10),
			@coop_dollars_amount decimal(20,8),
			@customer_code	VARCHAR(10),

			--Cursor Variables
			@order_no_cur	int, 
			@ext_cur	int, 
			@total_amt_order_cur decimal(20,8),
			@coop_points_calculated	decimal(20,8),
			@coop_date	datetime,
			@coop_percentage	decimal(20,8)
			
	DECLARE	@order_type	char(1), -- v1.2
			@coop_ytd	DECIMAL(20,8) -- v1.3

	-- START v1.6
	DECLARE @total_sales DECIMAL(20,8),    
			@total_sales_hist DECIMAL(20,8)  
	-- END v1.6

	-- START v2.3
	RETURN
	-- END v2.3

	--Get all the values from tables into the variables at the customer level
	SELECT @coop_eligible = ISNULL(t.coop_eligible, ''), 
		   @coop_threshold_flag = ISNULL(t.coop_threshold_flag, ''), 
		   @coop_threshold_amount = ISNULL(t.coop_threshold_amount, 0), 
		   @coop_dollars = t.coop_dollars,
		   @coop_notes = ISNULL(t.coop_notes, ''), 
		   @coop_cust_rate_flag = ISNULL(t.coop_cust_rate_flag, ''), 
		   @coop_cust_rate = ISNULL(t.coop_cust_rate, 0),
		   @user_category = ISNULL(o.user_category, 'N'), --FROM ORDERS
		   @cust_code = o.cust_code, --FROM ORDERS
		   @order_type = o.type, -- v1.2.1 I = order C = credit
		   @status = o.[status] -- v1.9
	FROM CVO_armaster_all t (NOLOCK)
	inner join orders o (NOLOCK)
	ON		t.customer_code = o.cust_code
	WHERE	o.order_no = @order_no AND
			o.ext = @ext AND
			t.address_type = 0

	--Get the values from tables into variables at application level
	select @coop_general_account = ISNULL(value_str, '') from config (NOLOCK) where flag = 'COOP_ACCOUNT'
	select @coop_general_minsales = CAST(ISNULL(value_str, '0') as DECIMAL(20,8))  from config (NOLOCK) where flag = 'COOP_MINSALES'
	select @coop_general_rate = CAST(ISNULL(value_str, '0') as DECIMAL(20,8)) from config (NOLOCK) where flag = 'COOP_RATE' 


--***********Validations*******************************************************************
	-- 1st - Check if the customer is coop eligible or not -------------------
	if @coop_eligible <> 'Y'
		begin
			-- v1.2 select 1, 'ok'  --It's not a customer coop eligible v1.0
			return
		end

	-- AMENDEZ, Verify the threshold amount
	-- 2nd and 3rd - Check if the threshold is assigned	----------
	if @coop_threshold_flag = 'Y'  --Then its by customer level
	BEGIN
		IF @coop_threshold_amount = 0
		BEGIN
			IF @coop_general_minsales = 0
			BEGIN
				-- v1.2 select 1, 'ok' 	--It's not a threshold amount configured in customer level neither application level
				return
			END
			ELSE
			BEGIN
				SELECT @minsales_for_use = @coop_general_minsales
			END
		END
		ELSE
		BEGIN
			SELECT @minsales_for_use = @coop_threshold_amount
		END
	END
	ELSE	--It's by application level
	BEGIN
		IF @coop_general_minsales = 0
		BEGIN
			-- v1.2 select 1, 'ok' 	--It's not a threshold amount configurated at application level
			return
		END
		ELSE
		BEGIN
			SELECT @minsales_for_use = @coop_general_minsales
		END
	END
	  
	-- AMENDEZ, Verify the rate porcentage
	-- 2nd and 3rd - Check if the Rate is assigned	----------
	IF @coop_cust_rate = 0
	BEGIN
		IF @coop_general_rate = 0
		BEGIN
			-- v1.2 select 1, 'ok' 	--It's not a Rate configured in customer level neither application level
			return
		END
		ELSE
		BEGIN
			SELECT @rate_for_use = @coop_general_rate
		END
	END
	ELSE
	BEGIN
		SELECT @rate_for_use = @coop_cust_rate
	END

	-- 4th Check for the order type existence in the coop order type table -if it is there is eligible
	SELECT @order_category = category_eligible	from CVO_order_types (NOLOCK) where order_category = @user_category

	-- v1.2.1 If credit then the user_category can either from the order it was applied to or blank
	-- If applied then let it go through or if blank then force it through
	IF UPPER(@order_type) = 'C'
	BEGIN
		IF ISNULL(@order_category, '') = ''
			SET @order_category = 'OK'
	END

	if @order_category = 'N' OR ISNULL(@order_category, '') = ''
	begin
		-- v1.2 select 1, 'ok'  --It's not a order type eligible
		return
	end

	--Check if the customer reach the Rate Sales of the year 

-- TLM : Fix / Calculate Min Sales as Invoiced Orders Only
		-- v1.2.1 Add in credits, the values are all positive so need to switch them
	    -- v1.2.1 if ISNULL((select sum(gross_sales) from orders (NOLOCK)	
		--if ISNULL((select sum(CASE WHEN type = 'C' THEN (gross_sales * -1) ELSE gross_sales END) from orders (NOLOCK)													-- TLM : Fix
		
		-- START v1.6 - only look at vlaid order types. Also including figures from historic orders
		SELECT 
			@total_sales = SUM(CASE WHEN type = 'C' THEN ((ISNULL(gross_sales,0) - ISNULL(total_discount,0)) * -1) ELSE ISNULL(gross_sales,0) - ISNULL(total_discount,0) END) 
		FROM 
			dbo.orders_all orders (NOLOCK)	-- v1.4												-- TLM : Fix
		WHERE 
			cust_code = @cust_code  
			AND orders.status > 'S' 
			AND orders.status <> 'V'												-- TLM : Fix  
			AND orders.invoice_date	BETWEEN (SELECT DATEADD(yy, DATEDIFF(yy,0,getdate()), 0)) AND  (SELECT dateadd(year, 1, dateadd(ms,-3,DATEADD(yy, DATEDIFF(yy,0,getdate() ), 0))))
			AND ((orders.user_category IN (SELECT order_category FROM CVO_order_types WHERE category_eligible = 'Y')) OR (orders.[type] = 'C'))
		
		SELECT 
			@total_sales_hist = SUM(CASE WHEN type = 'C' THEN ((ISNULL(total_amt_order,0) - ISNULL(tot_ord_disc,0)) * -1) ELSE ISNULL(total_amt_order,0) - ISNULL(tot_ord_disc,0) END) 
		FROM 
			dbo.cvo_orders_all_hist orders (NOLOCK)	-- v1.4												
		WHERE 
			cust_code = @cust_code  
			AND orders.status > 'S' 
			AND orders.status <> 'V'												-- TLM : Fix  
			AND orders.invoice_date	BETWEEN (SELECT DATEADD(yy, DATEDIFF(yy,0,getdate()), 0)) AND  (SELECT dateadd(year, 1, dateadd(ms,-3,DATEADD(yy, DATEDIFF(yy,0,getdate() ), 0))))
			AND ((orders.user_category IN (SELECT order_category FROM CVO_order_types WHERE category_eligible = 'Y')) OR (orders.[type] = 'C'))

		SET @total_sales = ISNULL(@total_sales,0) + ISNULL(@total_sales_hist,0)
		/*
		IF ISNULL((select sum(CASE WHEN type = 'C' THEN ((ISNULL(gross_sales,0) - ISNULL(total_discount,0)) * -1) ELSE ISNULL(gross_sales,0) - ISNULL(total_discount,0) END) from orders (NOLOCK)	-- v1.4												-- TLM : Fix
	   where cust_code = @cust_code  
	   and orders.status > 'S' and orders.status <> 'V'												-- TLM : Fix  
	   and orders.invoice_date																		-- TLM : Fix   
	   between (SELECT DATEADD(yy, DATEDIFF(yy,0,getdate()), 0))   
	   and  (SELECT dateadd(year, 1, dateadd(ms,-3,DATEADD(yy, DATEDIFF(yy,0,getdate() ), 0))))
		),0) < @minsales_for_use
		*/

		IF @total_sales < @minsales_for_use
		-- END v1.6
		BEGIN
			-- v1.2 select 1, 'ok'  --Do not meet the threshold
			
			-- START v1.3 
			-- Calculate the coop ytd for the year
			SELECT @coop_ytd = dbo.f_calculate_coop_ytd (@cust_code,0,0)

			UPDATE 
				cvo_armaster_all 
			SET 
				coop_ytd = @coop_ytd,
				coop_dollars = 0 -- v2.2
			WHERE 
				customer_code = @cust_code 
				AND address_type = 0
			-- END v1.3

			-- START v2.2
			DELETE FROM
				dbo.cvo_coop_dollars_history
			WHERE
				coop_date between (SELECT DATEADD(yy, DATEDIFF(yy,0,getdate()), 0))
				and  (SELECT dateadd(year, 1, dateadd(ms,-3,DATEADD(yy, DATEDIFF(yy,0,getdate() ), 0))))  
				AND customer_code = @cust_code
			-- END v2.2

			return
		end

--***********End Validations****************************************************************??


	select @coop_date = getdate()	
	

	--Sum acoumulated points only the first time of the year when there are not points in the history table for that year
	IF not EXISTS(select 1 from cvo_coop_dollars_history (NOLOCK)
	where coop_date between (SELECT DATEADD(yy, DATEDIFF(yy,0,getdate()), 0))
	and  (SELECT dateadd(year, 1, dateadd(ms,-3,DATEADD(yy, DATEDIFF(yy,0,getdate() ), 0))))  
	AND customer_code = @cust_code) -- v1.8
	BEGIN
			--For each order of the current year calculate the coop dollars
			select @coop_dollars_amount = 0

			DECLARE coop_order CURSOR FOR
					select	
						order_no, 
						ext, 
						--ISNULL(CASE WHEN type = 'C' THEN (gross_sales * -1) ELSE gross_sales END,0) -- v1.2.1										-- TLM : Fix
						ISNULL(CASE WHEN type = 'C' THEN ((ISNULL(gross_sales,0) - ISNULL(total_discount,0)) * -1) ELSE ISNULL(gross_sales,0) - ISNULL(total_discount,0) END,0), -- v1.4
						ISNULL(invoice_date,date_shipped) -- v2.1
					from orders (NOLOCK)
					where cust_code = @cust_code
					--and status in ('t')
					AND ((orders.user_category IN (SELECT order_category FROM CVO_order_types WHERE category_eligible = 'Y')) OR (orders.[type] = 'C'))	-- v1.5
					and orders.invoice_date   										-- TLM : Fix
					between (SELECT DATEADD(yy, DATEDIFF(yy,0,getdate()), 0))   
					and  (SELECT dateadd(year, 1, dateadd(ms,-3,DATEADD(yy, DATEDIFF(yy,0,getdate() ), 0)))) 
					-- START v2.0
					UNION
					select	
						order_no, 
						ext, 
						--ISNULL(CASE WHEN type = 'C' THEN (gross_sales * -1) ELSE gross_sales END,0) -- v1.2.1										-- TLM : Fix
						ISNULL(CASE WHEN type = 'C' THEN ((ISNULL(total_amt_order,0) - ISNULL(tot_ord_disc,0)) * -1) ELSE ISNULL(total_amt_order,0) - ISNULL(tot_ord_disc,0) END,0), -- v1.4
						ISNULL(invoice_date,date_shipped) -- v2.1
					from cvo_orders_all_hist (NOLOCK)
					where cust_code = @cust_code
					--and status in ('t')
					AND ((user_category IN (SELECT order_category FROM CVO_order_types WHERE category_eligible = 'Y')) OR ([type] = 'C'))	-- v1.5
					and invoice_date   										-- TLM : Fix
					between (SELECT DATEADD(yy, DATEDIFF(yy,0,getdate()), 0))   
					and  (SELECT dateadd(year, 1, dateadd(ms,-3,DATEADD(yy, DATEDIFF(yy,0,getdate() ), 0))))
					-- END v2.0

			OPEN coop_order          
			FETCH NEXT FROM coop_order         
			INTO  @order_no_cur, 
				  @ext_cur, 
				  @total_amt_order_cur,
				  @coop_date -- v2.1      
		              
			  WHILE @@FETCH_STATUS = 0 
			  BEGIN     
			  
				set @coop_percentage = @rate_for_use / cast(100 as decimal(20,8))
				set @coop_points_calculated =  ROUND(@total_amt_order_cur  * @coop_percentage,2)

				SET @coop_dollars_amount = @coop_dollars_amount + @coop_points_calculated 

				-- START v1.7 - write for each order
				------------- Insert into the history table ----------------------
				INSERT cvo_coop_dollars_history(order_no, order_ext, coop_dollars, coop_date, customer_code)
				VALUES(@order_no_cur, @ext_cur, @coop_points_calculated, @coop_date, @cust_code)
				------------- End Insert into the history table ----------------------
				-- END v1.7
		     
				FETCH NEXT FROM coop_order          
				INTO  @order_no_cur, 
					  @ext_cur, 
					  @total_amt_order_cur,
					  @coop_date -- v2.1                 
			  END          

			 CLOSE coop_order
			 DEALLOCATE coop_order

			-- START v1.7 - not required, this is already held in @cust_code
			/*
			/*START: 10/07/2010, AMENDEZ, Adding customer code to history table*/
			SELECT	@customer_code = cust_code
			FROM	orders_all (NOLOCK)
			WHERE	order_no = @order_no AND ext = @ext
			*/
			-- END v1.7

			-- START v1.7 - move this code up so it's valid for all orders in the cursor
			/*
			------------- Insert into the history table ----------------------
			INSERT cvo_coop_dollars_history(order_no, order_ext, coop_dollars, coop_date, customer_code)
			VALUES(@order_no, @ext, @coop_dollars_amount, @coop_date, @customer_code)
			------------- End Insert into the history table ----------------------
			/*END: 10/07/2010, AMENDEZ, Adding customer code to history table*/
			*/
			-- END v1.7

			-- START v1.3 
			-- Calculate the coop ytd for the year
			SELECT @coop_ytd = dbo.f_calculate_coop_ytd (@cust_code,0,0)
			
			------------- Insert into the coop table ----------------------
			UPDATE 
				cvo_armaster_all 
			SET 
				coop_dollars = @coop_dollars_amount,
				coop_ytd = @coop_ytd
			WHERE 
				customer_code = @cust_code 
				AND address_type = 0
			------------- End Insert into the coop table ----------------------
			-- END v1.3

			-- v1.2 select 1, 'ok' 
			return

	END
	--End Sum acoumulated points only the first time of the year when there are not points in the history table for that year

	ELSE	--If there are already coop_dollars for the current year in the history table
			--Only calculate the points for the current sales orders shipped
		BEGIN
			-- v1.9
			IF @status > 'S' AND @status <> 'V'
			BEGIN

				--select	@total_amt_order_cur = ISNULL(CASE WHEN type = 'C' THEN (gross_sales * -1) ELSE gross_sales END,0) -- v1.2.1
				SELECT	@total_amt_order_cur = ISNULL(CASE WHEN type = 'C' THEN ((ISNULL(gross_sales,0) - ISNULL(total_discount,0)) * -1) ELSE ISNULL(gross_sales,0) - ISNULL(total_discount,0) END,0) -- v1.4
				from orders (NOLOCK) where order_no = @order_no  and ext =  @ext
				AND orders.status > 'S' AND orders.status <> 'V'	-- v1.9

				set @coop_percentage = @rate_for_use / cast(100 as decimal(20,8))
				
				set @coop_points_calculated =  ROUND(@total_amt_order_cur * @coop_percentage,2)

				DELETE cvo_coop_dollars_history WHERE order_no = @order_no and order_ext = @ext

				/*START: 10/07/2010, AMENDEZ, Adding customer code to history table*/
				SELECT	@customer_code = cust_code
				FROM	orders_all (NOLOCK)
				WHERE	order_no = @order_no AND ext = @ext

				------------- Insert into the history table ----------------------
				INSERT cvo_coop_dollars_history(order_no, order_ext, coop_dollars, coop_date, customer_code)
				VALUES(@order_no, @ext, @coop_points_calculated, @coop_date, @customer_code)
				------------- End Insert into the history table ----------------------

				/*END: 10/07/2010, AMENDEZ, Adding customer code to history table*/

				-- START v1.3 
				-- Calculate the coop ytd for the year
				SELECT @coop_ytd = dbo.f_calculate_coop_ytd (@customer_code,@order_no,@ext)
				
				------------- Insert into the coop table ----------------------
				UPDATE 
					cvo_armaster_all 
				SET 
					coop_dollars = coop_dollars + @coop_points_calculated ,
					coop_ytd = @coop_ytd
				WHERE 
					customer_code = @cust_code 
					and address_type = 0
				------------- End Insert into the coop table ----------------------
				-- END v1.3
			END -- v1.9
			-- v1.2 select 1, 'ok'
			return
		END

END

GO
GRANT EXECUTE ON  [dbo].[CVO_coop_dollars] TO [public]
GO
