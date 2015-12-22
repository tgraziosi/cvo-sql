SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_process_backorder_held_orders_sp]
AS
BEGIN
	SET NOCOUNT ON

	-- Declarations
	DECLARE	@id			int,
			@last_id	int,
			@hold_type	int,
			@order_no	int,
			@order_ext	int

	-- Create working table
	CREATE TABLE #wip (
		id					int identity(1,1),
		order_no			int,
		order_ext			int,
		so_priority_code	char(1),
		sch_ship_date		datetime,
		hold_type			int)

	-- To populate the working table we will make multiple passes on the data
	-- this is to ensure that CVO's priority is followed
	-- 0.5 Get the backorders with a order type of RX ordering by so priority, sch ship date, order and ext
	--		And the backorder is not a held allocation
	INSERT	#wip (order_no, order_ext, so_priority_code, sch_ship_date, hold_type)
	SELECT	DISTINCT a.order_no,
			a.ext,
			CASE WHEN a.so_priority_code IS NULL THEN 9
				  WHEN a.so_priority_code = '' THEN 9
				  ELSE a.so_priority_code END,
			a.sch_ship_date,
			0
	FROM	dbo.orders a (NOLOCK)
	JOIN	dbo.cvo_orders_all cvo (NOLOCK) -- v1.1
	ON		a.order_no = cvo.order_no -- v1.1
	AND		a.ext = cvo.ext -- v1.1
	LEFT JOIN dbo.tdc_pick_queue b (NOLOCK)
	ON		a.order_no = b.trans_type_no
	WHERE	a.user_category = 'RX'
	AND		a.status IN ('N','A','C') -- v1.4
	AND		a.ext = 0
	AND		a.who_entered <> 'BACKORDR'
	AND		a.type = 'I'
	AND		a.location = '001'
	AND		ISNULL(cvo.allocation_date,GETDATE()-1) < GETDATE() -- v1.1
	AND		((ISNULL(b.trans,'') = 'STDPICK') -- v1.2
	OR		(b.trans_type_no IS NULL
	AND		b.trans_type_ext IS NULL))
	ORDER BY CASE WHEN a.so_priority_code IS NULL THEN 9
				  WHEN a.so_priority_code = '' THEN 9
				  ELSE a.so_priority_code END ASC, 
			a.sch_ship_date ASC,
			a.order_no ASC,
			a.ext ASC


	-- 1. Get the backorders with a order type of RX ordering by so priority, sch ship date, order and ext
	--		And the backorder is not a held allocation
	INSERT	#wip (order_no, order_ext, so_priority_code, sch_ship_date, hold_type)
	SELECT	DISTINCT a.order_no,
			a.ext,
			CASE WHEN a.so_priority_code IS NULL THEN 9
				  WHEN a.so_priority_code = '' THEN 9
				  ELSE a.so_priority_code END,
			a.sch_ship_date,
			0
	FROM	dbo.orders a (NOLOCK)
	JOIN	dbo.cvo_orders_all cvo (NOLOCK) -- v1.1
	ON		a.order_no = cvo.order_no -- v1.1
	AND		a.ext = cvo.ext -- v1.1
	LEFT JOIN dbo.tdc_pick_queue b (NOLOCK)
	ON		a.order_no = b.trans_type_no
	WHERE	a.user_category = 'RX'
	AND		a.status IN ('N','A','C') -- v1.4
	AND		a.ext > 0
	AND		a.who_entered = 'BACKORDR'
	AND		a.type = 'I'
	AND		a.location = '001'
	AND		ISNULL(cvo.allocation_date,GETDATE()-1) < GETDATE() -- v1.1
	AND		((ISNULL(b.trans,'') = 'STDPICK') -- v1.2
	OR		(b.trans_type_no IS NULL
	AND		b.trans_type_ext IS NULL))
	ORDER BY CASE WHEN a.so_priority_code IS NULL THEN 9
				  WHEN a.so_priority_code = '' THEN 9
				  ELSE a.so_priority_code END ASC, 
			a.sch_ship_date ASC,
			a.order_no ASC,
			a.ext ASC

	-- 2. Get the backorders with a order type of RX ordering by so priority, sch ship date, order and ext
	--		And the backorder is a held allocation for ship complete
	INSERT	#wip (order_no, order_ext, so_priority_code, sch_ship_date, hold_type)
	SELECT	DISTINCT a.order_no,
			a.ext,
			CASE WHEN a.so_priority_code IS NULL THEN 9
				  WHEN a.so_priority_code = '' THEN 9
				  ELSE a.so_priority_code END,
			a.sch_ship_date,
			0
	FROM	dbo.orders a (NOLOCK)
	JOIN	dbo.tdc_pick_queue b (NOLOCK)
	ON		a.order_no = b.trans_type_no
	LEFT JOIN #wip c
	ON		a.order_no = c.order_no
	AND		a.ext = c.order_ext
	WHERE	a.user_category = 'RX'
	AND		a.status IN ('N','A','C') -- v1.4
	AND		a.ext > 0
	AND		a.who_entered = 'BACKORDR'
	AND		a.type = 'I'
	AND		a.location = '001'
	AND		PATINDEX('SHIP_COMP%',b.mfg_batch) > 0
	AND		PATINDEX('%REL_DATE%',b.mfg_batch) = 0
	AND		c.order_no IS NULL
	AND		c.order_ext IS NULL
	ORDER BY CASE WHEN a.so_priority_code IS NULL THEN 9
				  WHEN a.so_priority_code = '' THEN 9
				  ELSE a.so_priority_code END ASC, 
			a.sch_ship_date ASC,
			a.order_no ASC,
			a.ext ASC


	-- 3. Get the backorders with a order type of RX ordering by so priority, sch ship date, order and ext
	--		And the backorder is a held allocation for ship complete and/or release date
	INSERT	#wip (order_no, order_ext, so_priority_code, sch_ship_date, hold_type)
	SELECT	DISTINCT a.order_no,
			a.ext,
			CASE WHEN a.so_priority_code IS NULL THEN 9
				  WHEN a.so_priority_code = '' THEN 9
				  ELSE a.so_priority_code END,
			a.sch_ship_date,
			0
	FROM	dbo.orders a (NOLOCK)
	JOIN	dbo.tdc_pick_queue b (NOLOCK)
	ON		a.order_no = b.trans_type_no
	LEFT JOIN #wip c
	ON		a.order_no = c.order_no
	AND		a.ext = c.order_ext
	WHERE	a.user_category = 'RX'
	AND		a.status IN ('N','A','C') -- v1.4
	AND		a.ext > 0
	AND		a.who_entered = 'BACKORDR'
	AND		a.type = 'I'
	AND		a.location = '001'
	AND		PATINDEX('%REL_DATE%',b.mfg_batch) > 0
	AND		c.order_no IS NULL
	AND		c.order_ext IS NULL
	ORDER BY CASE WHEN a.so_priority_code IS NULL THEN 9
				  WHEN a.so_priority_code = '' THEN 9
				  ELSE a.so_priority_code END ASC, 
			a.sch_ship_date ASC,
			a.order_no ASC,
			a.ext ASC

	-- 3.5. Get the backorders with a order type of ST ordering by so priority, sch ship date, order and ext
	--		And the backorder is not a held allocation
	INSERT	#wip (order_no, order_ext, so_priority_code, sch_ship_date, hold_type)
	SELECT	DISTINCT a.order_no,
			a.ext,
			CASE WHEN a.so_priority_code IS NULL THEN 9
				  WHEN a.so_priority_code = '' THEN 9
				  ELSE a.so_priority_code END,
			a.sch_ship_date,
			0
	FROM	dbo.orders a (NOLOCK)
	JOIN	dbo.cvo_orders_all cvo (NOLOCK) -- v1.1
	ON		a.order_no = cvo.order_no -- v1.1
	AND		a.ext = cvo.ext -- v1.1
	LEFT JOIN dbo.tdc_pick_queue b (NOLOCK)
	ON		a.order_no = b.trans_type_no
	LEFT JOIN #wip c
	ON		a.order_no = c.order_no
	AND		a.ext = c.order_ext
	WHERE	a.user_category = 'ST'
	AND		a.status IN ('N','A','C') -- v1.4
	AND		a.ext = 0
	AND		a.who_entered <> 'BACKORDR'
	AND		a.type = 'I'
	AND		a.location = '001'
	AND		ISNULL(cvo.allocation_date,GETDATE()-1) < GETDATE() -- v1.1
	AND		((ISNULL(b.trans,'') = 'STDPICK') -- v1.2
	OR		(b.trans_type_no IS NULL
	AND		b.trans_type_ext IS NULL))
	AND		c.order_no IS NULL
	AND		c.order_ext IS NULL
	ORDER BY CASE WHEN a.so_priority_code IS NULL THEN 9
				  WHEN a.so_priority_code = '' THEN 9
				  ELSE a.so_priority_code END ASC, 
			a.sch_ship_date ASC,
			a.order_no ASC,
			a.ext ASC


	-- 4. Get the backorders with a order type of ST ordering by so priority, sch ship date, order and ext
	--		And the backorder is not a held allocation
	INSERT	#wip (order_no, order_ext, so_priority_code, sch_ship_date, hold_type)
	SELECT	DISTINCT a.order_no,
			a.ext,
			CASE WHEN a.so_priority_code IS NULL THEN 9
				  WHEN a.so_priority_code = '' THEN 9
				  ELSE a.so_priority_code END,
			a.sch_ship_date,
			0
	FROM	dbo.orders a (NOLOCK)
	JOIN	dbo.cvo_orders_all cvo (NOLOCK) -- v1.1
	ON		a.order_no = cvo.order_no -- v1.1
	AND		a.ext = cvo.ext -- v1.1
	LEFT JOIN dbo.tdc_pick_queue b (NOLOCK)
	ON		a.order_no = b.trans_type_no
	LEFT JOIN #wip c
	ON		a.order_no = c.order_no
	AND		a.ext = c.order_ext
	WHERE	a.user_category = 'ST'
	AND		a.status IN ('N','A','C') -- v1.4
	AND		a.ext > 0
	AND		a.who_entered = 'BACKORDR'
	AND		a.type = 'I'
	AND		a.location = '001'
	AND		ISNULL(cvo.allocation_date,GETDATE()-1) < GETDATE()
	AND		((ISNULL(b.trans,'') = 'STDPICK') -- v1.2
	OR		(b.trans_type_no IS NULL
	AND		b.trans_type_ext IS NULL))
	AND		c.order_no IS NULL
	AND		c.order_ext IS NULL
	ORDER BY CASE WHEN a.so_priority_code IS NULL THEN 9
				  WHEN a.so_priority_code = '' THEN 9
				  ELSE a.so_priority_code END ASC, 
			a.sch_ship_date ASC,
			a.order_no ASC,
			a.ext ASC

	-- 5. Get the backorders with a order type of ST ordering by so priority, sch ship date, order and ext
	--		And the backorder is a held allocation for ship complete
	INSERT	#wip (order_no, order_ext, so_priority_code, sch_ship_date, hold_type)
	SELECT	DISTINCT a.order_no,
			a.ext,
			CASE WHEN a.so_priority_code IS NULL THEN 9
				  WHEN a.so_priority_code = '' THEN 9
				  ELSE a.so_priority_code END,
			a.sch_ship_date,
			0
	FROM	dbo.orders a (NOLOCK)
	JOIN	dbo.tdc_pick_queue b (NOLOCK)
	ON		a.order_no = b.trans_type_no
	LEFT JOIN #wip c
	ON		a.order_no = c.order_no
	AND		a.ext = c.order_ext
	WHERE	a.user_category = 'ST'
	AND		a.status IN ('N','A','C') -- v1.4
	AND		a.ext > 0
	AND		a.who_entered = 'BACKORDR'
	AND		a.type = 'I'
	AND		a.location = '001'
	AND		PATINDEX('SHIP_COMP%',b.mfg_batch) > 0
	AND		PATINDEX('%REL_DATE%',b.mfg_batch) = 0
	AND		c.order_no IS NULL
	AND		c.order_ext IS NULL
	ORDER BY CASE WHEN a.so_priority_code IS NULL THEN 9
				  WHEN a.so_priority_code = '' THEN 9
				  ELSE a.so_priority_code END ASC, 
			a.sch_ship_date ASC,
			a.order_no ASC,
			a.ext ASC

	-- 6. Get the backorders with a order type of ST ordering by so priority, sch ship date, order and ext
	--		And the backorder is a held allocation for ship complete and/or release date
	INSERT	#wip (order_no, order_ext, so_priority_code, sch_ship_date, hold_type)
	SELECT	DISTINCT a.order_no,
			a.ext,
			CASE WHEN a.so_priority_code IS NULL THEN 9
				  WHEN a.so_priority_code = '' THEN 9
				  ELSE a.so_priority_code END,
			a.sch_ship_date,
			0
	FROM	dbo.orders a (NOLOCK)
	JOIN	dbo.tdc_pick_queue b (NOLOCK)
	ON		a.order_no = b.trans_type_no
	LEFT JOIN #wip c
	ON		a.order_no = c.order_no
	AND		a.ext = c.order_ext
	WHERE	a.user_category = 'ST'
	AND		a.status IN ('N','A','C') -- v1.4
	AND		a.ext > 0
	AND		a.who_entered = 'BACKORDR'
	AND		a.type = 'I'
	AND		a.location = '001'
	AND		PATINDEX('%REL_DATE%',b.mfg_batch) > 0
	AND		c.order_no IS NULL
	AND		c.order_ext IS NULL
	ORDER BY CASE WHEN a.so_priority_code IS NULL THEN 9
				  WHEN a.so_priority_code = '' THEN 9
				  ELSE a.so_priority_code END ASC, 
			a.sch_ship_date ASC,
			a.order_no ASC,
			a.ext ASC


	-- 6.5. Get the backorders with a order type not equal to RX or ST ordering by so priority, sch ship date, order and ext
	--		And the backorder is not a held allocation
	INSERT	#wip (order_no, order_ext, so_priority_code, sch_ship_date, hold_type)
	SELECT	DISTINCT a.order_no,
			a.ext,
			CASE WHEN a.so_priority_code IS NULL THEN 9
				  WHEN a.so_priority_code = '' THEN 9
				  ELSE a.so_priority_code END,
			a.sch_ship_date,
			0
	FROM	dbo.orders a (NOLOCK)
	JOIN	dbo.cvo_orders_all cvo (NOLOCK) -- v1.1
	ON		a.order_no = cvo.order_no -- v1.1
	AND		a.ext = cvo.ext -- v1.1
	LEFT JOIN dbo.tdc_pick_queue b (NOLOCK)
	ON		a.order_no = b.trans_type_no
	LEFT JOIN #wip c
	ON		a.order_no = c.order_no
	AND		a.ext = c.order_ext
	WHERE	a.user_category NOT IN ('RX','ST')
	AND		a.status IN ('N','A','C') -- v1.4
	AND		a.ext = 0
	AND		a.who_entered <> 'BACKORDR'
	AND		a.type = 'I'
	AND		a.location = '001'
	AND		ISNULL(cvo.allocation_date,GETDATE()-1) < GETDATE() -- v1.1
	AND		((ISNULL(b.trans,'') = 'STDPICK') -- v1.2
	OR		(b.trans_type_no IS NULL
	AND		b.trans_type_ext IS NULL))
	AND		c.order_no IS NULL
	AND		c.order_ext IS NULL
	ORDER BY CASE WHEN a.so_priority_code IS NULL THEN 9
				  WHEN a.so_priority_code = '' THEN 9
				  ELSE a.so_priority_code END ASC, 
			a.sch_ship_date ASC,
			a.order_no ASC,
			a.ext ASC


	-- 7. Get the backorders with a order type not equal to RX or ST ordering by so priority, sch ship date, order and ext
	--		And the backorder is not a held allocation
	INSERT	#wip (order_no, order_ext, so_priority_code, sch_ship_date, hold_type)
	SELECT	DISTINCT a.order_no,
			a.ext,
			CASE WHEN a.so_priority_code IS NULL THEN 9
				  WHEN a.so_priority_code = '' THEN 9
				  ELSE a.so_priority_code END,
			a.sch_ship_date,
			0
	FROM	dbo.orders a (NOLOCK)
	JOIN	dbo.cvo_orders_all cvo (NOLOCK) -- v1.1
	ON		a.order_no = cvo.order_no -- v1.1
	AND		a.ext = cvo.ext -- v1.1
	LEFT JOIN dbo.tdc_pick_queue b (NOLOCK)
	ON		a.order_no = b.trans_type_no
	LEFT JOIN #wip c
	ON		a.order_no = c.order_no
	AND		a.ext = c.order_ext
	WHERE	a.user_category NOT IN ('RX','ST')
	AND		a.status IN ('N','A','C') -- v1.4
	AND		a.ext > 0
	AND		a.who_entered = 'BACKORDR'
	AND		a.type = 'I'
	AND		a.location = '001'
	AND		ISNULL(cvo.allocation_date,GETDATE()-1) < GETDATE() -- v1.1
	AND		((ISNULL(b.trans,'') = 'STDPICK') -- v1.2
	OR		(b.trans_type_no IS NULL
	AND		b.trans_type_ext IS NULL))
	AND		c.order_no IS NULL
	AND		c.order_ext IS NULL
	ORDER BY CASE WHEN a.so_priority_code IS NULL THEN 9
				  WHEN a.so_priority_code = '' THEN 9
				  ELSE a.so_priority_code END ASC, 
			a.sch_ship_date ASC,
			a.order_no ASC,
			a.ext ASC

	-- 8. Get the backorders with a order type not equal to RX or ST ordering by so priority, sch ship date, order and ext
	--		And the backorder is a held allocation for ship complete
	INSERT	#wip (order_no, order_ext, so_priority_code, sch_ship_date, hold_type)
	SELECT	DISTINCT a.order_no,
			a.ext,
			CASE WHEN a.so_priority_code IS NULL THEN 9
				  WHEN a.so_priority_code = '' THEN 9
				  ELSE a.so_priority_code END,
			a.sch_ship_date,
			0
	FROM	dbo.orders a (NOLOCK)
	JOIN	dbo.tdc_pick_queue b (NOLOCK)
	ON		a.order_no = b.trans_type_no
	LEFT JOIN #wip c
	ON		a.order_no = c.order_no
	AND		a.ext = c.order_ext
	WHERE	a.user_category NOT IN ('RX','ST')
	AND		a.status IN ('N','A','C') -- v1.4
	AND		a.ext > 0
	AND		a.who_entered = 'BACKORDR'
	AND		a.type = 'I'
	AND		a.location = '001'
	AND		PATINDEX('SHIP_COMP%',b.mfg_batch) > 0
	AND		PATINDEX('%REL_DATE%',b.mfg_batch) = 0
	AND		c.order_no IS NULL
	AND		c.order_ext IS NULL
	ORDER BY CASE WHEN a.so_priority_code IS NULL THEN 9
				  WHEN a.so_priority_code = '' THEN 9
				  ELSE a.so_priority_code END ASC, 
			a.sch_ship_date ASC,
			a.order_no ASC,
			a.ext ASC

	-- 9. Get the backorders with a order type not equal to RX or ST ordering by so priority, sch ship date, order and ext
	--		And the backorder is a held allocation for ship complete and/or release date
	INSERT	#wip (order_no, order_ext, so_priority_code, sch_ship_date, hold_type)
	SELECT	DISTINCT a.order_no,
			a.ext,
			CASE WHEN a.so_priority_code IS NULL THEN 9
				  WHEN a.so_priority_code = '' THEN 9
				  ELSE a.so_priority_code END,
			a.sch_ship_date,
			0
	FROM	dbo.orders a (NOLOCK)
	JOIN	dbo.tdc_pick_queue b (NOLOCK)
	ON		a.order_no = b.trans_type_no
	LEFT JOIN #wip c
	ON		a.order_no = c.order_no
	AND		a.ext = c.order_ext
	WHERE	a.user_category NOT IN ('RX','ST') -- v1.3
	AND		a.status IN ('N','A','C') -- v1.4
	AND		a.ext > 0
	AND		a.who_entered = 'BACKORDR'
	AND		a.type = 'I'
	AND		a.location = '001'
	AND		PATINDEX('%REL_DATE%',b.mfg_batch) > 0
	AND		c.order_no IS NULL
	AND		c.order_ext IS NULL
	ORDER BY CASE WHEN a.so_priority_code IS NULL THEN 9
				  WHEN a.so_priority_code = '' THEN 9
				  ELSE a.so_priority_code END ASC, 
			a.sch_ship_date ASC,
			a.order_no ASC,
			a.ext ASC

	-- 10. Get the order in hold for ship complete but not a backorder ordering by so priority, sch ship date, order and ext
	--		And the order type is RX
	INSERT	#wip (order_no, order_ext, so_priority_code, sch_ship_date, hold_type)
	SELECT	DISTINCT a.order_no,
			a.ext,
			CASE WHEN a.so_priority_code IS NULL THEN 9
				  WHEN a.so_priority_code = '' THEN 9
				  ELSE a.so_priority_code END,
			a.sch_ship_date,
			2
	FROM	dbo.orders a (NOLOCK)
	JOIN	dbo.tdc_pick_queue b (NOLOCK)
	ON		a.order_no = b.trans_type_no
	LEFT JOIN #wip c
	ON		a.order_no = c.order_no
	AND		a.ext = c.order_ext
	WHERE	a.user_category = 'RX'
	AND		a.status IN ('N','A','C') -- v1.4
	AND		a.who_entered <> 'BACKORDR'
	AND		a.type = 'I'
	AND		a.location = '001'
	AND		PATINDEX('%SHIP_COMP%',b.mfg_batch) > 0
	AND		PATINDEX('%REL_DATE%',b.mfg_batch) = 0
	AND		c.order_no IS NULL
	AND		c.order_ext IS NULL
	ORDER BY CASE WHEN a.so_priority_code IS NULL THEN 9
				  WHEN a.so_priority_code = '' THEN 9
				  ELSE a.so_priority_code END ASC, 
			a.sch_ship_date ASC,
			a.order_no ASC,
			a.ext ASC

	-- 10.5 Get the order in hold for ship complete but not a backorder ordering by so priority, sch ship date, order and ext
	--		And the order type is RX
	INSERT	#wip (order_no, order_ext, so_priority_code, sch_ship_date, hold_type)
	SELECT	DISTINCT a.order_no,
			a.ext,
			CASE WHEN a.so_priority_code IS NULL THEN 9
				  WHEN a.so_priority_code = '' THEN 9
				  ELSE a.so_priority_code END,
			a.sch_ship_date,
			3
	FROM	dbo.orders a (NOLOCK)
	JOIN	dbo.tdc_pick_queue b (NOLOCK)
	ON		a.order_no = b.trans_type_no
	LEFT JOIN #wip c
	ON		a.order_no = c.order_no
	AND		a.ext = c.order_ext
	WHERE	a.user_category = 'RX'
	AND		a.status IN ('N','A','C') -- v1.4
	AND		a.who_entered <> 'BACKORDR'
	AND		a.type = 'I'
	AND		a.location = '001'
	AND		PATINDEX('%SHIP_COMP%',b.mfg_batch) > 0
	AND		PATINDEX('%REL_DATE%',b.mfg_batch) > 0
	AND		c.order_no IS NULL
	AND		c.order_ext IS NULL
	ORDER BY CASE WHEN a.so_priority_code IS NULL THEN 9
				  WHEN a.so_priority_code = '' THEN 9
				  ELSE a.so_priority_code END ASC, 
			a.sch_ship_date ASC,
			a.order_no ASC,
			a.ext ASC


	-- 11. Get the order in hold for release date but not a backorder ordering by so priority, sch ship date, order and ext
	--		And the order type is RX
	INSERT	#wip (order_no, order_ext, so_priority_code, sch_ship_date, hold_type)
	SELECT	DISTINCT a.order_no,
			a.ext,
			CASE WHEN a.so_priority_code IS NULL THEN 9
				  WHEN a.so_priority_code = '' THEN 9
				  ELSE a.so_priority_code END,
			a.sch_ship_date,
			1
	FROM	dbo.orders a (NOLOCK)
	JOIN	dbo.tdc_pick_queue b (NOLOCK)
	ON		a.order_no = b.trans_type_no
	LEFT JOIN #wip c
	ON		a.order_no = c.order_no
	AND		a.ext = c.order_ext
	WHERE	a.user_category = 'RX'
	AND		a.status IN ('N','A','C') -- v1.4
	AND		a.who_entered <> 'BACKORDR'
	AND		a.type = 'I'
	AND		a.location = '001'
	AND		PATINDEX('%SHIP_COMP%',b.mfg_batch) = 0
	AND		PATINDEX('%REL_DATE%',b.mfg_batch) > 0
	AND		c.order_no IS NULL
	AND		c.order_ext IS NULL
	ORDER BY CASE WHEN a.so_priority_code IS NULL THEN 9
				  WHEN a.so_priority_code = '' THEN 9
				  ELSE a.so_priority_code END ASC, 
			a.sch_ship_date ASC,
			a.order_no ASC,
			a.ext ASC

	-- 12. Get the order in hold for ship complete but not a backorder ordering by so priority, sch ship date, order and ext
	--		And the order type is ST
	INSERT	#wip (order_no, order_ext, so_priority_code, sch_ship_date, hold_type)
	SELECT	DISTINCT a.order_no,
			a.ext,
			CASE WHEN a.so_priority_code IS NULL THEN 9
				  WHEN a.so_priority_code = '' THEN 9
				  ELSE a.so_priority_code END,
			a.sch_ship_date,
			2
	FROM	dbo.orders a (NOLOCK)
	JOIN	dbo.tdc_pick_queue b (NOLOCK)
	ON		a.order_no = b.trans_type_no
	LEFT JOIN #wip c
	ON		a.order_no = c.order_no
	AND		a.ext = c.order_ext
	WHERE	a.user_category = 'ST'
	AND		a.status IN ('N','A','C') -- v1.4
	AND		a.who_entered <> 'BACKORDR'
	AND		a.type = 'I'
	AND		a.location = '001'
	AND		PATINDEX('%SHIP_COMP%',b.mfg_batch) > 0
	AND		PATINDEX('%REL_DATE%',b.mfg_batch) = 0
	AND		c.order_no IS NULL
	AND		c.order_ext IS NULL
	ORDER BY CASE WHEN a.so_priority_code IS NULL THEN 9
				  WHEN a.so_priority_code = '' THEN 9
				  ELSE a.so_priority_code END ASC, 
			a.sch_ship_date ASC,
			a.order_no ASC,
			a.ext ASC

	-- 12.5 Get the order in hold for ship complete but not a backorder ordering by so priority, sch ship date, order and ext
	--		And the order type is ST
	INSERT	#wip (order_no, order_ext, so_priority_code, sch_ship_date, hold_type)
	SELECT	DISTINCT a.order_no,
			a.ext,
			CASE WHEN a.so_priority_code IS NULL THEN 9
				  WHEN a.so_priority_code = '' THEN 9
				  ELSE a.so_priority_code END,
			a.sch_ship_date,
			3
	FROM	dbo.orders a (NOLOCK)
	JOIN	dbo.tdc_pick_queue b (NOLOCK)
	ON		a.order_no = b.trans_type_no
	LEFT JOIN #wip c
	ON		a.order_no = c.order_no
	AND		a.ext = c.order_ext
	WHERE	a.user_category = 'ST'
	AND		a.status IN ('N','A','C') -- v1.4
	AND		a.who_entered <> 'BACKORDR'
	AND		a.type = 'I'
	AND		a.location = '001'
	AND		PATINDEX('%SHIP_COMP%',b.mfg_batch) > 0
	AND		PATINDEX('%REL_DATE%',b.mfg_batch) > 0
	AND		c.order_no IS NULL
	AND		c.order_ext IS NULL
	ORDER BY CASE WHEN a.so_priority_code IS NULL THEN 9
				  WHEN a.so_priority_code = '' THEN 9
				  ELSE a.so_priority_code END ASC, 
			a.sch_ship_date ASC,
			a.order_no ASC,
			a.ext ASC


	-- 13. Get the order in hold for release date but not a backorder ordering by so priority, sch ship date, order and ext
	--		And the order type is ST
	INSERT	#wip (order_no, order_ext, so_priority_code, sch_ship_date, hold_type)
	SELECT	DISTINCT a.order_no,
			a.ext,
			CASE WHEN a.so_priority_code IS NULL THEN 9
				  WHEN a.so_priority_code = '' THEN 9
				  ELSE a.so_priority_code END,
			a.sch_ship_date,
			1
	FROM	dbo.orders a (NOLOCK)
	JOIN	dbo.tdc_pick_queue b (NOLOCK)
	ON		a.order_no = b.trans_type_no
	LEFT JOIN #wip c
	ON		a.order_no = c.order_no
	AND		a.ext = c.order_ext
	WHERE	a.user_category = 'ST'
	AND		a.status IN ('N','A','C') -- v1.4
	AND		a.who_entered <> 'BACKORDR'
	AND		a.type = 'I'
	AND		a.location = '001'
	AND		PATINDEX('%SHIP_COMP%',b.mfg_batch) = 0
	AND		PATINDEX('%REL_DATE%',b.mfg_batch) > 0
	AND		c.order_no IS NULL
	AND		c.order_ext IS NULL
	ORDER BY CASE WHEN a.so_priority_code IS NULL THEN 9
				  WHEN a.so_priority_code = '' THEN 9
				  ELSE a.so_priority_code END ASC, 
			a.sch_ship_date ASC,
			a.order_no ASC,
			a.ext ASC

	-- 14. Get the order in hold for ship complete but not a backorder ordering by so priority, sch ship date, order and ext
	--		And the order type is not RX or ST
	INSERT	#wip (order_no, order_ext, so_priority_code, sch_ship_date, hold_type)
	SELECT	DISTINCT a.order_no,
			a.ext,
			CASE WHEN a.so_priority_code IS NULL THEN 9
				  WHEN a.so_priority_code = '' THEN 9
				  ELSE a.so_priority_code END,
			a.sch_ship_date,
			2
	FROM	dbo.orders a (NOLOCK)
	JOIN	dbo.tdc_pick_queue b (NOLOCK)
	ON		a.order_no = b.trans_type_no
	LEFT JOIN #wip c
	ON		a.order_no = c.order_no
	AND		a.ext = c.order_ext
	WHERE	a.user_category NOT IN ('RX','ST')
	AND		a.status IN ('N','A','C') -- v1.4
	AND		a.who_entered <> 'BACKORDR'
	AND		a.type = 'I'
	AND		a.location = '001'
	AND		PATINDEX('%SHIP_COMP%',b.mfg_batch) > 0
	AND		PATINDEX('%REL_DATE%',b.mfg_batch) = 0
	AND		c.order_no IS NULL
	AND		c.order_ext IS NULL
	ORDER BY CASE WHEN a.so_priority_code IS NULL THEN 9
				  WHEN a.so_priority_code = '' THEN 9
				  ELSE a.so_priority_code END ASC, 
			a.sch_ship_date ASC,
			a.order_no ASC,
			a.ext ASC

	-- 14.5 Get the order in hold for ship complete but not a backorder ordering by so priority, sch ship date, order and ext
	--		And the order type is not RX or ST
	INSERT	#wip (order_no, order_ext, so_priority_code, sch_ship_date, hold_type)
	SELECT	DISTINCT a.order_no,
			a.ext,
			CASE WHEN a.so_priority_code IS NULL THEN 9
				  WHEN a.so_priority_code = '' THEN 9
				  ELSE a.so_priority_code END,
			a.sch_ship_date,
			3
	FROM	dbo.orders a (NOLOCK)
	JOIN	dbo.tdc_pick_queue b (NOLOCK)
	ON		a.order_no = b.trans_type_no
	LEFT JOIN #wip c
	ON		a.order_no = c.order_no
	AND		a.ext = c.order_ext
	WHERE	a.user_category NOT IN ('RX','ST')
	AND		a.status IN ('N','A','C') -- v1.4
	AND		a.who_entered <> 'BACKORDR'
	AND		a.type = 'I'
	AND		a.location = '001'
	AND		PATINDEX('%SHIP_COMP%',b.mfg_batch) > 0
	AND		PATINDEX('%REL_DATE%',b.mfg_batch) > 0
	AND		c.order_no IS NULL
	AND		c.order_ext IS NULL
	ORDER BY CASE WHEN a.so_priority_code IS NULL THEN 9
				  WHEN a.so_priority_code = '' THEN 9
				  ELSE a.so_priority_code END ASC, 
			a.sch_ship_date ASC,
			a.order_no ASC,
			a.ext ASC


	-- 15. Get the order in hold for release date but not a backorder ordering by so priority, sch ship date, order and ext
	--		And the order type is not RX or ST
	INSERT	#wip (order_no, order_ext, so_priority_code, sch_ship_date, hold_type)
	SELECT	DISTINCT a.order_no,
			a.ext,
			CASE WHEN a.so_priority_code IS NULL THEN 9
				  WHEN a.so_priority_code = '' THEN 9
				  ELSE a.so_priority_code END,
			a.sch_ship_date,
			1
	FROM	dbo.orders a (NOLOCK)
	JOIN	dbo.tdc_pick_queue b (NOLOCK)
	ON		a.order_no = b.trans_type_no
	LEFT JOIN #wip c
	ON		a.order_no = c.order_no
	AND		a.ext = c.order_ext
	WHERE	a.user_category NOT IN ('RX','ST')
	AND		a.status IN ('N','A','C') -- v1.4
	AND		a.who_entered <> 'BACKORDR'
	AND		a.type = 'I'
	AND		a.location = '001'
	AND		PATINDEX('%SHIP_COMP%',b.mfg_batch) = 0
	AND		PATINDEX('%REL_DATE%',b.mfg_batch) > 0
	AND		c.order_no IS NULL
	AND		c.order_ext IS NULL
	ORDER BY CASE WHEN a.so_priority_code IS NULL THEN 9
				  WHEN a.so_priority_code = '' THEN 9
				  ELSE a.so_priority_code END ASC, 
			a.sch_ship_date ASC,
			a.order_no ASC,
			a.ext ASC

