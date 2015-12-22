SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[CVO_Consolidate_PackOut_sp]
AS
BEGIN
	SET NOCOUNT ON

	-- Declarations
	DECLARE	@case		varchar(30),
			@pattern	varchar(30),
			@polarized	varchar(30),
			@type_code	varchar(100),
			@id			int,
			@last_id	int,
			@order_no	int,
			@order_ext	int

	-- Working tables
	CREATE TABLE #order_to_process (
		id				int IDENTITY(1,1),
		order_no		int,
		order_ext		int)

	CREATE TABLE #lines_to_consolidate (
		line_no			int,
		location		varchar(10),
		part_no			varchar(30),
		qty				decimal(20,8),
		packed_qty		decimal(20,8),
		carton_qty		decimal(20,8),
		new_qty			decimal(20,8),
		con_rec			int,
		line_link		int)

	CREATE TABLE #parts_to_consolidate (
		line_no			int,
		location		varchar(10),
		part_no			varchar(30),
		qty				decimal(20,8))

	CREATE TABLE #parts_to_pack_consolidate (
		line_no			int,
		location		varchar(10),
		part_no			varchar(30),
		packed_qty		decimal(20,8))

	CREATE TABLE #parts_to_carton_consolidate (
		line_no			int,
		location		varchar(10),
		part_no			varchar(30),
		carton_qty		decimal(20,8))

	-- Select orders to process
	INSERT	#order_to_process (order_no, order_ext)
	SELECT	distinct order_no, order_ext
	FROM	#temp_pps_carton_display

	-- Find the resource type for case, pattern, polarized
	SET @case	   = [dbo].[CVO_get_ResType_PartType_fn] ('DEF_RES_TYPE_CASE')
	SET @pattern   = [dbo].[CVO_get_ResType_PartType_fn] ('DEF_RES_TYPE_PATTERN')  
	SET @polarized = [dbo].[CVO_get_ResType_PartType_fn] ('DEF_RES_TYPE_POLARIZED') 

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
		INSERT	#lines_to_consolidate (line_no, part_no, qty, packed_qty, carton_qty, new_qty, con_rec, line_link)
		SELECT	a.line_no,
				a.part_no,
				a.picked,
				a.total_packed,
				a.carton_packed,
				0, 0, NULL
		FROM	#temp_pps_carton_display a (NOLOCK)
		JOIN	inv_master b (NOLOCK)
		ON		a.part_no = b.part_no
		WHERE	b.type_code IN (select * from [fs_cParsing](@type_code))
		AND		a.order_no = @order_no
		AND		a.order_ext = @order_ext
		AND		a.order_no IN (
				SELECT	a.order_no 
				FROM	#temp_pps_carton_display a (NOLOCK)
				JOIN	inv_master b (NOLOCK)
				ON		a.part_no = b.part_no
				WHERE	b.type_code NOT IN (select * from [fs_cParsing](@type_code)))

		-- Clear the working table
		DELETE	#parts_to_consolidate

		-- Consolidate the quantities
		INSERT	#parts_to_consolidate (line_no, part_no, qty)
		SELECT	MIN(line_no), part_no, SUM(qty)
		FROM	#lines_to_consolidate
		GROUP BY part_no

		DELETE	#parts_to_pack_consolidate

		-- Consolidate the quantities
		INSERT	#parts_to_pack_consolidate (line_no, part_no, packed_qty)
		SELECT	MIN(line_no), part_no, SUM(packed_qty)
		FROM	#lines_to_consolidate
		GROUP BY part_no

		DELETE	#parts_to_carton_consolidate

		-- Consolidate the quantities
		INSERT	#parts_to_carton_consolidate (line_no, part_no, carton_qty)
		SELECT	MIN(line_no), part_no, SUM(carton_qty)
		FROM	#lines_to_consolidate
		GROUP BY part_no


		-- Mark the lines to consolidate
		UPDATE	a
		SET		new_qty = b.qty,
				con_rec = 1
		FROM	#lines_to_consolidate a
		JOIN	#parts_to_consolidate b
		ON		a.line_no = b.line_no
		WHERE	b.qty > 1

		UPDATE	a
		SET		packed_qty = b.packed_qty
		FROM	#lines_to_consolidate a
		JOIN	#parts_to_pack_consolidate b
		ON		a.line_no = b.line_no
		WHERE	b.packed_qty > 1
		AND		a.con_rec = 1

		UPDATE	a
		SET		carton_qty = b.carton_qty
		FROM	#lines_to_consolidate a
		JOIN	#parts_to_carton_consolidate b
		ON		a.line_no = b.line_no
		WHERE	b.carton_qty > 1
		AND		a.con_rec = 1

		UPDATE	a
		SET		con_rec = 2,
				line_link = b.line_no
		FROM	#lines_to_consolidate a
		JOIN	#lines_to_consolidate b
		ON		a.part_no = b.part_no
		WHERE	a.con_rec = 0
		AND		b.con_rec = 1
		
		-- Mark the #temp_pps_carton_display records
		UPDATE	a
		SET		con_qty = CASE WHEN b.con_rec = 1 THEN b.new_qty ELSE NULL END,
				con_ref = CASE WHEN b.con_rec = 1 THEN b.line_no 
								  WHEN b.con_rec = 2 THEN b.line_link ELSE NULL END,
				con_rec = CASE WHEN b.con_rec = 2 THEN 1 ELSE NULL END,
				con_packed_qty = CASE WHEN b.con_rec = 1 THEN b.packed_qty ELSE NULL END,
				con_carton_qty = CASE WHEN b.con_rec = 1 THEN b.carton_qty ELSE NULL END					
		FROM	#temp_pps_carton_display a
		JOIN	#lines_to_consolidate b
		ON		a.line_no = b.line_no
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
GRANT EXECUTE ON  [dbo].[CVO_Consolidate_PackOut_sp] TO [public]
GO
