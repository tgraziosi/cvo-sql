
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[CVO_Consolidate_Pick_queue_sp]	@order_no	int = 0, -- v1.1
												@order_ext	int = 0 -- v1.1
AS
BEGIN
	SET NOCOUNT ON

	-- Declarations
	DECLARE	@case		varchar(30),
			@pattern	varchar(30),
			@polarized	varchar(30),
			@type_code	varchar(100),
			@id			int,
			@last_id	int --, v1.1
-- v1.1			@order_no	int,
-- v1.1			@order_ext	int

	-- Working tables
	CREATE TABLE #order_to_process (
		id				int IDENTITY(1,1),
		order_no		int,
		order_ext		int)

	CREATE TABLE #lines_to_consolidate (
		tran_id			int,
		location		varchar(10),
		part_no			varchar(30),
		bin_no			varchar(20),
		qty				decimal(20,8),
		new_qty			decimal(20,8),
		con_rec			int,
		tran_id_link	int)

	CREATE TABLE #parts_to_consolidate (
		tran_id			int,
		location		varchar(10),
		part_no			varchar(30),
		bin_no			varchar(20),
		qty				decimal(20,8))


	-- Select orders to process
	-- v1.1 Start - If no order nno is passed in then its being called from WMS
	IF @order_no = 0
	BEGIN
		INSERT	#order_to_process (order_no, order_ext)
		SELECT	order_no, order_ext
		FROM	#so_alloc_management_header

		-- v1.2 Start
		DELETE	a
		FROM	#order_to_process a
		LEFT JOIN cvo_soft_alloc_det b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		WHERE	b.order_no IS NULL
		-- v1.2 End

	END
	ELSE
	BEGIN 
		INSERT	#order_to_process (order_no, order_ext)
		SELECT	@order_no, @order_ext
		
		-- v1.3 Start
		--IF NOT EXISTS (SELECT 1 FROM cvo_soft_alloc_hdr (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext)
		--	RETURN
		-- v1.3 End
	END
	-- v1.1 End


	-- Find the resource type for case, pattern, polarized
	SET @case	   = [dbo].[CVO_get_ResType_PartType_fn] ('DEF_RES_TYPE_CASE')
	SET @pattern   = [dbo].[CVO_get_ResType_PartType_fn] ('DEF_RES_TYPE_PATTERN')  
	SET @polarized = 'PARTS' -- v1.4 [dbo].[CVO_get_ResType_PartType_fn] ('DEF_RES_TYPE_POLARIZED') 

	SET @type_code = @case + ',' + @pattern + ',' + @polarized

	SET @last_id = 0

	SELECT	TOP 1 @id = id,
			@order_no = order_no,
			@order_ext = order_ext
	FROM	#order_to_process
	WHERE	id > @last_id
	ORDER BY id ASC

	WHILE @@ROWCOUNT <> 0
	BEGIN
		
		-- Clear the working table
		DELETE	#lines_to_consolidate

		-- Populate the working table
		INSERT	#lines_to_consolidate (tran_id, location, part_no, bin_no, qty,	new_qty, con_rec, tran_id_link)
		SELECT	a.tran_id,
				a.location,
				a.part_no,
				a.bin_no,
				a.qty_to_process,
				0, 0, NULL
		FROM	tdc_pick_queue a (NOLOCK)
		JOIN	inv_master b (NOLOCK)
		ON		a.part_no = b.part_no
		WHERE	b.type_code IN (select * from [fs_cParsing](@type_code))
		AND		a.trans_type_no = @order_no
		AND		a.trans_type_ext = @order_ext

		-- Clear the working table
		DELETE	#parts_to_consolidate

		-- Consolidate the quantities
		INSERT	#parts_to_consolidate (tran_id, location, part_no, bin_no, qty)
		SELECT	MIN(tran_id), location, part_no, bin_no, SUM(qty)
		FROM	#lines_to_consolidate
		GROUP BY location, part_no, bin_no

		-- Mark the lines to consolidate
		UPDATE	a
		SET		new_qty = b.qty,
				con_rec = 1
		FROM	#lines_to_consolidate a
		JOIN	#parts_to_consolidate b
		ON		a.tran_id = b.tran_id
		WHERE	b.qty > 1

		UPDATE	a
		SET		con_rec = 2,
				tran_id_link = b.tran_id
		FROM	#lines_to_consolidate a
		JOIN	#lines_to_consolidate b
		ON		a.location = b.location
		AND		a.part_no = b.part_no
		AND		a.bin_no = b.bin_no
		WHERE	a.con_rec = 0
		AND		b.con_rec = 1
	
		
		-- Mark the tdc_pick_queue records
		-- pcsn field will hold the consolidated qty and the tran_id_link will hold the tran id ref
		-- assign_user_id will be set to HIDDEN for the reference tran ids so that they do not show up
		-- in queue management
		UPDATE	a
		SET		pcsn = CASE WHEN b.con_rec = 1 THEN b.new_qty ELSE NULL END,
				tran_id_link = CASE WHEN b.con_rec = 1 THEN b.tran_id 
								  WHEN b.con_rec = 2 THEN b.tran_id_link ELSE NULL END,
				assign_user_id = CASE WHEN b.con_rec = 2 THEN 'HIDDEN' ELSE NULL END					
		FROM	tdc_pick_queue a
		JOIN	#lines_to_consolidate b
		ON		a.tran_id = b.tran_id
		WHERE	b.con_rec > 0

		SET @last_id = @id

		SELECT	TOP 1 @id = id,
				@order_no = order_no,
				@order_ext = order_ext
		FROM	#order_to_process
		WHERE	id > @last_id
		ORDER BY id ASC

	END

END
GO

GRANT EXECUTE ON  [dbo].[CVO_Consolidate_Pick_queue_sp] TO [public]
GO
