SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
declare @msg varchar(100)
exec tdc_get_order_list_status 1420538, 0, 1, @msg OUTPUT
select @msg


*/
CREATE PROCEDURE [dbo].[tdc_get_order_list_status] 
	@order_no INT,
	@ext INT,
	@line_no INT,
	@msg VARCHAR(100) OUTPUT 
AS

SET NOCOUNT ON

DECLARE @ORD VARCHAR(20), @PCK VARCHAR(20), @PAK VARCHAR(20), @CRT VARCHAR(20)
DECLARE @STG VARCHAR(20), @VER VARCHAR(20), @MAN VARCHAR(20), @ALC VARCHAR(20), @location VARCHAR(10)
DECLARE @status CHAR(2), @type VARCHAR(2), @qty DECIMAL(20, 8) 
DECLARE @parent INT, @child INT
DECLARE @multiple_flag char(1), @carton char(1) 
DECLARE @qty_man DECIMAL(20, 8), @qty_ver DECIMAL(20, 8), @conv_factor DECIMAL(20, 8)
DECLARE @qty_pak DECIMAL(20, 8), @qty_stg DECIMAL(20, 8), @qty_crt DECIMAL(20, 8)

DECLARE @SOF		varchar(20), -- v1.1
		@sa_stock	decimal(20,8), -- v1.2
		@alloc_qty	decimal(20,8), -- v1.2
		@pack_qty	decimal(20,8) -- v1.3

SELECT @msg = '', @status = '', @PCK = '' 
SELECT @ORD = '', @MAN = '', 	@STG = '' 
SELECT @PAK = '', @VER = '', 	@CRT = '', @ALC = ''

SELECT @SOF = '' -- v1.1

SELECT @status = status, @type = type, @multiple_flag = multiple_flag 
	FROM orders_all (nolock) -- v1.0
		WHERE order_no = @order_no AND ext = @ext

/*************************************************************************************************/
/* TDC does not have control to the following orders */
IF(((@status = 'M') OR (@multiple_flag = 'Y')) AND (@ext = 0)) OR (@type = 'C')
BEGIN
	RETURN 0
END

IF NOT EXISTS (	SELECT 1 FROM tdc_dist_item_list (nolock) WHERE order_no = @order_no AND order_ext = @ext AND [function] = 'S')
	--IF NOT EXISTS (	SELECT * FROM tdc_bkp_dist_item_list (nolock) WHERE order_no = @order_no AND order_ext = @ext AND [function] = 'S')
		RETURN 0

-- v1.0
--SELECT @qty = SUM(shipped) 
--	FROM ord_list (nolock) 
--		WHERE order_no = @order_no AND order_ext = @ext

-- v1.0
IF EXISTS ( SELECT 1 FROM ord_list (nolock) WHERE order_no = @order_no AND order_ext = @ext AND shipped <> 0)
	SET @qty = 1
ELSE
	SET @qty = 0


IF (@qty > 0)
	IF NOT EXISTS (SELECT * FROM tdc_dist_item_pick (nolock) WHERE order_no = @order_no AND order_ext = @ext AND [function] = 'S')
		--IF NOT EXISTS (SELECT * FROM tdc_bkp_dist_item_pick (nolock) WHERE order_no = @order_no AND order_ext = @ext AND [function] = 'S')
			RETURN 0

/**************************************************************************************************/
/* what ever the order has not been picked, or has been shipped, or being processed we display the */
/* ordered qty and shipped qt */

SELECT @ORD = RTRIM(LTRIM(STR(ordered, 15, 2))), @PCK = RTRIM(LTRIM(STR(shipped, 15, 2))), @conv_factor = conv_factor, @location = location, -- v1.4 @sa_stock = ordered, -- v1.2
		@pack_qty = shipped -- v1.3
  FROM ord_list (nolock)
 WHERE order_no = @order_no 
   AND order_ext = @ext 
   AND line_no = @line_no

-- v1.4 Start
SELECT	@sa_stock = a.ordered
FROM	ord_list a (NOLOCK)
JOIN	cvo_orders_all b (NOLOCK)
ON		a.order_no = b.order_no
AND		a.order_ext = b.ext
WHERE	a.order_no = @order_no 
AND		a.order_ext = @ext 
AND		a.line_no = @line_no
AND		b.allocation_date <= GETDATE()
IF (@sa_stock IS NULL)
	SET @sa_stock = 0
-- v1.4 End

-- v1.6 Start
IF EXISTS (SELECT 1 FROM cvo_soft_alloc_det (NOLOCK) WHERE order_no = @order_no AND order_ext = @ext AND line_no = @line_no AND status = -3)
BEGIN
	SET @sa_stock = 0
