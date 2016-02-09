
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/* 1/31/16
1
011-TRUNK
1011-TRUNK
304 - NELS
426 - OLTH
530 - SEST
728 - COWL
785 - KNOX
Nordstrom
*/
/*
BEGIN TRAN 
	EXEC dbo.cvo_stock_sync_sp 1, 'Nordstrom' -- Report only for location 001

	EXEC dbo.cvo_stock_sync_sp 1, '001' -- Run for location 001

	EXEC dbo.cvo_stock_sync_sp 0, '503 - scha' -- Report only for location 001	
	EXEC dbo.cvo_stock_sync_sp 0, 'UK' -- Report only for location 	
ROLLBACK TRAN
COMMIT TRAN
*/

CREATE PROC [dbo].[cvo_stock_sync_sp]	@run		smallint = 0, 
									@location	varchar(10) = NULL
AS
BEGIN

	SET NOCOUNT ON
	
	DECLARE	@id			int,
			@last_id	int,
			@loc		varchar(10),
			@part_no	varchar(30),
			@quantity	decimal(20,8)

	CREATE TABLE #lb_stock (
		location	varchar(10),	
		part_no		varchar(30),
		quantity	decimal(20,8))

	CREATE TABLE #inv_stock (
		location	varchar(10),	
		part_no		varchar(30),
		quantity	decimal(20,8))

	CREATE TABLE #inv_compare (
		id				int IDENTITY(1,1),
		location		varchar(10),
		part_no			varchar(30),
		inv_stock		decimal(20,8),
		lb_stock		decimal(20,8),
		diff_stock		decimal(20,8),
		no_loc			smallint,
		issue_qty		decimal(20,8),
		act_issue_qty	decimal(20,8),
		sales_qty		decimal(20,8),
		act_sales_qty	decimal(20,8),
		xfer_qty		decimal(20,8),
		act_xfer_qty	decimal(20,8),
		rec_qty			decimal(20,8),
		act_rec_qty		decimal(20,8))

	-- Get records from lot_bin_stock for all locations and parts
	INSERT	#lb_stock
	SELECT	location,
			part_no,
			SUM(qty)
	FROM	lot_bin_stock (NOLOCK)
	WHERE	(location = @location OR @location IS NULL)
	GROUP BY location, part_no

	-- Get records from inventory for all locations and parts
	INSERT	#inv_stock
	SELECT	l.location,
			l.part_no,
			SUM(CASE WHEN (m.status='C' or m.status='V') THEN 0 
				ELSE (l.in_stock + l.issued_mtd + p.produced_mtd - p.usage_mtd - s.sales_qty_mtd + r.recv_mtd + x.xfer_mtd) END)
	FROM	inv_list l (NOLOCK)  
	JOIN	inv_master m (NOLOCK) 
	ON		m.part_no = l.part_no  
	JOIN	inv_produce p (NOLOCK) 
	ON		p.part_no = m.part_no 
	AND		p.location = l.location  
	JOIN	inv_sales s (NOLOCK) 
	ON		s.part_no = m.part_no 
	AND		s.location = l.location  
	JOIN	inv_xfer x (NOLOCK) 
	ON		x.part_no = m.part_no 
	AND		x.location = l.location  
	JOIN	inv_recv r (NOLOCK) 
	ON		r.part_no = m.part_no 
	AND		r.location = l.location  
	WHERE	(l.location = @location OR @location IS NULL)
	GROUP BY l.location, l.part_no

	CREATE index #lb_stock_1 ON #lb_stock(location, part_no)
	CREATE index #inv_stock_1 ON #inv_stock(location, part_no)

	-- Use inventory as the basis for location and parts
	INSERT	#inv_compare 
	SELECT	location,
			part_no, 
			quantity, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	FROM	#inv_stock

	-- Get any location/part in lot bin stock that does not exist in inventory
	INSERT	#inv_compare 
	SELECT	a.location,
			a.part_no, 
			0, SUM(a.quantity), 0, 1, 0, 0, 0, 0, 0, 0, 0, 0
	FROM	#lb_stock a
	LEFT JOIN #inv_compare b
	ON		a.location = b.location
	AND		a.part_no = b.part_no
	WHERE	b.location IS NULL
	AND		b.part_no IS NULL
	AND		(a.location = @location OR @location IS NULL)
	GROUP BY a.location, a.part_no

	-- Update the lot bin stock quantity
	UPDATE	a
	SET		lb_stock = b.quantity
	FROM	#inv_compare a
	JOIN	#lb_stock b
	ON		a.location = b.location
	AND		a.part_no = b.part_no

	UPDATE	#inv_compare
	SET		lb_stock = 0
	WHERE	lb_stock IS NULL

	-- Calc the diff
	UPDATE	#inv_compare
	SET		diff_stock = lb_stock - inv_stock

	-- Get the issue quantites from iventory
	UPDATE	a
	SET		issue_qty = b.issued_mtd
	FROM	#inv_compare a
	JOIN	inv_list b (NOLOCK)
	ON		a.location = b.location
	AND		a.part_no = b.part_no

	-- Get the issue quantites from issues
	UPDATE	a
	SET		act_issue_qty = ISNULL((SELECT SUM(qty * direction) FROM issues (NOLOCK) WHERE location_from = a.location AND part_no = a.part_no AND ISNULL(inventory,'') = 'N'),0)
	FROM	#inv_compare a

	-- Get the sales quantites from iventory
	UPDATE	a
	SET		sales_qty = b.sales_qty_mtd
	FROM	#inv_compare a
	JOIN	inv_sales b (NOLOCK)
	ON		a.location = b.location
	AND		a.part_no = b.part_no

	-- Get the sales quantites from orders
	UPDATE	a
	SET		act_sales_qty = ISNULL((SELECT SUM(shipped - cr_shipped) FROM ord_list (NOLOCK) WHERE location = a.location AND part_no = a.part_no AND status NOT IN ('V','Q') AND status > 'N'),0)
	FROM	#inv_compare a

	-- Get the xfer quantites from iventory
	UPDATE	a
	SET		xfer_qty = b.xfer_mtd
	FROM	#inv_compare a
	JOIN	inv_xfer b (NOLOCK)
	ON		a.location = b.location
	AND		a.part_no = b.part_no

	-- Get the xfer quantites from transfers in
	UPDATE	a
	SET		act_xfer_qty = ISNULL((SELECT SUM(shipped) FROM xfer_list (NOLOCK) WHERE to_loc = a.location AND part_no = a.part_no AND status <> 'V' AND status > 'P'),0)
	FROM	#inv_compare a

	-- Get the xfer quantites from transfers out
	UPDATE	a
	SET		act_xfer_qty = act_xfer_qty - (ISNULL((SELECT SUM(shipped) FROM xfer_list (NOLOCK) WHERE from_loc = a.location AND part_no = a.part_no AND status <> 'V' AND status > 'P'),0))
	FROM	#inv_compare a

	-- Get the receipts quantites from iventory
	UPDATE	a
	SET		rec_qty = b.recv_mtd
	FROM	#inv_compare a
	JOIN	inv_recv b (NOLOCK)
	ON		a.location = b.location
	AND		a.part_no = b.part_no

	-- Get the receipt quantites from transfers in
	UPDATE	a
	SET		act_rec_qty = ISNULL((SELECT SUM(qty * direction) FROM lot_bin_recv (NOLOCK) WHERE location = a.location AND part_no = a.part_no),0)
	FROM	#inv_compare a

	IF @run = 0
	BEGIN
		SELECT * FROM #inv_compare WHERE diff_stock <> 0 order by location, part_no
		RETURN
	END

	SELECT GETDATE() RunTime, 'Stock Sync Process Started'

	SET @last_id = 0

	SELECT	TOP 1 @id = id,
			@loc = location,
			@part_no = part_no,
			@quantity = diff_stock
	FROM	#inv_compare
	WHERE	id > @last_id
	AND		diff_stock <> 0
	ORDER BY id ASC

	WHILE @@ROWCOUNT <> 0
	BEGIN	

		-- If the no_loc flag is set then stock exists in lot bin stock for an invalid location/part
		IF	EXISTS (SELECT 1 FROM #inv_compare WHERE id = @id AND no_loc = 1)
		BEGIN
			UPDATE	lot_bin_stock
			SET		qty = 0
			WHERE	location = @loc
			AND		part_no = @part_no

			DELETE	lot_bin_stock
			WHERE	qty = 0
			AND		location = @loc
			AND		part_no = @part_no

			SELECT GETDATE() RunTime, 'Location:' + @loc + ' Part:' + @part_no + ' - Non existant location/part, lot_bin_stock record removed'
			
			SET @last_id = @id

			SELECT	TOP 1 @id = id,
					@loc = location,
					@part_no = part_no,
					@quantity = diff_stock
			FROM	#inv_compare
			WHERE	id > @last_id
			AND		diff_stock <> 0
			ORDER BY id ASC

			CONTINUE
		END

		-- Check if the differenace is obvious 
		-- Issues
		IF EXISTS (SELECT 1 FROM #inv_compare WHERE id = @id AND issue_qty <> act_issue_qty)
		BEGIN
			UPDATE	inv_list
			SET		issued_mtd = issued_mtd + @quantity,
					issued_ytd = issued_ytd + @quantity
			WHERE	location = @loc
			AND		part_no = @part_no
			
			SELECT GETDATE() RunTime, 'Location:' + @loc + ' Part:' + @part_no + ' - Update inv_list, applied ' + LTRIM(CAST(@quantity as varchar(30))) + ' to/from inventory'

			SET @last_id = @id
			 
			SELECT	TOP 1 @id = id,
					@loc = location,
					@part_no = part_no,
					@quantity = diff_stock
			FROM	#inv_compare
			WHERE	id > @last_id
			AND		diff_stock <> 0
			ORDER BY id ASC

			CONTINUE
		END

		-- transfer
		IF EXISTS (SELECT 1 FROM #inv_compare WHERE id = @id AND xfer_qty <> act_xfer_qty)
		BEGIN
			UPDATE	inv_xfer
			SET		xfer_mtd = xfer_mtd + @quantity,
					xfer_ytd = xfer_ytd + @quantity
			WHERE	location = @loc
			AND		part_no = @part_no
			
			SELECT GETDATE() RunTime, 'Location:' + @loc + ' Part:' + @part_no + ' - Update inv_xfer, applied ' + LTRIM(CAST(@quantity as varchar(30))) + ' to/from inventory'

			SET @last_id = @id

			SELECT	TOP 1 @id = id,
					@loc = location,
					@part_no = part_no,
					@quantity = diff_stock
			FROM	#inv_compare
			WHERE	id > @last_id
			AND		diff_stock <> 0
			ORDER BY id ASC

			CONTINUE
		END

		-- receipts
		IF EXISTS (SELECT 1 FROM #inv_compare WHERE id = @id AND rec_qty <> act_rec_qty)
		BEGIN
			UPDATE	inv_recv
			SET		recv_mtd = recv_mtd + @quantity,
					recv_ytd = recv_ytd + @quantity
			WHERE	location = @loc
			AND		part_no = @part_no

			SELECT GETDATE() RunTime, 'Location:' + @loc + ' Part:' + @part_no + ' - Update inv_recv, applied ' + LTRIM(CAST(@quantity as varchar(30))) + ' to/from inventory'
			
			SET @last_id = @id

			SELECT	TOP 1 @id = id,
					@loc = location,
					@part_no = part_no,
					@quantity = diff_stock
			FROM	#inv_compare
			WHERE	id > @last_id
			AND		diff_stock <> 0
			ORDER BY id ASC

			CONTINUE
		END


		-- If we get here then adjust sales
		UPDATE	inv_sales 
		SET		sales_qty_mtd = sales_qty_mtd - @quantity,
				sales_qty_ytd = sales_qty_ytd - @quantity
		WHERE	location = @loc
		AND		part_no = @part_no
			
		SELECT GETDATE() RunTime, 'Location:' + @loc + ' Part:' + @part_no + ' - Update inv_sales, applied ' + LTRIM(CAST(@quantity as varchar(30))) + ' to/from inventory'

		SET @last_id = @id

		SELECT	TOP 1 @id = id,
				@loc = location,
				@part_no = part_no,
				@quantity = diff_stock
		FROM	#inv_compare
		WHERE	id > @last_id
		AND		diff_stock <> 0
		ORDER BY id ASC

	END

	SELECT GETDATE() RunTime, 'Stock Sync Process Finnished'

END
GO

GRANT EXECUTE ON  [dbo].[cvo_stock_sync_sp] TO [public]
GO