--select a.*,b.* from #wip a join ord_list b on a.order_no = b.order_no and a.order_ext = b.order_ext

--return

	-- Now loop through the results and process them depending on the hold type
	SET @last_id = 0

	SELECT	TOP 1 @id = id,
			@hold_type = hold_type,
			@order_no = order_no,
			@order_ext = order_ext
	FROM	#wip
	WHERE	id > @last_id
	ORDER BY id ASC

	WHILE @@ROWCOUNT <> 0
	BEGIN

		-- BackOrders
		IF (@hold_type = 0)
		BEGIN
			EXEC cvo_allocate_backorders_sp @order_no, @order_ext
		END
	
		-- Ship Complete
		IF (@hold_type = 2)
		BEGIN
			EXEC dbo.cvo_release_hold_ship_complete_allocations_sp @order_no, @order_ext
		END

		-- Ship Complete and rel date
		IF (@hold_type = 3)
		BEGIN
			EXEC cvo_allocate_backorders_sp @order_no, @order_ext
			EXEC dbo.cvo_release_rel_date_held_allocations_sp @order_no, @order_ext
			EXEC dbo.cvo_release_hold_ship_complete_allocations_sp @order_no, @order_ext
		END


		-- Release Date
		IF (@hold_type = 1)
		BEGIN
			EXEC dbo.cvo_release_rel_date_held_allocations_sp @order_no, @order_ext
		END

		SET @last_id = @id

		SELECT	TOP 1 @id = id,
				@hold_type = hold_type,
				@order_no = order_no,
				@order_ext = order_ext
		FROM	#wip
		WHERE	id > @last_id
		ORDER BY id ASC

	END

	DROP TABLE #wip

END
GO
GRANT EXECUTE ON  [dbo].[cvo_process_backorder_held_orders_sp] TO [public]
GO
