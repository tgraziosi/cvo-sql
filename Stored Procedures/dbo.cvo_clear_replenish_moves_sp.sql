SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_clear_replenish_moves_sp] @replen_group varchar(20)
AS
BEGIN
  
	-- Declarations
	DECLARE	@replen_id int

	CREATE TABLE #trans_to_remove (
		replen_id	int,
		location	varchar(10),
		part_no		varchar(30),
		bin_no		varchar(20),
		lot_ser		varchar(25),
		target_bin	varchar(20),
		qty			decimal(20,8))

	IF (@replen_group = 'ALL')
	BEGIN

		INSERT	#trans_to_remove
		SELECT	CAST(b.eco_no AS int), a.location, a.part_no, a.bin_no, a.lot_ser, a.target_bin, SUM(a.qty)
		FROM	tdc_soft_alloc_tbl a (NOLOCK)
		JOIN	tdc_pick_queue b (NOLOCK)
		ON		a.location = b.location
		AND		a.part_no = b.part_no
		AND		a.lot_ser = b.lot
		AND		a.bin_no = b.bin_no
		AND		a.target_bin = b.next_op
		WHERE	a.order_no = 0
		AND		a.order_ext = 0
		AND		a.line_no = 0
		AND		a.order_type = 'S'
		AND		ISNUMERIC(b.eco_no) = 1
		AND		ISNULL(b.eco_no,0) <> 0
		GROUP BY b.eco_no, a.location, a.part_no, a.bin_no, a.lot_ser, a.target_bin

		UPDATE	a
		SET		qty = a.qty - b.qty
		FROM	tdc_soft_alloc_tbl a
		JOIN	#trans_to_remove b
		ON		a.location = b.location
		AND		a.part_no = b.part_no
		AND		a.bin_no = b.bin_no
		AND		a.lot_ser = b.lot_ser
		AND		a.target_bin = b.target_bin
		WHERE	a.order_no = 0
		AND		a.order_ext = 0
		AND		a.line_no = 0
		AND		a.order_type = 'S'

		DELETE	a
		FROM	tdc_soft_alloc_tbl a
		JOIN	#trans_to_remove b
		ON		a.location = b.location
		AND		a.part_no = b.part_no
		AND		a.bin_no = b.bin_no
		AND		a.lot_ser = b.lot_ser
		AND		a.target_bin = b.target_bin
		WHERE	a.order_no = 0
		AND		a.order_ext = 0
		AND		a.line_no = 0
		AND		a.order_type = 'S'
		AND		a.qty <= 0

		DELETE	a
		FROM	tdc_pick_queue a
		JOIN	#trans_to_remove b
		ON		a.location = b.location
		AND		a.part_no = b.part_no
		AND		a.bin_no = b.bin_no
		AND		a.lot = b.lot_ser
		AND		a.next_op = b.target_bin
		WHERE	a.trans = 'MGTB2B'
		AND		a.trans_type_no = 0
		AND		a.trans_type_ext = 0
		AND		a.line_no = 0
		AND		ISNUMERIC(a.eco_no) = 1
		AND		ISNULL(a.eco_no,0) <> 0
	END
	ELSE
	BEGIN
		SELECT	@replen_id = replen_id
		FROM	replenishment_groups (NOLOCK)
		WHERE	replen_group = @replen_group
	
		INSERT	#trans_to_remove
		SELECT	CAST(b.eco_no AS int), a.location, a.part_no, a.bin_no, a.lot_ser, a.target_bin, SUM(a.qty)
		FROM	tdc_soft_alloc_tbl a (NOLOCK)
		JOIN	tdc_pick_queue b (NOLOCK)
		ON		a.location = b.location
		AND		a.part_no = b.part_no
		AND		a.lot_ser = b.lot
		AND		a.bin_no = b.bin_no
		AND		a.target_bin = b.next_op
		WHERE	a.order_no = 0
		AND		a.order_ext = 0
		AND		a.line_no = 0
		AND		a.order_type = 'S'
		AND		ISNUMERIC(b.eco_no) = 1
		AND		ISNULL(b.eco_no,0) = @replen_id
		GROUP BY b.eco_no, a.location, a.part_no, a.bin_no, a.lot_ser, a.target_bin

		UPDATE	a
		SET		qty = a.qty - b.qty
		FROM	tdc_soft_alloc_tbl a
		JOIN	#trans_to_remove b
		ON		a.location = b.location
		AND		a.part_no = b.part_no
		AND		a.bin_no = b.bin_no
		AND		a.lot_ser = b.lot_ser
		AND		a.target_bin = b.target_bin
		WHERE	a.order_no = 0
		AND		a.order_ext = 0
		AND		a.line_no = 0
		AND		a.order_type = 'S'

		DELETE	a
		FROM	tdc_soft_alloc_tbl a
		JOIN	#trans_to_remove b
		ON		a.location = b.location
		AND		a.part_no = b.part_no
		AND		a.bin_no = b.bin_no
		AND		a.lot_ser = b.lot_ser
		AND		a.target_bin = b.target_bin
		WHERE	a.order_no = 0
		AND		a.order_ext = 0
		AND		a.line_no = 0
		AND		a.order_type = 'S'
		AND		a.qty <= 0

		DELETE	a
		FROM	tdc_pick_queue a
		JOIN	#trans_to_remove b
		ON		a.location = b.location
		AND		a.part_no = b.part_no
		AND		a.bin_no = b.bin_no
		AND		a.lot = b.lot_ser
		AND		a.next_op = b.target_bin
		WHERE	a.trans = 'MGTB2B'
		AND		a.trans_type_no = 0
		AND		a.trans_type_ext = 0
		AND		a.line_no = 0
		AND		ISNUMERIC(a.eco_no) = 1
		AND		ISNULL(a.eco_no,0) = @replen_id

	END

	DROP TABLE #trans_to_remove

END
GO
GRANT EXECUTE ON  [dbo].[cvo_clear_replenish_moves_sp] TO [public]
GO
