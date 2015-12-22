SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_get_xfer_list_status] 
	@xfer_no INT,
	@line_no INT,
	@msg VARCHAR(100) OUTPUT 
AS

------------------------------------------------------------------------------

DECLARE @ORD VARCHAR(20), @PCK VARCHAR(20), @PAK VARCHAR(20), @CRT VARCHAR(20)
DECLARE @STG VARCHAR(20), @VER VARCHAR(20), @MAN VARCHAR(20), @ALC VARCHAR(20), @location VARCHAR(10)
DECLARE @status CHAR(2), @type VARCHAR(2), @qty DECIMAL(20, 8) 
DECLARE @parent INT, @child INT
DECLARE @qty_man DECIMAL(20, 8), @qty_ver DECIMAL(20, 8), @conv_factor DECIMAL(20, 8)
DECLARE @qty_pak DECIMAL(20, 8), @qty_stg DECIMAL(20, 8), @qty_crt DECIMAL(20, 8)

SELECT @msg = '', @status = '', @PCK = '' 
SELECT @ORD = '', @MAN = '', 	@STG = '' 
SELECT @PAK = '', @VER = '', 	@CRT = '', @ALC = ''

/*************************************************************************************************/

/* TDC does not have control to the following orders */
IF NOT EXISTS (SELECT * FROM tdc_xfers (nolock) WHERE xfer_no = @xfer_no )
	RETURN 0

IF NOT EXISTS (	SELECT * FROM tdc_dist_item_list (nolock) WHERE order_no = @xfer_no AND [function] = 'T')
	IF NOT EXISTS (	SELECT * FROM tdc_bkp_dist_item_list (nolock) WHERE order_no = @xfer_no AND [function] = 'T')
		RETURN 0

SELECT @qty = SUM(shipped) FROM xfer_list (nolock) WHERE xfer_no = @xfer_no

IF (@qty > 0)
	IF NOT EXISTS (SELECT * FROM tdc_dist_item_pick (nolock) WHERE order_no = @xfer_no AND [function] = 'T')
		IF NOT EXISTS (SELECT * FROM tdc_bkp_dist_item_pick (nolock) WHERE order_no = @xfer_no AND [function] = 'T')
			RETURN 0

/**************************************************************************************************/
/* what ever the order has not been picked, or has been shipped, or being processed we display the */
/* ordered qty and shipped qty */

SELECT @ORD = RTRIM(LTRIM(STR(ordered, 15, 2))), @PCK = RTRIM(LTRIM(STR(shipped, 15, 2))), @conv_factor	= conv_factor, @location = from_loc
  FROM xfer_list (nolock)
 WHERE xfer_no = @xfer_no 
   AND line_no = @line_no

SELECT @ALC = RTRIM(LTRIM(STR(qty, 15, 2)))
	FROM tdc_soft_alloc_tbl (NOLOCK)
		WHERE order_no = @xfer_no 
		  AND order_ext = 0 
		  AND order_type = 'T'
		  AND location = @location
		  AND line_no = @line_no

IF @ALC = ''
	SELECT @ALC = '0.00'

SELECT @msg = 'ORD ' + @ORD + ',  ALC ' + @ALC + ',  PCK ' + @PCK
	
IF(@qty = 0) RETURN 0

SELECT @status = status FROM xfers (nolock) WHERE xfer_no = @xfer_no

IF(@status < 'S')
BEGIN
	IF NOT EXISTS (	SELECT * FROM tdc_dist_group g (nolock), tdc_dist_item_pick i (nolock)
			WHERE g.child_serial_no = i.child_serial_no AND g.[function] = 'T' 
			AND i.[function] = 'T' AND i.order_no = @xfer_no AND i.line_no = @line_no ) 
	BEGIN
		SELECT @VER = RTRIM(LTRIM(STR(ISNULL(SUM(quantity/@conv_factor), 0), 15, 2))) 	
		  FROM tdc_dist_item_pick (nolock)
		 WHERE order_no = @xfer_no AND [function] = 'T' AND line_no = @line_no AND status = 'V'
	
		IF @@ROWCOUNT > 0 
			SELECT @msg = @msg + ',  VER ' + @VER

		RETURN 0
	END
