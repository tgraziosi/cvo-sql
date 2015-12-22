SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_check_custom_frame_stock_sp]
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARATIONS

	-- Working tables
	CREATE TABLE #exclusions (
		order_no		int,
		order_ext		int,
		has_line_exc	int NULL) 

	CREATE TABLE #line_exclusions (
		order_no		int,
		order_ext		int,
		line_no			int)
	
	-- Unmark the custom frames
	UPDATE	cvo_soft_alloc_hdr
	SET		status = 0
	WHERE	status = -4

	UPDATE	cvo_soft_alloc_det
	SET		status = 0
	WHERE	status = -4

	-- Call the custom frame checking routine
	EXEC	cvo_soft_alloc_CF_check_sp 

	-- Mark custom frames with exclusions
	UPDATE	a
	SET		status = -4
	FROM	cvo_soft_alloc_hdr a
	JOIN	#exclusions b
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	JOIN	cvo_ord_list c (NOLOCK)
	ON		a.order_no = c.order_no
	AND		a.order_ext = c.order_ext
	WHERE	c.is_customized = 'S'

	UPDATE	a
	SET		status = -4
	FROM	cvo_soft_alloc_det a
	JOIN	cvo_soft_alloc_hdr b (NOLOCK)
	ON		a.soft_alloc_no = b.soft_alloc_no
	WHERE	b.status = -4	

	-- Clean Up
	DROP TABLE #exclusions
	DROP TABLE #line_exclusions

END
GO
GRANT EXECUTE ON  [dbo].[cvo_check_custom_frame_stock_sp] TO [public]
GO
