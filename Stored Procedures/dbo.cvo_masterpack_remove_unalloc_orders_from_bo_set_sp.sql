SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0 CT 10/04/2014 - Issue #572 - Process unallocations to remove them from BO consolidation sets
-- v1.1 CB 11/07/2014 - Add in missing temp table

CREATE PROC [dbo].[cvo_masterpack_remove_unalloc_orders_from_bo_set_sp]
AS
BEGIN
	DECLARE @rec_id				INT,
			@order_no			INT,
			@ext				INT,
			@consolidation_no	INT

	-- Create working tables
	CREATE TABLE #unalloc_orders (
		rec_id				INT IDENTITY (1,1),
		order_no			INT,
		ext					INT,
		consolidation_no	INT)

	-- v1.1 Start
	IF OBJECT_ID('tempdb..#consolidate_picks') IS NULL
	BEGIN
		 CREATE TABLE #consolidate_picks(  
		  consolidation_no INT,  
		  order_no   INT,  
		  ext     INT)  
	END
	-- v1.1 End

	-- Get unalloc records for BO consolidation sets
	INSERT INTO #unalloc_orders(
		order_no,
		ext,
		consolidation_no)
	SELECT DISTINCT
		order_no,
		order_ext,
		mp_consolidation_no
	FROM 
		#so_alloc_management a 
	INNER JOIN 
		dbo.cvo_masterpack_consolidation_hdr b (NOLOCK)
	ON 
		a.mp_consolidation_no = b.consolidation_no 
    WHERE 
		b.type = 'BO' 
		AND a.sel_flg2 <> 0

	-- Loop through orders
	SET @rec_id = 0
	WHILE 1=1
	BEGIN
		-- Get order
		SELECT
			@rec_id = rec_id,
			@order_no = order_no,
			@ext = ext,
			@consolidation_no = consolidation_no
		FROM
			#unalloc_orders
		WHERE
			rec_id > @rec_id
		ORDER BY
			rec_id

		IF @@ROWCOUNT = 0 
			BREAK

		-- If the order has alreay been packed then don't unallocate it
		IF EXISTS(SELECT 1 FROM dbo.tdc_carton_tx (NOLOCK) WHERE order_no = @order_no AND order_ext = @ext AND order_type = 'S')
		BEGIN
			-- Don't unallocate
			UPDATE
				#so_alloc_management
			SET
				sel_flg2 = 0
			WHERE
				order_no = @order_no 
				AND order_ext = @ext
			
			-- Remove from working table
			DELETE FROM #unalloc_orders WHERE rec_id = @rec_id
		END
		ELSE
		BEGIN
			-- Remove order from consolidation set
			DELETE FROM dbo.cvo_masterpack_consolidation_det WHERE consolidation_no = @consolidation_no AND order_no = @order_no AND order_ext = @ext
		END

	END

	-- Reconsolidate picks for affected consolidation sets
	SET @consolidation_no = 0
	WHILE 1=1
	BEGIN
		SELECT TOP 1
			@consolidation_no = consolidation_no
		FROM
			#unalloc_orders
		WHERE
			consolidation_no > @consolidation_no
		ORDER BY
			consolidation_no

		IF @@ROWCOUNT = 0
			BREAK

		EXEC dbo.cvo_masterpack_unconsolidate_pick_records_sp @consolidation_no
		EXEC dbo.cvo_masterpack_consolidate_pick_records_sp @consolidation_no
	END
END
GO
GRANT EXECUTE ON  [dbo].[cvo_masterpack_remove_unalloc_orders_from_bo_set_sp] TO [public]
GO
