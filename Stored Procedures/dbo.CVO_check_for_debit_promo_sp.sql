SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
v1.0 CT 07/08/2013 - Created
v1.1 CT 08/11/2013 - Fixed bug which was returning last promo checked as being valid if no promos were valid
*/
CREATE PROCEDURE [dbo].[CVO_check_for_debit_promo_sp]	@customer_code VARCHAR(8), 
														@order_no INT, 
														@ext INT, 
														@order_type VARCHAR(10)
AS
BEGIN

	DECLARE @date_entered			DATETIME,
			@spid					INT,
			@rec_key				INT,
			@promo_id				VARCHAR(20),
			@promo_level			VARCHAR(30),
			@ret_val				SMALLINT,
			@valid					SMALLINT,
			@current_promo_id		VARCHAR(20), 
			@current_promo_level	VARCHAR(30)
			
			

	SELECT @spid = @@SPID 

	CREATE TABLE #promos(
		rec_key INT IDENTITY(1,1),
		promo_id VARCHAR(20),
		promo_level VARCHAR(30),
		valid SMALLINT)
	
	-- Get date the order was created
	IF @order_no = 0
	BEGIN
		SET @date_entered = GETDATE()
	END
	ELSE
	BEGIN
		SELECT 
			@date_entered = date_entered
		FROM
			dbo.orders (NOLOCK)
		WHERE
			order_no = @order_no
			AND ext = @ext
	END

	-- Get date part of date entered
	SET @date_entered = DATEADD(dd, 0, DATEDIFF(dd, 0, @date_entered))

	-- Get drawdown promos the customer is enrolled on
	INSERT #promos(
		promo_id,
		promo_level,
		valid)
	SELECT
		drawdown_promo_id,
		drawdown_promo_level,
		0
	FROM
		dbo.CVO_debit_promo_customer_hdr a (NOLOCK)
	WHERE
		customer_code = @customer_code
		AND available > 0
		AND [start_date] <= @date_entered
		AND [expiry_date] >= @date_entered 
	ORDER BY
		hdr_rec_id

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

				
		-- Check if order is a valid order type
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
	
		-- Check if order qualifies	
		IF @valid = 1
		BEGIN
			IF @order_no <> 0 
			BEGIN
				EXEC @ret_val = CVO_verify_order_quali_sp	@order_no, @ext, @promo_id,	@promo_level, @customer_code, 1
			END
			ELSE
			BEGIN
				EXEC @ret_val = CVO_verify_order_quali_sp	@spid, -1, @promo_id,	@promo_level, @customer_code, 1
			END

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
	
	IF @order_no <> 0 
	BEGIN
		DELETE FROM CVO_ord_list_temp WHERE order_no = @order_no AND order_ext = @ext
	END
	ELSE
	BEGIN
		DELETE FROM CVO_ord_list_temp WHERE order_no = @spid AND order_ext = -1
	END

	-- Does order currently have a promo applied
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

	-- START v1.1
	-- Clear out promo variables
	SET @promo_id = NULL
	SET @promo_level = NULL
	-- END v1.1

	-- Only return the first drawdown promo that is valid
	SELECT TOP 1
		@promo_id = promo_id,
		@promo_level = promo_level 
	FROM 
		#promos	
	WHERE 
		valid = 1
	ORDER BY
		rec_key

	-- Clear out qualified lines which aren't for the returned promo
	DELETE FROM dbo.CVO_drawdown_promo_qualified_lines WHERE SPID = @@SPID AND NOT (promo_id = @promo_id AND promo_level = @promo_level)

	SELECT
		@promo_id,
		@promo_level

END

-- Permissions
GO
GRANT EXECUTE ON  [dbo].[CVO_check_for_debit_promo_sp] TO [public]
GO
