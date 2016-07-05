SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_process_calc_tax]
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARATIONS
	DECLARE @row_id				int,
			@last_row_id		int,
			@err_ret			int,
			@order_no			int,
			@order_ext			int,
			@consolidation_no	int, -- v1.2
			@carton_no			int -- v1.2

	-- Create Working Table
	CREATE TABLE #process_tax (
		row_id		int IDENTITY(1,1),
		order_no	int,
		order_ext	int, 
		cons_no		int NULL) -- v1.2

	-- Insert records to process
	INSERT	#process_tax (order_no, order_ext, cons_no) -- v1.2 Start
	SELECT	a.order_no, a.order_ext, b.consolidation_no
	FROM	dbo.cvo_calc_tax a (NOLOCK)
	LEFT JOIN cvo_masterpack_consolidation_det b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext -- v1.2 End

	-- Process the records
	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@order_no = order_no,
			@order_ext = order_ext,
			@consolidation_no = cons_no -- v1.2
	FROM	#process_tax
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

	WHILE (@@ROWCOUNT <> 0)
	BEGIN
		-- v1.2 Start
		IF (@consolidation_no IS NOT NULL)
		BEGIN
			SET @carton_no = 0

			SELECT	TOP 1 @carton_no = carton_no
			FROM	tdc_carton_tx (NOLOCK)
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
			AND		carton_no > @carton_no

			WHILE (1 = 1)
			BEGIN

				EXEC CVO_masterpack_consolidation_consolidated_shipping_sp @carton_no

				SELECT	TOP 1 @carton_no = carton_no
				FROM	tdc_carton_tx (NOLOCK)
				WHERE	order_no = @order_no
				AND		order_ext = @order_ext
				AND		carton_no > @carton_no

				IF (@@ROWCOUNT = 0)
					BREAK
			END

			DELETE	#process_tax
			WHERE	cons_no = @consolidation_no
		END
		ELSE
		BEGIN
			EXEC dbo.CVO_GetFreight_recalculate_sp	@order_no, @order_ext, 2 -- v1.1
		END
		-- v1.2 End

		EXEC dbo.fs_calculate_oetax @order_no, @order_ext, @err_ret OUT  
		EXEC dbo.fs_updordtots @order_no, @order_ext     

		DELETE dbo.cvo_calc_tax WHERE order_no = @order_no AND order_ext = @order_ext	

		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@order_no = order_no,
				@order_ext = order_ext,
				@consolidation_no = cons_no -- v1.2
		FROM	#process_tax
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC
	END	

	-- Clean up
	DROP TABLE #process_tax

END 
GO
GRANT EXECUTE ON  [dbo].[cvo_process_calc_tax] TO [public]
GO