END
ELSE
BEGIN
	IF NOT EXISTS ( SELECT * FROM tdc_bkp_dist_group g (nolock), tdc_bkp_dist_item_pick i (nolock)
				WHERE g.child_serial_no = i.child_serial_no AND g.[function] = 'T' 
				AND i.[function] = 'T' AND i.order_no = @xfer_no AND i.line_no = @line_no)
	BEGIN
		SELECT @VER = RTRIM(LTRIM(STR(ISNULL(SUM(quantity/@conv_factor), 0), 15, 2))) 	
			FROM tdc_bkp_dist_item_pick (nolock)
				WHERE order_no = @xfer_no AND [function] = 'T' AND line_no = @line_no

		SELECT @msg = @msg + ',  VER ' + @VER
		RETURN 0
	END
END

SELECT @status = tdc_status FROM tdc_xfers (nolock) WHERE xfer_no = @xfer_no

CREATE TABLE #temp_tb1(
	parent INT NOT NULL,
	child INT NOT NULL,
	type VARCHAR(2) NOT NULL,
	qty DECIMAL(20, 8) NOT NULL
)

CREATE TABLE #temp_tb2(
	parent_id INT NOT NULL,
	child_id INT NOT NULL,
	type VARCHAR(2) NOT NULL,
	qty DECIMAL(20, 8) NOT NULL
)

CREATE TABLE #temp_tb3(
	type VARCHAR(2) NOT NULL,
	qty DECIMAL(20, 8) NOT NULL
)