END
-- v1.6 End

SELECT @ALC = RTRIM(LTRIM(STR(SUM(qty), 15, 2))), @alloc_qty = SUM(qty) -- v1.2
	FROM tdc_soft_alloc_tbl (NOLOCK)
		WHERE order_no = @order_no 
		  AND order_ext = @ext 
		  AND order_type = 'S'
		  AND location = @location
		  AND line_no = @line_no

IF @ALC = '' OR @ALC IS NULL	-- SCR 34479 -- v1.2
BEGIN
	SELECT @ALC = '0.00'
	SET @alloc_qty = 0 -- v1.2
END


-- v1.2 Start
SET @sa_stock = @sa_stock - @alloc_qty - @pack_qty

-- v1.8 Start
IF NOT EXISTS (SELECT 1 FROM cvo_soft_alloc_det (NOLOCK) WHERE order_no = @order_no AND order_ext = @ext AND line_no = @line_no)
BEGIN
	IF (@sa_stock < 0)
		SET @sa_stock = 0
END

IF EXISTS (SELECT 1 FROM cvo_orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @ext AND allocation_date > GETDATE())
BEGIN
	IF EXISTS (SELECT 1 FROM tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @order_no AND order_ext = @ext AND order_type = 'S'
				AND location = @location AND line_no = @line_no)
	BEGIN
		IF (@sa_stock < 0)
			SET @sa_stock = @sa_stock + @alloc_qty
	END
END

-- v1.8 End

--SELECT	@sa_stock = ISNULL(SUM(CASE WHEN a.deleted = 1 THEN (a.quantity * -1) ELSE a.quantity END),0) - ISNULL(SUM(b.qty),0)
--FROM	dbo.cvo_soft_alloc_det a (NOLOCK)
--LEFT JOIN tdc_soft_alloc_tbl b (NOLOCK)
--ON		a.order_no = b.order_no
--AND		a.order_ext = b.order_ext
--AND		a.part_no = b.part_no
--WHERE	a.status IN (-1,0,1) -- -1 = selected for allocation, 0 = ready for allocation, 1 = being edited
--AND		a.order_no = @order_no
--AND		a.order_ext = @ext
--AND		a.line_no = @line_no
--AND		a.location = @location

-- v1.5 Start
IF EXISTS (SELECT 1 FROM cvo_soft_alloc_start (NOLOCK) WHERE order_no = @order_no AND order_ext = @ext)
BEGIN -- Pre soft alloc
	SET @sa_stock = 0
END
-- v1.5 End

-- v1.9 Start
IF (@sa_stock < 0)
BEGIN
	SET @alloc_qty = @alloc_qty + @sa_stock
	SET @sa_Stock = 0
	IF (@alloc_qty > 0)
		SET @ALC = RTRIM(LTRIM(STR(@alloc_qty, 15, 2)))		
END
-- v1.9 End

-- v1.1 Start
SELECT	@SOF = RTRIM(LTRIM(STR(SUM(@sa_stock),15,2)))
--FROM	cvo_soft_alloc_det (NOLOCK)
--WHERE	order_no = @order_no 
--AND		order_ext = @ext 
--AND		location = @location
--AND		line_no = @line_no
--AND		status IN (-1,0,1) -- -1 = selected for allocation, 0 = ready for allocation, 1 = being edited
-- v1.2 End


-- TAG
IF @SOF = '' OR @SOF IS NULL SELECT @SOF = '0.00'

-- START v1.7
IF @status = 'V'
BEGIN
	SET @SOF = '0.00'
END
-- END v1.7

SELECT @msg = 'ORD ' + @ORD + ',  SOF ' + @SOF + ',  ALC ' + @ALC + ',  PCK ' + @PCK
--SELECT @msg = 'ORD ' + @ORD + ',  ALC ' + @ALC + ',  PCK ' + @PCK
-- v1.1 End

IF(@qty = 0) RETURN 0

--Call 799080BRK
IF(@status <= 'Q') RETURN 0

-- IF EXISTS (SELECT * FROM tdc_carton_tx (nolock) WHERE order_no = @order_no AND order_ext = @ext AND order_type = 'S')
-- 	SELECT @carton = 'Y'

-- IF(@status < 'R')
-- BEGIN
-- 	IF NOT EXISTS (	SELECT * FROM tdc_dist_group g (nolock), tdc_dist_item_pick i (nolock)
-- 			WHERE g.child_serial_no = i.child_serial_no AND g.[function] = 'S' 
-- 			AND i.[function] = 'S' AND i.order_no = @order_no AND i.order_ext = @ext AND i.line_no = @line_no ) 
	SELECT @qty_pak = ISNULL(SUM(pack_qty) ,0)
	  FROM tdc_carton_detail_tx (nolock)
	 WHERE order_no = @order_no AND order_ext = @ext AND line_no = @line_no 
		--RETURN 0
