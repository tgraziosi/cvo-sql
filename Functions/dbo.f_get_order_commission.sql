SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[f_get_order_commission](@order_no int, @order_ext int)
RETURNS decimal (5,2)
AS
BEGIN
	DECLARE @use_commission smallint,
			@commission decimal (20,8),
			@promo_id varchar(20),
			@promo_level varchar(30),
			@cust_code varchar(10),
			@salesperson varchar(10),
			@price_code varchar(8),
			@commission_override int, -- v1.1 
			@commission_set decimal(20,8) -- v1.1

	-- Get information we need to do this
	SELECT
		@promo_id = b.promo_id,
		@promo_level = b.promo_level,
		@cust_code = a.cust_code,
		@salesperson = a.salesperson,
		@price_code = c.price_code,
		@commission_override = ISNULL(b.commission_override,0), -- v1.1
		@commission_set = ISNULL(commission_pct,0) -- v1.1
	FROM
		dbo.orders_all a (NOLOCK)
	INNER JOIN
		dbo.cvo_orders_all b (NOLOCK)
	ON
		a.order_no = b.order_no
		AND a.ext = b.ext 
	INNER JOIN
		dbo.armaster_all c (NOLOCK)
	ON
		a.cust_code = c.customer_code
	WHERE
		a.order_no = @order_no
		AND a.ext = @order_ext
		AND c.address_type = 0

	-- v1.1 Start - If commission_override flag set then return the commission_pct already set
	IF (@commission_override = 1)
	BEGIN
		SET	@commission = @commission_set
		RETURN @commission
	END
	-- v1.1 End

	-- 1.CHECK FOR PROMOTION LEVEL COMMISSION
	IF (ISNULL(@promo_id,'') <> '') AND (ISNULL(@promo_level,'') <> '') 
	BEGIN
		SELECT  @use_commission = 0,
				@commission = 0

		SELECT 
			@use_commission = commissionable,
			@commission = ROUND(commission,2)
		FROM
			dbo.cvo_promotions (NOLOCK)
		WHERE
			promo_id = @promo_id
			AND promo_level = @promo_level

		IF (ISNULL(@use_commission,0) = 1) AND (@commission IS NOT NULL)
		BEGIN
			RETURN @commission
		END
	END

	-- 2.CHECK FOR CUSTOMER LEVEL COMMISSION
	IF (ISNULL(@cust_code,'') <> '') 
	BEGIN
		SELECT  @use_commission = 0,
				@commission = 0

		SELECT 
			@use_commission = commissionable,
			@commission = commission
		FROM
			dbo.cvo_armaster_all (NOLOCK)
		WHERE
			customer_code = @cust_code
			AND address_type = 0

		IF (ISNULL(@use_commission,0) = 1) AND (@commission IS NOT NULL)
		BEGIN
			RETURN @commission
		END
	END

	-- 3.CHECK FOR SALESPERSON LEVEL COMMISSION
	IF (ISNULL(@salesperson,'') <> '') 
	BEGIN
		SELECT  @use_commission = 0,
				@commission = 0

		SELECT 
			@use_commission = escalated_commissions,
			@commission = commission
		FROM
			dbo.arsalesp (NOLOCK)
		WHERE
			salesperson_code = @salesperson

		IF (ISNULL(@use_commission,0) = 1) AND (@commission IS NOT NULL)
		BEGIN
			RETURN @commission
		END
	END

	-- 4.CHECK FOR PRICE CLASS LEVEL COMMISSION
	IF (ISNULL(@price_code,'') <> '') 
	BEGIN
		SELECT @commission = 0

		SELECT 
			@commission = commission_pct
		FROM
			dbo.cvo_comm_pclass (NOLOCK)
		WHERE
			price_code = @price_code

		IF @commission IS NOT NULL
		BEGIN
			RETURN @commission
		END
	END

	-- No commission found - return 0
	RETURN 0
END
GO
