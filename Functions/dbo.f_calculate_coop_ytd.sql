SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
Copyright (c) 2012 Epicor Software (UK) Ltd
Name:			f_calculate_coop_ytd		
Project ID:		Issue 721
Type:			Function
Description:	Calculates Co-op year to date for the customer passed in.
				If order details are passed in the adds to current value,
				If order_no = 0 then it recalculates for the entire year.
Developer:		Chris Tyler

History
-------
v1.0	05/07/12	CT	Original version
v1.1	17/07/12	CT	The figure for calculating Co-Op should be after discount has been applied
v1.2 -  7/23/12 - tag - add history tables

-- SELECT dbo.f_calculate_coop_ytd ('043337',0,0) 

*/

CREATE FUNCTION [dbo].[f_calculate_coop_ytd] (@customer_code VARCHAR(8),@order_no INT, @ext INT) 
RETURNS DECIMAL(20,8)
AS
BEGIN
	-- Declarations
	DECLARE @coop_ytd			DECIMAL (20,8),
			@current_coop_ytd	DECIMAL (20,8),
			@total_order_amt	DECIMAL (20,8),
			@total_credit_amt	DECIMAL (20,8),
			@order_amt			DECIMAL (20,8),
			@order_type			CHAR(1),
			@user_category		VARCHAR(10),
			@add_order_amt		SMALLINT,
			@startdate			DATETIME,
			@enddate			DATETIME

	declare @total_order_amt_hist decimal(20,8),
			@total_credit_amt_hist decimal(20,8)

	-- Check if customer is coop eligible, if not return NULL
	IF NOT EXISTS (SELECT 1 FROM dbo.cvo_armaster_all (NOLOCK) WHERE customer_code = @customer_code AND address_type = 0 AND ISNULL(coop_eligible,'N') = 'Y')
	BEGIN
		RETURN @coop_ytd
	END 

	-- Calculate year start and end
	SET @startdate = DATEADD(yy, DATEDIFF(yy,0,getdate()), 0)
	SET @enddate = DATEADD(year, 1, dateadd(ms,-3,DATEADD(yy, DATEDIFF(yy,0,getdate() ), 0)))

	-- If order_no is 0 then recalculate the entire year
	IF @order_no = 0
	BEGIN
		-- Get eligibale sales orders
		SELECT 
			@total_order_amt = SUM(ISNULL(a.gross_sales,0)- ISNULL(a.total_discount,0))	-- v1.1
		FROM 
			dbo.orders_all a (NOLOCK)
		INNER JOIN
			dbo.CVO_order_types b (NOLOCK)
		ON
			a.user_category = b.order_category
		WHERE
			a.cust_code = @customer_code
			AND a.[type] = 'I'
			AND a.user_category IN (SELECT order_category FROM CVO_order_types WHERE category_eligible = 'Y') -- v1.1
			AND a.status > 'S' 
			AND a.status <> 'V'	
			AND a.invoice_date BETWEEN @startdate AND @enddate 
			AND b.category_eligible = 'Y'

		-- v1.2 - Get eligibale sales orders from History table
		SELECT 
			@total_order_amt_hist = SUM(ISNULL(a.total_amt_order,0)- ISNULL(a.tot_ord_disc,0))	-- v1.1
		FROM 
			dbo.cvo_orders_all_hist a (NOLOCK)
		INNER JOIN
			dbo.CVO_order_types b (NOLOCK)
		ON
			a.user_category = b.order_category
		WHERE
			a.cust_code = @customer_code
			AND a.[type] = 'I'
			AND a.user_category IN (SELECT order_category FROM CVO_order_types WHERE category_eligible = 'Y') -- v1.1
			AND a.status > 'S' 
			AND a.status <> 'V'	
			AND a.invoice_date >= @startdate
			AND b.category_eligible = 'Y'

		-- Get eligibale credit returns
		SELECT 
			@total_credit_amt = SUM(ISNULL(gross_sales,0)- ISNULL(total_discount,0)) * -1	-- v1.1
		FROM 
			dbo.orders_all (NOLOCK)
		WHERE
			cust_code = @customer_code
			AND [type] = 'C'
			AND [status] > 'S' 
			AND [status] <> 'V'	
			AND invoice_date BETWEEN @startdate AND @enddate 
		
		-- v1.2 - tag - Get eligibale credit returns from hsistory
		SELECT 
			@total_credit_amt_hist = SUM(ISNULL(total_amt_order,0)- ISNULL(tot_ord_disc,0)) * -1	-- v1.1
		FROM 
			dbo.cvo_orders_all_hist (NOLOCK)
		WHERE
			cust_code = @customer_code
			AND [type] = 'C'
			AND [status] > 'S' 
			AND [status] <> 'V'	
			AND invoice_date >= @startdate
	
		SET @coop_ytd = ISNULL(@total_order_amt,0) + ISNULL(@total_credit_amt,0)
				+ ISNULL(@total_order_amt_hist,0) + ISNULL(@total_credit_amt_hist,0)

		RETURN @coop_ytd

	END
	ELSE
	BEGIN	-- Add this order to current value
		
		SET @add_order_amt = 0	-- False

		-- Get current value
		SELECT
			@current_coop_ytd = coop_ytd
		FROM
			dbo.cvo_armaster_all (NOLOCK) 
		WHERE 
			customer_code = @customer_code
			AND address_type = 0

		-- Get order details
		SELECT
			@user_category = user_category,
			@order_type = [type],
			--@order_amt = ISNULL(CASE WHEN type = 'C' THEN (gross_sales * -1) ELSE gross_sales END,0)
			@order_amt = ISNULL(CASE WHEN type = 'C' THEN ((ISNULL(gross_sales,0) - ISNULL(total_discount,0)) * -1) ELSE ISNULL(gross_sales,0) - ISNULL(total_discount,0) END,0)	-- v1.1
		FROM
			dbo.orders_all (NOLOCK)
		WHERE
			order_no = @order_no
			AND ext = @ext
			AND cust_code = @customer_code
			AND invoice_date BETWEEN @startdate AND @enddate
			
		-- If we have returned a value 
		IF ISNULL(@order_amt,0) <> 0
		BEGIN
			-- Check order type 
			IF @order_type = 'I'
			BEGIN
				-- Sales order - check user category
				IF EXISTS (SELECT 1 FROM dbo.CVO_order_types (NOLOCK) WHERE order_category = @user_category AND category_eligible = 'Y')
				BEGIN
					SET @add_order_amt = 1
				END
			END
			ELSE
			BEGIN
				-- Credit return - add value
				SET @add_order_amt = 1
			END
			
		END
		

		IF @add_order_amt = 0
		BEGIN
			SET @coop_ytd = ISNULL(@current_coop_ytd,0)
		END
		ELSE
		BEGIN
			SET @coop_ytd = ISNULL(@current_coop_ytd,0) + ISNULL(@order_amt,0)
		END
				
		RETURN @coop_ytd			
	END
	
	RETURN @coop_ytd

END
GO
GRANT REFERENCES ON  [dbo].[f_calculate_coop_ytd] TO [public]
GO
GRANT EXECUTE ON  [dbo].[f_calculate_coop_ytd] TO [public]
GO