IF @qty_pak > 0
	SELECT @msg = @msg + ',  PAK ' + RTRIM(LTRIM(STR(@qty_pak, 15, 2)))

RETURN 0

-- END
-- ELSE
-- BEGIN
-- 	IF(@carton != 'Y')
-- 	BEGIN
-- 		IF NOT EXISTS (SELECT * FROM tdc_bkp_dist_group g (nolock), tdc_bkp_dist_item_pick i (nolock)
-- 					WHERE g.child_serial_no = i.child_serial_no AND g.[function] = 'S' 
-- 					AND i.[function] = 'S' AND i.order_no = @order_no AND i.order_ext = @ext AND i.line_no = @line_no)
-- 		BEGIN
-- 			SELECT @msg = @msg + ',  VER ' + @PCK
-- 			RETURN 0
-- 		END		
-- 	END
-- END

-- SELECT @status = tdc_status FROM tdc_order (nolock) WHERE order_no = @order_no AND order_ext = @ext
-- 
-- CREATE TABLE #temp_tb1(
-- 	parent INT NOT NULL,
-- 	child INT NOT NULL,
-- 	type VARCHAR(2) NOT NULL,
-- 	qty DECIMAL(20, 8) NOT NULL
-- )
-- 
-- CREATE TABLE #temp_tb2(
-- 	parent_id INT NOT NULL,
-- 	child_id INT NOT NULL,
-- 	type VARCHAR(2) NOT NULL,
-- 	qty DECIMAL(20, 8) NOT NULL
-- )
-- 
-- CREATE TABLE #temp_tb3(
-- 	type VARCHAR(2) NOT NULL,
-- 	qty DECIMAL(20, 8) NOT NULL
-- )
-- 
-- IF (@status = 'R1') AND (@carton != 'Y')	-- look into back up tables
-- BEGIN 
-- 	INSERT INTO #temp_tb1 (parent, child, type, qty)
-- 		SELECT DISTINCT g.parent_serial_no, g.child_serial_no, g.type, g.quantity 
-- 		FROM tdc_bkp_dist_group g (nolock), tdc_bkp_dist_item_pick i (nolock)
-- 		WHERE g.child_serial_no = i.child_serial_no AND g.[function] = 'S' 
-- 		AND i.[function] = 'S' AND i.order_no = @order_no AND i.order_ext = @ext
-- 		AND i.line_no = @line_no
-- 
-- 	WHILE EXISTS (SELECT parent_serial_no 
-- 			FROM tdc_bkp_dist_group (nolock)
-- 			WHERE child_serial_no IN (SELECT DISTINCT parent FROM #temp_tb1) AND [function] = 'S')
-- 	BEGIN
-- 		INSERT INTO #temp_tb2 (parent_id, child_id, type, qty)	
-- 			SELECT DISTINCT parent_serial_no, child_serial_no, type, quantity
-- 				FROM tdc_bkp_dist_group (nolock)	
-- 					WHERE child_serial_no IN (SELECT DISTINCT parent FROM #temp_tb1) AND [function] = 'S'
-- 
-- 		DELETE FROM #temp_tb2 	WHERE parent_id IN (SELECT DISTINCT parent FROM #temp_tb1)
-- 					AND child_id IN (SELECT DISTINCT child FROM #temp_tb1)
-- 					AND type IN (SELECT DISTINCT type FROM #temp_tb1)
-- 
-- 		IF EXISTS (SELECT * FROM #temp_tb2)
-- 			INSERT INTO #temp_tb1 (parent, child, type, qty) SELECT parent_id, child_id, type, qty FROM #temp_tb2
-- 		ELSE 
-- 			BREAK
-- 	END
-- END
-- ELSE
-- BEGIN 
-- 	INSERT INTO #temp_tb1 (parent, child, type, qty) 
-- 		SELECT DISTINCT g.parent_serial_no, g.child_serial_no, g.type, g.quantity 
-- 			FROM tdc_dist_group g (nolock), tdc_dist_item_pick i (nolock)
-- 				WHERE g.child_serial_no = i.child_serial_no
-- 				AND g.[function] = 'S' AND i.[function] = 'S' AND i.line_no = @line_no
-- 				AND i.order_no = @order_no AND i.order_ext = @ext
-- 				
-- 	WHILE EXISTS (SELECT parent_serial_no 	FROM tdc_dist_group (nolock)
-- 						WHERE child_serial_no IN (SELECT DISTINCT parent FROM #temp_tb1) 
-- 						AND [function] = 'S')
-- 	BEGIN
-- 		INSERT INTO #temp_tb2 (parent_id, child_id, type, qty) 
-- 			SELECT DISTINCT parent_serial_no, child_serial_no, type, quantity
-- 				FROM tdc_dist_group (nolock)	
-- 					WHERE child_serial_no IN (SELECT DISTINCT parent FROM #temp_tb1) AND [function] = 'S'
-- 
-- 		DELETE FROM #temp_tb2 	WHERE parent_id IN (SELECT DISTINCT parent FROM #temp_tb1)
-- 					AND child_id IN (SELECT DISTINCT child FROM #temp_tb1)
-- 					AND type IN (SELECT DISTINCT type FROM #temp_tb1)
-- 
-- 		IF EXISTS (SELECT * FROM #temp_tb2)
-- 			INSERT INTO #temp_tb1 (parent, child, type, qty) SELECT parent_id, child_id, type, qty FROM #temp_tb2
-- 		ELSE 
-- 			BREAK
-- 	END
-- END
-- 
-- INSERT INTO #temp_tb3 (type, qty) SELECT type, SUM(qty) FROM #temp_tb1 GROUP BY type

/**********************************************************************************************/
/* loop through each type to get its qty */

-- SELECT @qty_pak = 0.0, @qty_man = 0.0, @type = NULL
-- SELECT @qty_crt = 0.0, @qty_stg = 0.0, @qty_ver = 0.0

-- DECLARE get_qty CURSOR FOR SELECT * FROM #temp_tb3 
-- 
-- OPEN get_qty
-- FETCH NEXT FROM get_qty INTO @type, @qty
-- 
-- WHILE (@@FETCH_STATUS = 0)
-- BEGIN
-- 	SELECT @qty = @qty / @conv_factor 
-- 
-- 	IF @type = 'P1'
-- 	BEGIN
-- 		SELECT @PAK = 'P1'
-- 		SELECT @qty_pak = @qty 
-- 	END
-- 	
-- 	IF @type = 'N1' 	
-- 	BEGIN
-- 		SELECT @CRT = 'N1'
-- 		SELECT @qty_crt = @qty
-- 	END
-- 
-- 	IF @type = 'S1'  	
-- 	BEGIN
-- 		SELECT @STG = 'S1'
-- 		SELECT @qty_stg = @qty
-- 	END
-- 
-- 	IF @type = 'M1'  	
-- 	BEGIN
-- 		SELECT @MAN = 'M1'
-- 		SELECT @qty_man = @qty
-- 	END
-- 
-- 	FETCH NEXT FROM get_qty INTO @type, @qty
-- END
-- 
-- CLOSE get_qty
-- DEALLOCATE get_qty

-- IF LEN(@PAK) > 0
-- 	SELECT @msg = @msg + ',  PAK ' + RTRIM(LTRIM(STR(@qty_pak, 15, 2)))
-- 
-- IF LEN(@CRT) > 0
-- 	SELECT @msg = @msg + ',  CRT ' + RTRIM(LTRIM(STR(@qty_crt, 15, 2)))
-- 
-- IF LEN(@STG) > 0
-- 	SELECT @msg = @msg + ',  STG ' + RTRIM(LTRIM(STR(@qty_stg, 15, 2)))
-- 
-- IF LEN(@MAN) > 0
-- 	SELECT @msg = @msg + ',  MAN ' + RTRIM(LTRIM(STR(@qty_man, 15, 2)))
-- 
-- IF (@status = 'R1')
-- BEGIN
-- 	SELECT @msg = @msg + ',  VER ' + RTRIM(LTRIM(STR(@PCK, 15, 2)))
-- END
-- ELSE
-- BEGIN
-- 	IF EXISTS (SELECT * FROM tdc_dist_group g (nolock), tdc_dist_item_pick p (nolock)
-- 				WHERE p.order_no = @order_no AND p.order_ext = @ext AND g.status = 'V'
-- 				AND p.line_no = @line_no AND g.child_serial_no = p.child_serial_no 
-- 				AND p.[function] = 'S' AND g.[function] = 'S' )
-- 	BEGIN
-- 		SELECT @qty_ver = (SELECT SUM(g.quantity / @conv_factor) 
-- 					FROM tdc_dist_group g (nolock), tdc_dist_item_pick p (nolock) 
-- 					WHERE p.order_no = @order_no AND p.order_ext = @ext AND g.status = 'V'
-- 					AND p.line_no = @line_no AND g.child_serial_no = p.child_serial_no) 
-- 
-- 		SELECT @msg = @msg + ',  VER ' + RTRIM(LTRIM(STR(@qty_ver, 15, 2)))
-- 	END	
-- END

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_get_order_list_status] TO [public]
GO
