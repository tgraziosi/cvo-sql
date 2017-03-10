SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_recheck_fl_sc_sp] @order_no int, 
									@order_ext int,
									@who varchar(50)
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARATIONS
	DECLARE	@soft_alloc_no		int,
			@fill_rate			decimal(20,8),
			@fill_rate_level	decimal(20,8),
			@sc_flag			int,
			@hold_priority		int,
			@user_category		varchar(20)

	-- PROCESSING
	SELECT	@soft_alloc_no = soft_alloc_no
	FROM	cvo_soft_alloc_no_assign (NOLOCK)
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext

	SELECT	@sc_flag = back_ord_flag,
			@user_category = user_category
	FROM	orders_all (NOLOCK)
	WHERE	order_no = @order_no
	AND		ext = @order_ext

	SELECT	@fill_rate_level = CAST(value_str as decimal(20,8))
	FROM	dbo.config (NOLOCK) 
	WHERE	flag = 'ST_ORDER_FILL_RATE'

	SET @fill_rate = -1
	EXEC dbo.cvo_order_summary_sp @soft_alloc_no, @order_no, @order_ext, 1, NULL, @fill_rate OUTPUT 

	IF (@fill_rate < 100 AND @sc_flag = 1) -- Ship Complete
	BEGIN
		SELECT	@hold_priority = dbo.f_get_hold_priority('SC','')
		IF NOT EXISTS (SELECT 1 FROM cvo_so_holds (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND hold_reason = 'SC')
		BEGIN
			INSERT	dbo.cvo_so_holds (order_no, order_ext, hold_reason, hold_priority, hold_user, hold_date)
			SELECT	@order_no, @order_ext, 'SC', @hold_priority, @who, GETDATE()
		END
	END

	IF ((@fill_rate < @fill_rate_level AND @sc_flag <> 1) AND LEFT(@user_category,2) = 'ST')
	BEGIN
		SELECT	@hold_priority = dbo.f_get_hold_priority('FL','')
		IF NOT EXISTS (SELECT 1 FROM cvo_so_holds (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND hold_reason = 'SC')
		BEGIN
			INSERT	dbo.cvo_so_holds (order_no, order_ext, hold_reason, hold_priority, hold_user, hold_date)
			SELECT	@order_no, @order_ext, 'FL', @hold_priority, @who, GETDATE()
		END
	END

END
GO
GRANT EXECUTE ON  [dbo].[cvo_recheck_fl_sc_sp] TO [public]
GO