IF (@status = 'R1')
BEGIN 
	INSERT INTO #temp_tb1 (parent, child, type, qty)
		SELECT DISTINCT g.parent_serial_no, g.child_serial_no, g.type, g.quantity
		FROM tdc_bkp_dist_group g (nolock), tdc_bkp_dist_item_pick i (nolock)
		WHERE g.child_serial_no = i.child_serial_no AND g.[function] = 'T' 
		AND i.[function] = 'T' AND i.order_no = @xfer_no
		AND i.line_no = @line_no

	WHILE EXISTS (SELECT parent_serial_no 
			FROM tdc_bkp_dist_group (nolock)
			WHERE child_serial_no IN (SELECT DISTINCT parent FROM #temp_tb1) AND [function] = 'T')
	BEGIN
		INSERT INTO #temp_tb2 (parent_id, child_id, type, qty)	
			SELECT DISTINCT parent_serial_no, child_serial_no, type, quantity
				FROM tdc_bkp_dist_group (nolock)	
					WHERE child_serial_no IN (SELECT DISTINCT parent FROM #temp_tb1) AND [function] = 'T'

		DELETE FROM #temp_tb2 	WHERE parent_id IN (SELECT DISTINCT parent FROM #temp_tb1)
					AND child_id IN (SELECT DISTINCT child FROM #temp_tb1)
					AND type IN (SELECT DISTINCT type FROM #temp_tb1)

		IF EXISTS (SELECT * FROM #temp_tb2)
			INSERT INTO #temp_tb1 (parent, child, type, qty) SELECT parent_id, child_id, type, qty FROM #temp_tb2
		ELSE 
			BREAK
	END
END
ELSE
BEGIN 
	INSERT INTO #temp_tb1 (parent, child, type, qty) 
		SELECT DISTINCT g.parent_serial_no, g.child_serial_no, g.type, g.quantity 
			FROM tdc_dist_group g (nolock), tdc_dist_item_pick i (nolock)
				WHERE g.child_serial_no = i.child_serial_no
				AND g.[function] = 'T' AND i.[function] = 'T' AND i.line_no = @line_no
				AND i.order_no = @xfer_no
				
	WHILE EXISTS (SELECT parent_serial_no 	FROM tdc_dist_group (nolock)
						WHERE child_serial_no IN (SELECT DISTINCT parent FROM #temp_tb1) 
						AND [function] = 'T')
	BEGIN
		INSERT INTO #temp_tb2 (parent_id, child_id, type, qty) 
			SELECT DISTINCT parent_serial_no, child_serial_no, type, quantity
				FROM tdc_dist_group (nolock)	
					WHERE child_serial_no IN (SELECT DISTINCT parent FROM #temp_tb1) AND [function] = 'T'

		DELETE FROM #temp_tb2 	WHERE parent_id IN (SELECT DISTINCT parent FROM #temp_tb1)
					AND child_id IN (SELECT DISTINCT child FROM #temp_tb1)
					AND type IN (SELECT DISTINCT type FROM #temp_tb1)

		IF EXISTS (SELECT * FROM #temp_tb2)
			INSERT INTO #temp_tb1 (parent, child, type, qty) SELECT parent_id, child_id, type, qty FROM #temp_tb2
		ELSE 
			BREAK
	END
END

INSERT INTO #temp_tb3 (type, qty) SELECT type, SUM(qty) FROM #temp_tb1 GROUP BY type

/**********************************************************************************************/
/* loop through each type to get its qty */

SELECT @qty_pak = 0.0, @qty_man = 0.0, @type = NULL
SELECT @qty_crt = 0.0, @qty_stg = 0.0, @qty_ver = 0.0

DECLARE get_qty CURSOR FOR SELECT type, qty / @conv_factor FROM #temp_tb3 

OPEN get_qty
FETCH NEXT FROM get_qty INTO @type, @qty

WHILE (@@FETCH_STATUS = 0)
BEGIN
	IF @type = 'P1'
	BEGIN
		SELECT @PAK = 'P1'
		SELECT @qty_pak = @qty 
	END
	
	IF @type = 'N1' 	
	BEGIN
		SELECT @CRT = 'N1'
		SELECT @qty_crt = @qty
	END

	IF @type = 'S1'  	
	BEGIN
		SELECT @STG = 'S1'
		SELECT @qty_stg = @qty
	END

	IF @type = 'M1'  	
	BEGIN
		SELECT @MAN = 'M1'
		SELECT @qty_man = @qty
	END

	FETCH NEXT FROM get_qty INTO @type, @qty
END

CLOSE get_qty
DEALLOCATE get_qty

IF LEN(@PAK) > 0
	SELECT @msg = @msg + ',  PAK ' + RTRIM(LTRIM(STR(@qty_pak, 15, 2)))

IF LEN(@CRT) > 0
	SELECT @msg = @msg + ',  CRT ' + RTRIM(LTRIM(STR(@qty_crt, 15, 2)))

IF LEN(@STG) > 0
	SELECT @msg = @msg + ',  STG ' + RTRIM(LTRIM(STR(@qty_stg, 15, 2)))

IF LEN(@MAN) > 0
	SELECT @msg = @msg + ',  MAN ' + RTRIM(LTRIM(STR(@qty_man, 15, 2)))

IF (@status = 'R1')
BEGIN
	SELECT @msg = @msg + ',  VER ' + RTRIM(LTRIM(STR(@PCK, 15, 2)))
END
ELSE
BEGIN
	IF EXISTS (SELECT * FROM tdc_dist_group g (nolock), tdc_dist_item_pick p (nolock)
				WHERE p.order_no = @xfer_no AND g.status = 'V'
				AND p.line_no = @line_no AND g.child_serial_no = p.child_serial_no 
				AND p.[function] = 'T' AND g.[function] = 'T' )
	BEGIN
		SELECT @qty_ver = (SELECT SUM(g.quantity/@conv_factor) 
					FROM tdc_dist_group g (nolock), tdc_dist_item_pick p (nolock) 
					WHERE p.order_no = @xfer_no AND g.status = 'V' AND p.[function] = 'T' AND g.[function] = 'T'
					AND p.line_no = @line_no AND g.child_serial_no = p.child_serial_no) 

		SELECT @msg = @msg + ',  VER ' + RTRIM(LTRIM(STR(@qty_ver, 15, 2)))
	END	
END

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_get_xfer_list_status] TO [public]
GO
