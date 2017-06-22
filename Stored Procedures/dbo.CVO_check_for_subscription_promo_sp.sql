SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
v1.0 CT 29/10/2012 - Created
V1.1 CT 15/10/2012 - Excluded voided promos
v1.2 CT 22/11/2012 - If the order already has a subscription promo on it (and it is still valid), only return it if more than 1 valid promos exist
v1.3 CT 08/02/2012 - Additional paramter of ship to, to be passed into customer qualification routine
v1.4 CT 08/02/2012 - If order number is zero, use SPID instead
v1.5 CT 01/03/2013 - Free frames logic
v1.6 CT 05/06/2013 - Issue #1304 - If customer has a primary designation code set, then only select subscription promos for that designation code
v1.7 CT 11/11/2013 - Issue #1412 - Check primary only setting when checking for designation code
v1.8 CB 13/06/2017 - #1593 - Designation Codes - Ship To	
*/
CREATE PROCEDURE [dbo].[CVO_check_for_subscription_promo_sp] @customer_code VARCHAR(8), 
															 @order_no INT, 
															 @ext INT, 
															 @order_type VARCHAR(10), 
															 @ship_to VARCHAR(10) -- v1.3
AS
BEGIN

	DECLARE @rec_key				INT,
			@promo_id				VARCHAR(20),
			@promo_level			VARCHAR(30),
			@ret_val				SMALLINT,
			@valid					SMALLINT,
			@count					INT,
			@current_promo_id		VARCHAR(20), -- v1.2
			@current_promo_level	VARCHAR(30), -- v1.2
			@spid					INT,		 -- v1.4
			@primary_code			VARCHAR(10),	 -- v1.6
			@ship_to_code			varchar(10), -- v1.8
			@useCustDC				varchar(10) -- v1.8

	SELECT @spid = @@SPID -- v1.4

	-- v1.8 Start
	SET @ship_to_code = @ship_to

	SET @useCustDC = 'Y'
	SELECT	@useCustDC = value_str
	FROM	dbo.config (NOLOCK)
	WHERE	flag = 'DESIGNATION CUST DEF'

	IF (@ship_to_code <> '')
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM cvo_cust_designation_codes a (NOLOCK) JOIN cvo_designation_codes b (NOLOCK)
				ON a.code = b.code WHERE b.void = 0 AND a.customer_code = @customer_code AND a.ship_to = @ship_to_code AND a.date_reqd = 1 
				AND (GETDATE() BETWEEN a.start_date AND ISNULL(a.end_date,'01 january 2999')))
		BEGIN
			IF (@useCustDC = 'Y')
				SET @ship_to_code = ''
		END
	END
	-- v1.8 End

	CREATE TABLE #promos(
		rec_key INT IDENTITY(1,1),
		promo_id VARCHAR(20),
		promo_level VARCHAR(30),
		valid SMALLINT) 
	
	-- START v1.7
	-- v1.6 no longer required
	/* 
	-- START v1.6
	SELECT 
		@primary_code = a.code 
	FROM 
		dbo.cvo_cust_designation_codes a (NOLOCK) 
	INNER JOIN  
		dbo.cvo_designation_codes b (NOLOCK)
	ON 
		a.code = b.code 
	WHERE 
		a.customer_code = @customer_code 
		AND (a.date_reqd = 0 OR (a.date_reqd = 1 AND a.start_date <= GETDATE() AND ISNULL(a.end_date,GETDATE()) >= GETDATE()))
		AND ISNULL(b.void,0) = 0	
		AND ISNULL(a.primary_flag,0) = 1 	

	-- If customer has a primary, only select on that
	IF ISNULL(@primary_code,'') <> ''
	BEGIN
		INSERT #promos(
			promo_id,
			promo_level,
			valid)
		SELECT
			promo_id,
			promo_level,
			0
		FROM
			dbo.cvo_promotions  (NOLOCK)
		WHERE
			ISNULL(void,'N') = 'N'	
			AND ISNULL(subscription,0) = 1
			AND promo_end_date >= GETDATE()
			AND ISNULL(designation_code,'') = @primary_code
		ORDER BY
			promo_id,
			promo_level
	END
	ELSE
	BEGIN
		-- No primary, get promos for all customer's designation codes
		INSERT #promos(
			promo_id,
			promo_level,
			valid)
		SELECT
			b.promo_id,
			b.promo_level,
			0
		FROM
			dbo.cvo_cust_designation_codes a (NOLOCK)
		INNER JOIN
			dbo.cvo_promotions b (NOLOCK)
		ON
			a.code = b.designation_code
		INNER JOIN
			dbo.cvo_designation_codes c (NOLOCK)
		ON
			a.code = c.code
		WHERE
			a.customer_code = @customer_code
			AND (a.date_reqd = 0 
				OR (a.date_reqd = 1 AND a.start_date <= GETDATE() AND ISNULL(a.end_date,GETDATE()) >= GETDATE()))
			AND ISNULL(c.void,0) = 0
			AND ISNULL(b.void,'N') = 'N'	-- v1.1
			AND ISNULL(b.subscription,0) = 1
			AND b.promo_end_date >= GETDATE()
			AND b.designation_code IS NOT NULL
		ORDER BY
			b.promo_id,
			b.promo_level
	END
	-- END v1.6
	*/
	-- Get promos for customer's designation codes
	-- If promo has primary only set to true then customer must have designation code as primary
	INSERT #promos(
		promo_id,
		promo_level,
		valid)
	SELECT
		b.promo_id,
		b.promo_level,
		0
	FROM
		dbo.cvo_cust_designation_codes a (NOLOCK)
	INNER JOIN
		dbo.cvo_promotions b (NOLOCK)
	ON
		a.code = b.designation_code
	INNER JOIN
		dbo.cvo_designation_codes c (NOLOCK)
	ON
		a.code = c.code
	WHERE
		a.customer_code = @customer_code
		AND a.ship_to = @ship_to_code -- v1.8
		AND (a.date_reqd = 0 
			OR (a.date_reqd = 1 AND a.start_date <= GETDATE() AND ISNULL(a.end_date,GETDATE()) >= GETDATE()))
		AND ISNULL(c.void,0) = 0
		AND ISNULL(b.void,'N') = 'N'	-- v1.1
		AND ISNULL(b.subscription,0) = 1
		AND b.promo_end_date >= GETDATE()
		AND b.designation_code IS NOT NULL
		AND ((ISNULL(b.subscription_designation_code_primary_only,0) = 0) OR (ISNULL(b.subscription_designation_code_primary_only,0) = 1 AND ISNULL(a.primary_flag,0) = 1))
	ORDER BY
		b.promo_id,
		b.promo_level
	-- END v1.7
	
	-- Loop through promos and check they are valid for order
	SET @rec_key = 0
	WHILE 1=1
	BEGIN
		SELECT TOP 1
			@rec_key = rec_key,
			@promo_id = promo_id,
			@promo_level = promo_level
		FROM
			#promos 
		WHERE
			rec_key > @rec_key
		ORDER BY
			rec_key

		IF @@ROWCOUNT = 0
			BREAK

		SET @valid = 1

		-- Check if customer qualifies
		EXEC @ret_val = [CVO_verify_customer_quali_sp]	@promo_id = @promo_id, 
														@promo_level = @promo_level, 
														@customer = @customer_code, 
														@order_no = @order_no, 
														@ext = @ext, 
														@sub_check = 1, 
														@ship_to = @ship_to -- v1.3

		IF @ret_val = 0
		BEGIN
			SET @valid = 0
		END
		
		-- Check if order is a valid order type
		IF @valid = 1
		BEGIN
			IF EXISTS(SELECT 1 FROM dbo.cvo_promotions (NOLOCK) WHERE promo_id = @promo_id AND promo_level = @promo_level AND ISNULL(order_type,0) = 1)
			BEGIN
				IF EXISTS (SELECT 1 FROM dbo.cvo_promotions_order_type (NOLOCK) WHERE promo_id = @promo_id AND promo_level = @promo_level)
				BEGIN
					IF NOT EXISTS (SELECT 1 FROM dbo.cvo_promotions_order_type (NOLOCK) WHERE promo_id = @promo_id AND promo_level = @promo_level AND order_type = @order_type)
					BEGIN
						SET @valid = 0
					END
				END
			END
		END
	
		-- Check if order qualifies	
		IF @valid = 1
		BEGIN
			-- START v1.4
			IF @order_no <> 0 
			BEGIN
				EXEC @ret_val = CVO_verify_order_quali_sp	@order_no, @ext, @promo_id,	@promo_level, @customer_code, 1
			END
			ELSE
			BEGIN
				EXEC @ret_val = CVO_verify_order_quali_sp	@spid, -1, @promo_id,	@promo_level, @customer_code, 1
			END
			-- END v1.4
			IF @ret_val = 0
			BEGIN
				SET @valid = 0
			END
	
		END
		
		IF @valid = 1
		BEGIN
			UPDATE
				#promos
			SET
				valid = 1
			WHERE 
				rec_key = @rec_key
		END
	END
	
	-- Remove order details from temp table
	-- START v1.4
	IF @order_no <> 0 
	BEGIN
		DELETE FROM CVO_ord_list_temp WHERE order_no = @order_no AND order_ext = @ext
	END
	ELSE
	BEGIN
		DELETE FROM CVO_ord_list_temp WHERE order_no = @spid AND order_ext = -1
	END

	-- START v1.2
	-- Does order currently have a subscription promo applied
	SELECT
		@current_promo_id = promo_id,
		@current_promo_level = promo_level
	FROM
		dbo.cvo_orders_all (NOLOCK)
	WHERE
		order_no = @order_no 
		and ext = @ext

	IF ISNULL(@current_promo_id,'') <> '' AND ISNULL(@current_promo_level,'') <> ''
	BEGIN
		IF EXISTS(SELECT 1 FROM #promos WHERE valid = 1 AND promo_id = @current_promo_id AND promo_level = @current_promo_level)
		BEGIN
			-- Mark other promos as not valid
			UPDATE
				#promos
			SET
				valid = 0
			WHERE
				NOT (promo_id = @current_promo_id AND promo_level = @current_promo_level)
		END

	END
	-- END v1.2

	SELECT @count = COUNT(1) FROM #promos WHERE valid = 1
	
	-- START v1.5
	-- If there are no qualifying promos clear down the table now as it won't be done in the client.
	IF ISNULL(@count,0) = 0
	BEGIN
		DELETE FROM dbo.CVO_free_frame_qualified WHERE SPID = @@SPID
	END
	-- END v1.5

	SELECT 
		@count rec_count,
		promo_id,
		promo_level 
	FROM 
		#promos	
	WHERE 
		valid = 1
	ORDER BY
		promo_id,
		promo_level 

END

-- Permissions
GO
GRANT EXECUTE ON  [dbo].[CVO_check_for_subscription_promo_sp] TO [public]
GO
