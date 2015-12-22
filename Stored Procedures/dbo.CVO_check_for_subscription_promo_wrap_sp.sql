SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
v1.0 CT 02/07/2013 - Created



*/
CREATE PROCEDURE [dbo].[CVO_check_for_subscription_promo_wrap_sp]	@customer_code	VARCHAR(8), 
																@order_no		INT, 
																@ext			INT, 
																@order_type		VARCHAR(10), 
																@ship_to		VARCHAR(10),
																@promo_id		VARCHAR(20) OUTPUT,
																@promo_level	VARCHAR(30) OUTPUT
																  
AS
BEGIN
	
	SET NOCOUNT ON

	CREATE TABLE #promo(
		rec_count		INT,
		promo_id		VARCHAR(20),
		promo_level	VARCHAR(30))

	-- Load details into working tables
	IF NOT EXISTS (SELECT 1 FROM CVO_ord_list_temp WHERE order_no = @order_no and order_ext = @ext)
	BEGIN
		INSERT INTO CVO_ord_list_temp 
		select a.order_no, a.order_ext, a.part_no, a.ordered, b.is_pop_gif from ord_list a inner join
		cvo_ord_list b on a.order_no = b.order_no and a.order_ext = b.order_ext and a.line_no = b.line_no
		where a.order_no = @order_no and a.order_ext = @ext
	END


	INSERT INTO #promo EXEC dbo.CVO_check_for_subscription_promo_sp	@customer_code = @customer_code , 
																	@order_no = @order_no , 
																	@ext = @ext, 
																	@order_type = @order_type, 
																	@ship_to = @ship_to


	SELECT TOP 1
		@promo_id = promo_id,
		@promo_level = promo_level
	FROM
		#promo
	ORDER BY
		promo_id,
		promo_level


	

END

GO
GRANT EXECUTE ON  [dbo].[CVO_check_for_subscription_promo_wrap_sp] TO [public]
GO
