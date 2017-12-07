SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[sim_tdc_plw_so_allocbylot_init_sp]	@location   varchar(10),  
													@part_no    varchar(30),  
													@order_no   int,  
													@order_ext   int,  
													@line_no int,  
													@needed_qty  decimal(20, 8),  
													@template_code  varchar(15),  
													@user_id varchar(50)
AS
BEGIN
	-- NOTE: Routine based on tdc_plw_so_allocbylot_init_sp v1.1 - All changes must be kept in sync
  
	DECLARE @lot_ser         varchar(25),  
		    @bin_no          varchar(12),  
			 @bin_group  varchar(12),  
			 @inv_qty  decimal(20, 8),  
			 @avail_qty  decimal(20, 8),  
			 @alloc_qty_for_line_no decimal(20, 8),  
			 @alloc_qty_total decimal(20, 8),  
			 @alloc_qty_for_lot_bin  decimal(20, 8),  
			 @SQL   varchar(1000) ,
			 @is_custom int 

	DECLARE @row_id			int,
			@last_row_id	int
  
	TRUNCATE TABLE #plw_alloc_by_lot_bin  

	IF EXISTS(SELECT 1 FROM CVO_ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND line_no = @line_no AND is_customized = 'S')
		SET @is_custom = 1
	ELSE
		SET @is_custom = 0

	------------------------------------------------------------------------------------------  
	-- Get the user's settings  
	------------------------------------------------------------------------------------------  
	SELECT @bin_group     = bin_group  
	FROM tdc_plw_process_templates (NOLOCK)  
	WHERE template_code  = @template_code  
	AND UserID         = @user_id  
	AND location       = @location  
	AND order_type     = 'S'  
	AND type           = 'one4one'  
  
	-- Insert all the records from lot_bin_stock  
	SET @SQL =  
		'INSERT INTO #plw_alloc_by_lot_bin(lot_ser, bin_no, date_expires, cur_alloc, instock_qty, avail_qty, sel_flg1, sel_flg2, qty)    
		SELECT lb.lot_ser, lb.bin_no, CONVERT(varchar(12), date_expires, 101), 0, 0, 0, 0, 0, 0  
		FROM lot_bin_stock              lb (NOLOCK),   
        tdc_bin_master             bm (NOLOCK)  
		WHERE lb.location = ' + char(39) + @location + char(39) +   
		'   AND lb.part_no  = ' + char(39) + @part_no  + char(39) +     
		'   AND lb.bin_no   = bm.bin_no  
			AND lb.location = bm.location  
			AND bm.usage_type_code IN (''OPEN'', ''REPLENISH'')'  
  
	IF ISNULL(@bin_group, '[ALL]') <> '[ALL]'  
	BEGIN  
		SET @SQL = @SQL + ' AND bm.group_code = ''' + @bin_group + ''''  
	END  
  
	EXEC (@SQL)  
  
	-- Get allocated qty for the part/line_no   
	SELECT @alloc_qty_for_line_no = 0  
	SELECT	@alloc_qty_for_line_no = SUM(qty)  
	FROM	#sim_tdc_soft_alloc_tbl (NOLOCK)  
	WHERE order_no   = @order_no  
	AND order_ext  = @order_ext  
	AND order_type = 'S'  
	AND location   = @location  
	AND line_no    = @line_no  
	AND part_no    = @part_no  
	GROUP BY location  
  
	-- Calculate needed qty for the part/line_no regardless LOTs/BINs  
	SELECT @needed_qty = @needed_qty - @alloc_qty_for_line_no  
  
	CREATE TABLE #lbi_alloc_qty_cursor (
		row_id			int IDENTITY(1,1),
		lot_ser			varchar(25),
		bin_no			varchar(12))

	INSERT #lbi_alloc_qty_cursor (lot_ser, bin_no)
	SELECT	lot_ser, bin_no FROM #plw_alloc_by_lot_bin ORDER BY lot_ser  

	CREATE INDEX #lbi_alloc_qty_cursor_ind0 ON #lbi_alloc_qty_cursor(row_id)
  
	------------------------------------------------  
	-- Set currently allocated and available qty  --  
	------------------------------------------------  
	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@lot_ser = lot_ser,
			@bin_no = bin_no
	FROM	#lbi_alloc_qty_cursor
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

	WHILE (@@ROWCOUNT <> 0)
	BEGIN  
		-- Get allocated qty for the part/line_no on the lot/bin  
	
		IF (@is_custom = 1)
		BEGIN
			SELECT @alloc_qty_for_lot_bin = 0  
			SELECT	@alloc_qty_for_lot_bin = qty_to_process 
			FROM	#sim_tdc_pick_queue (NOLOCK)  
			WHERE	trans_type_no = @order_no  
			AND		trans_type_ext = @order_ext  
			AND		trans = 'MGTB2B'  
			AND		location = @location  
			AND		line_no = @line_no  
			AND		part_no = @part_no  
			AND		lot = @lot_ser  
			AND		bin_no = @bin_no
		END
		ELSE
		BEGIN
			SELECT @alloc_qty_for_lot_bin = 0  
			SELECT	@alloc_qty_for_lot_bin = qty  
			FROM	#sim_tdc_soft_alloc_tbl (NOLOCK)  
			WHERE	order_no   = @order_no  
			AND		order_ext  = @order_ext  
			AND		order_type = 'S'  
			AND		location   = @location  
			AND		line_no    = @line_no  
			AND		part_no    = @part_no  
			AND		lot_ser    = @lot_ser  
			AND		bin_no     = @bin_no  
		END

		-- Get in stock qty for the part on the lot/bin  
		SELECT @inv_qty = 0  
		SELECT	@inv_qty = qty  
		FROM	lot_bin_stock (NOLOCK)  
		WHERE	location = @location  
		AND		part_no  = @part_no  
		AND		bin_no   = @bin_no  
		AND		lot_ser  = @lot_ser   
  
		-- Get allocated qty for the part on the lot/bin regardless order_no  
		SELECT @alloc_qty_total = 0  
		SELECT	@alloc_qty_total = ISNULL(SUM(qty),0)  
		FROM	#sim_tdc_soft_alloc_tbl (NOLOCK)  
		WHERE	location   = @location  
		AND		part_no    = @part_no  
		AND		lot_ser    = @lot_ser  
		AND		bin_no     = @bin_no  
		GROUP BY location  
    
		-- Calculate available qty  
		SELECT @avail_qty = 0  
		SELECT	@avail_qty = CASE WHEN @needed_qty = 0 THEN 0  
							ELSE CASE WHEN @inv_qty - @alloc_qty_total >= @needed_qty THEN @needed_qty  
									WHEN @inv_qty - @alloc_qty_total <  @needed_qty THEN @inv_qty - @alloc_qty_total END END  
  
		UPDATE	#plw_alloc_by_lot_bin    
		SET		cur_alloc = @alloc_qty_for_lot_bin,  
				instock_qty = @avail_qty, --SCR 080790  Call 1615282ESC  09/09/2008  
				avail_qty = @avail_qty  
		WHERE	lot_ser   = @lot_ser  
	    AND		bin_no    = @bin_no  
  
		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@lot_ser = lot_ser,
				@bin_no = bin_no
		FROM	#lbi_alloc_qty_cursor
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC

	END  
  
	DROP TABLE #lbi_alloc_qty_cursor
  
	RETURN   
END
GO
GRANT EXECUTE ON  [dbo].[sim_tdc_plw_so_allocbylot_init_sp] TO [public]
GO
