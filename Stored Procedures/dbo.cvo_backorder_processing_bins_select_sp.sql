SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
CREATE TABLE #bins(
		rec_id		INT IDENTITY(1,1),
		location	VARCHAR(10),
		bin_no		VARCHAR(12),
		qty			DECIMAL(20,8))

EXEC cvo_backorder_processing_bins_select_sp 'ETZCASBUNI', '001', 5

SELECT * FROM #bins

DROP TABLE #bins


*/

CREATE PROC [dbo].[cvo_backorder_processing_bins_select_sp]    (@part_no	VARCHAR(30),
															@location	VARCHAR(10),
															@qty		DECIMAL(20,8))
AS
BEGIN

	DECLARE @alloc_qty_fence_qty	INT,
			@bulk_bin_group			VARCHAR(12), 
			@hight_bays_bin_group	VARCHAR(12), 
			@pick_bin_group			VARCHAR(12)

	-- Get fence and bin group info
	SELECT @alloc_qty_fence_qty = value_str FROM tdc_config (NOLOCK) WHERE [function] = 'ALLOC_QTY_FENCE'
	SELECT @bulk_bin_group		= value_str FROM tdc_config (NOLOCK) WHERE [function] = 'bulk_bin_group'
	SELECT @hight_bays_bin_group= value_str FROM tdc_config (NOLOCK) WHERE [function] = 'hight_bays_bin_group'
	SELECT @pick_bin_group		= value_str FROM tdc_config (NOLOCK) WHERE [function] = 'pick_bin_group'

	-- Get stock currently allocated for this part
	CREATE TABLE #bin_qty(
		location	VARCHAR(10),
		bin_no		VARCHAR(12),
		qty			DECIMAL(20,8))
	
	INSERT INTO #bin_qty(
		location,
		bin_no,
		qty)
	SELECT
		location,
		bin_no,
		SUM(qty)
	FROM
		dbo.tdc_soft_alloc_tbl (NOLOCK)
	WHERE
		location = @location
		AND part_no = @part_no
	GROUP BY
		location,
		bin_no

	-- If @qty >= @alloc_qty_fence_qty then use bins in high bay, bulk and then pick order
	IF @qty >= @alloc_qty_fence_qty
	BEGIN
		-- High bay
		INSERT #bins(
			bin_no,
			location,
			qty)
		SELECT
			a.bin_no,
			a.location,
			a.qty - ISNULL(b.qty,0)
		FROM
			dbo.lot_bin_stock a (NOLOCK)
		LEFT JOIN
			#bin_qty b 
		ON
			a.location = b.location
			AND a.bin_no = b.bin_no
		INNER JOIN
			dbo.tdc_bin_master c (NOLOCK)
		ON
			a.location = c.location
			AND a.bin_no = c.bin_no
		WHERE
			a.location = @location
			AND a.part_no = @part_no
			AND c.group_code = @hight_bays_bin_group
			AND ISNULL(c.bm_udef_e,'') = ''
		ORDER BY
			a.qty - ISNULL(b.qty,0) DESC
			
		-- Bulk 
		INSERT #bins(
			bin_no,
			location,
			qty)
		SELECT
			a.bin_no,
			a.location,
			a.qty - ISNULL(b.qty,0)
		FROM
			dbo.lot_bin_stock a (NOLOCK)
		LEFT JOIN
			#bin_qty b 
		ON
			a.location = b.location
			AND a.bin_no = b.bin_no
		INNER JOIN
			dbo.tdc_bin_master c (NOLOCK)
		ON
			a.location = c.location
			AND a.bin_no = c.bin_no
		WHERE
			a.location = @location
			AND a.part_no = @part_no
			AND c.group_code = @bulk_bin_group
			AND ISNULL(c.bm_udef_e,'') = ''
		ORDER BY
			a.qty - ISNULL(b.qty,0) DESC

		-- Pick
		INSERT #bins(
			bin_no,
			location,
			qty)
		SELECT
			a.bin_no,
			a.location,
			a.qty - ISNULL(b.qty,0)
		FROM
			dbo.lot_bin_stock a (NOLOCK)
		LEFT JOIN
			#bin_qty b 
		ON
			a.location = b.location
			AND a.bin_no = b.bin_no
		INNER JOIN
			dbo.tdc_bin_master c (NOLOCK)
		ON
			a.location = c.location
			AND a.bin_no = c.bin_no
		WHERE
			a.location = @location
			AND a.part_no = @part_no
			AND c.group_code = @pick_bin_group
			AND ISNULL(c.bm_udef_e,'') = ''
		ORDER BY
			a.qty - ISNULL(b.qty,0) DESC
	END
	ELSE
	BEGIN
		-- If @qty < @alloc_qty_fence_qty then use bins in pick, high bay and then bulk order
		-- Pick
		INSERT #bins(
			bin_no,
			location,
			qty)
		SELECT
			a.bin_no,
			a.location,
			a.qty - ISNULL(b.qty,0)
		FROM
			dbo.lot_bin_stock a (NOLOCK)
		LEFT JOIN
			#bin_qty b 
		ON
			a.location = b.location
			AND a.bin_no = b.bin_no
		INNER JOIN
			dbo.tdc_bin_master c (NOLOCK)
		ON
			a.location = c.location
			AND a.bin_no = c.bin_no
		WHERE
			a.location = @location
			AND a.part_no = @part_no
			AND c.group_code = @pick_bin_group
			AND ISNULL(c.bm_udef_e,'') = ''
		ORDER BY
			a.qty - ISNULL(b.qty,0) DESC

		-- High bay
		INSERT #bins(
			bin_no,
			location,
			qty)
		SELECT
			a.bin_no,
			a.location,
			a.qty - ISNULL(b.qty,0)
		FROM
			dbo.lot_bin_stock a (NOLOCK)
		LEFT JOIN
			#bin_qty b 
		ON
			a.location = b.location
			AND a.bin_no = b.bin_no
		INNER JOIN
			dbo.tdc_bin_master c (NOLOCK)
		ON
			a.location = c.location
			AND a.bin_no = c.bin_no
		WHERE
			a.location = @location
			AND a.part_no = @part_no
			AND c.group_code = @hight_bays_bin_group
			AND ISNULL(c.bm_udef_e,'') = ''
		ORDER BY
			a.qty - ISNULL(b.qty,0) DESC
			
		-- Bulk 
		INSERT #bins(
			bin_no,
			location,
			qty)
		SELECT
			a.bin_no,
			a.location,
			a.qty - ISNULL(b.qty,0)
		FROM
			dbo.lot_bin_stock a (NOLOCK)
		LEFT JOIN
			#bin_qty b 
		ON
			a.location = b.location
			AND a.bin_no = b.bin_no
		INNER JOIN
			dbo.tdc_bin_master c (NOLOCK)
		ON
			a.location = c.location
			AND a.bin_no = c.bin_no
		WHERE
			a.location = @location
			AND a.part_no = @part_no
			AND c.group_code = @bulk_bin_group
			AND ISNULL(c.bm_udef_e,'') = ''
		ORDER BY
			a.qty - ISNULL(b.qty,0) DESC
	END

	-- Clear out bins without available stock
	DELETE FROM #bins WHERE qty <= 0

	RETURN
END

GO
GRANT EXECUTE ON  [dbo].[cvo_backorder_processing_bins_select_sp] TO [public]
GO
