SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_release_hold_ship_complete_allocations_sp]	@order_no int,
																@order_ext int
AS
BEGIN
	SET NOCOUNT ON

	-- Declarations
	DECLARE	@id			int,
			@last_id	int

	-- Create working tables
	CREATE TABLE #wip_sc (
		id			int identity(1,1),
		order_no	int,
		order_ext	int)

	-- Populate the working table with pick queue records where mfg_batch is set (REL_DATE, SHIP_COMP)
	INSERT	#wip_sc (order_no, order_ext)
	SELECT	trans_type_no,
			trans_type_ext
	FROM	dbo.tdc_pick_queue (NOLOCK)
	WHERE	tx_lock = 'H'
	AND		PATINDEX('%SHIP_COMP%',mfg_batch) > 0
	AND		trans_type_no = @order_no
	AND		trans_type_ext = @order_ext
	GROUP BY trans_type_no,
			trans_type_ext

	-- For each record returned call the allocation routine 
	SET @last_id = 0
	
	SELECT	TOP 1 @id = id,
			@order_no = order_no,
			@order_ext = order_ext
	FROM	#wip_sc
	WHERE	id > @last_id
	ORDER BY id ASC

	WHILE @@ROWCOUNT <> 0
	BEGIN
		-- Call the allocation process
		EXEC dbo.tdc_order_after_save @order_no, @order_ext
		IF @@ERROR <> 0
			RETURN -1

		-- Call the ship complete hold routine
		EXEC cvo_hold_ship_complete_allocations_sp @order_no, @order_ext

		SET @last_id = @id
		
		SELECT	TOP 1 @id = id,
				@order_no = order_no,
				@order_ext = order_ext
		FROM	#wip_sc
		WHERE	id > @last_id
		ORDER BY id ASC
	END

	DROP TABLE #wip_sc

	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[cvo_release_hold_ship_complete_allocations_sp] TO [public]
GO
