SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v2.0	TM	17-OCT-2011	Do not clear out forward pick replens
-- v3.0 CB 04/01/2012 - Clean up process

-- Execute CVO_highbay_replenishment_sp

CREATE PROCEDURE [dbo].[CVO_highbay_replenishment_sp]

AS
BEGIN
	SET NOCOUNT ON

	-- v3.0 Need to remove highbay replenishment records from the queue before running
	DECLARE @tran_id		int,
			@last_tran_id	int,
			@location		varchar(10),
			@part_no		varchar(30),
			@bin_no			varchar(20),
			@next_op		varchar(20),
			@qty			decimal(20,8),
			@id				int,
			@last_id		int

	SET @last_tran_id = 0

	SELECT	TOP 1 @tran_id = tran_id,
			@location = location,
			@part_no = part_no,
			@bin_no = bin_no,
			@next_op = next_op,
			@qty = qty_to_process
	FROM	tdc_pick_queue (NOLOCK)
	WHERE	trans = 'MGTB2B'
	AND		trans_type_no = 0
	AND		ISNULL(eco_no,'N') = 'Y'
	AND		tran_id > @last_tran_id
	ORDER BY tran_id ASC

	WHILE @@ROWCOUNT <> 0
	BEGIN

		-- Remove the tdc_pick_queue record
		DELETE	tdc_pick_queue WHERE tran_id = @tran_id

		-- Update the tdc_soft_alloc_tbl table to reduce the qty for the removed record from the queue
		UPDATE	tdc_soft_alloc_tbl
		SET		qty = qty - @qty
		WHERE	order_no = 0
		AND		order_type = 'S'
		AND		location = @location
		AND		part_no = @part_no
		AND		bin_no = @bin_no
		AND		target_bin = @next_op
		AND		dest_bin = @next_op

		-- Remove the tdc_soft_alloc_tbl record if the qty has been reduced to zero
		DELETE	tdc_soft_alloc_tbl
		WHERE	order_no = 0
		AND		order_type = 'S'
		AND		location = @location
		AND		part_no = @part_no
		AND		bin_no = @bin_no
		AND		target_bin = @next_op
		AND		dest_bin = @next_op
		AND		qty <= 0

		SET @last_tran_id = @tran_id

		SELECT	TOP 1 @tran_id = tran_id,
				@location = location,
				@part_no = part_no,
				@bin_no = bin_no,
				@next_op = next_op,
				@qty = qty_to_process
		FROM	tdc_pick_queue (NOLOCK)
		WHERE	trans = 'MGTB2B'
		AND		trans_type_no = 0
		AND		ISNULL(eco_no,'N') = 'Y'
		AND		tran_id > @last_tran_id
		ORDER BY tran_id ASC

	END

	-- Processing Highbay moves
	CREATE TABLE #highbay_process (
				id			int identity(1,1), 
				part_no		varchar(30),
				bin_no		varchar(20),
				qty			decimal(20,8))

	-- Deal with empty bins first
	INSERT	#highbay_process (part_no, bin_no, qty)
	SELECT	part_no, 
			bin_no,
			0
	FROM    dbo.cvo_empty_highbay_repl_bin_vw (NOLOCK)
	where part_no in (select part_no from inv_master where type_code ='frame')  -- dmoon 03/05/2012


	SET @last_id = 0

	SELECT	TOP 1 @id = id,
			@part_no = part_no,
			@bin_no = bin_no
	FROM	#highbay_process
	WHERE	id > @last_id
	ORDER BY id ASC

	WHILE @@ROWCOUNT <> 0
	BEGIN
	

		EXEC CVO_tdc_automatic_highbay_bin_replenish  '001', @part_no, @bin_no, 0, 0

		SET @last_id = @id

		SELECT	TOP 1 @id = id,
				@part_no = part_no,
				@bin_no = bin_no
		FROM	#highbay_process
		WHERE	id > @last_id
		ORDER BY id ASC

	END

	-- Deal with bins below required level
	DELETE #highbay_process

	INSERT	#highbay_process (part_no, bin_no, qty)
	SELECT	a.part_no,
			a.bin_no,
			c.qty
	FROM	CVO_bin_replenishment_tbl a (NOLOCK)
	JOIN	tdc_bin_master b (NOLOCK)
	ON		a.bin_no = b.bin_no
	JOIN	lot_bin_stock c (NOLOCK)
	ON		a.part_no = c.part_no
	AND		a.bin_no = c.bin_no
	WHERE	c.qty < a.min_qty
	AND		b.group_code = 'HIGHBAY'
	AND   a.part_no in (select part_no from inv_master where type_code ='frame') -- dmoon 03/05/2012
	ORDER BY a.bin_no


	SET @last_id = 0

	SELECT	TOP 1 @id = id,
			@part_no = part_no,
			@bin_no = bin_no,
			@qty = qty
	FROM	#highbay_process
	WHERE	id > @last_id
	ORDER BY id ASC

	WHILE @@ROWCOUNT <> 0
	BEGIN
	
		EXEC CVO_tdc_automatic_highbay_bin_replenish  '001', @part_no, @bin_no, 0, @qty

		SET @last_id = @id

		SELECT	TOP 1 @id = id,
				@part_no = part_no,
				@bin_no = bin_no,
				@qty = qty
		FROM	#highbay_process
		WHERE	id > @last_id
		ORDER BY id ASC

	END


	DROP TABLE #highbay_process

	Execute cvo_print_replenish_list 'HIGHBAY'

	RETURN
END
GO
GRANT EXECUTE ON  [dbo].[CVO_highbay_replenishment_sp] TO [public]
GO
