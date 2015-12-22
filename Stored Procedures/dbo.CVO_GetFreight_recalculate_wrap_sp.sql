SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[CVO_GetFreight_recalculate_wrap_sp]	@order_no	int,
													@order_ext	int
AS
BEGIN
	-- Declarations
	DECLARE	@carrier	varchar(20)
	
	-- Call the freight calculation routine
	EXEC dbo.CVO_GetFreight_recalculate_sp @order_no, @order_ext, 1

	-- Check if any errors were raised 
	IF EXISTS (SELECT 1 FROM dbo.cvo_carrier_errors (NOLOCK) WHERE spid = @@spid AND order_no = @order_no AND order_ext = @order_ext) -- v1.1
	BEGIN
		-- The freight calculation failed due to value or weight 
		-- Force order to use UPS ground and call calculation again
		SELECT @carrier = LEFT(ISNULL(value_str,'UPSGR'),20) FROM dbo.tdc_config (NOLOCK) WHERE [function] = 'PWB_FORCE_CARRIER' -- v1.1
		IF (@carrier = '')
			SET @carrier = 'UPSGR'

		UPDATE	orders_all
		SET		routing = @carrier
		WHERE	order_no = @order_no
		AND		ext = @order_ext

		-- Call the freight calculation routine again
		EXEC dbo.CVO_GetFreight_recalculate_sp @order_no, @order_ext, 1

	END

END
GO
GRANT EXECUTE ON  [dbo].[CVO_GetFreight_recalculate_wrap_sp] TO [public]
GO
