SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0 CT 24/07/2013 - Issue #1040 - Check for missing stock in other bins

CREATE PROC [dbo].[cvo_no_stock_get_bins_sp]
	 @user_id   varchar(50),               
	 @template_code  varchar(20),              
	 @order_no   int,               
	 @order_ext   int,               
	 @line_no   int,               
	 @part_no    varchar(30),              
	 @one_for_one_flg  char(1),              
	 @bin_group  varchar(30),               
	 @search_sort  varchar(30),               
	 @alloc_type  varchar(30),               
	 @pkg_code  varchar(10),              
	 @replen_group  varchar(12),              
	 @multiple_parts  char(1),              
	 @bin_first_option varchar(10),               
	 @priority  int,              
	 @user_hold  char(1),               
	 @cdock_flg  char(1),                 
	 @pass_bin  varchar(12),                
	 @assigned_user  varchar(25),                  
	 @lbs_order_by  varchar(5000),              
	 @max_qty_to_alloc decimal(20, 8) = 0                  
AS  
            
BEGIN     
	SET NOCOUNT ON
                 
	DECLARE @lot_ser  varchar(25),              
			@bin_no   varchar(12),   
			@one4one_or_cons varchar(7),   
			@search_type  varchar(10), 
			@bin_type  varchar(10),   
			@lb_cursor_clause  varchar(5000), 
			@location      varchar(10),
			@row_id  int,  
			@qty_needed DECIMAL(20,8),
			@qty_to_alloc  decimal(20, 8),               
			@qty_avail  decimal(20, 8),
			@usage_type_code  varchar(10)       
			
	SELECT 
		@qty_needed = qty, 
		@location = location
	FROM 
		#no_stock_required

	IF @qty_needed <= 0
		RETURN

	            
	SET @one4one_or_cons = CASE WHEN @one_for_one_flg = 'Y' THEN 'one4one' ELSE 'cons' END       

	SELECT 
		@search_sort      = search_sort,              
        @priority         = tran_priority,              
        @user_hold        = on_hold,              
        @cdock_flg        = cdock,              
        @pass_bin         = pass_bin,              
        @bin_first_option = bin_first,              
        @bin_type  = bin_type,              
        @replen_group  = replen_group,              
        @pkg_code  = pkg_code,              
        @multiple_parts   = multiple_parts,              
        @assigned_user    = CASE WHEN user_group = ''               
								  OR user_group LIKE '%DEFAULT%'               
								   THEN NULL              
								ELSE         user_group              
						   END,               
        @alloc_type       = CASE dist_type               
							WHEN 'PrePack'   THEN 'PR'              
							WHEN 'ConsolePick'  THEN 'PT'              
							WHEN 'PickPack'  THEN 'PP'              
							WHEN 'PackageBuilder'  THEN 'PB'              
							  END,              
        @search_type      = CASE ISNULL(bin_type, '')              
							 WHEN ''   THEN 'AUTOMATIC'              
							 ELSE        'MANUAL'              
							   END              
		FROM tdc_plw_process_templates (NOLOCK)              
		WHERE template_code  = @template_code              
		AND UserID         = @user_id              
		AND location       = @location              
		AND order_type     = 'S'              
		AND type           = @one4one_or_cons  

	
	SELECT @lb_cursor_clause = 'INSERT #lb_cur (lot_ser, bin_no, usage_type_code, qty_avail)     ' +              
		--' SELECT TOP 1 lb.lot_ser, lb.bin_no, bm.usage_type_code,  ' +              
		' SELECT lb.lot_ser, lb.bin_no, bm.usage_type_code,  ' +              
		'        qty_avail = (        ' +              
		'  SUM(qty) -        ' + -- Sum of the quantity in lot_bin_stock              
		'  (SELECT ISNULL((SELECT SUM(qty)     ' + -- Subtract the quantity allocated              
		'        FROM tdc_soft_alloc_tbl (NOLOCK)     ' +              
		'     WHERE location = lb.location   ' +              
		'       AND part_no = lb.part_no   ' +              
		'       AND lot_ser = lb.lot_ser   ' +              
		'       AND bin_no = lb.bin_no)   ' +              
		'  , 0)))       ' +              
		'  FROM lot_bin_stock lb (NOLOCK), tdc_bin_master bm (NOLOCK)     ' +              
		' WHERE lb.location   = ''' + @location + '''    ' +               
		'   AND lb.part_no    = ''' + @part_no + '''    ' +               
		'   AND lb.bin_no     = bm.bin_no     ' +   
		'   AND lb.location   = bm.location     '   

	
	SELECT @lb_cursor_clause = @lb_cursor_clause + '   AND ISNULL(bm.bm_udef_e,'''') = '''' '     -- v1.0                  

	IF @bin_group <> '[ALL]'              
	BEGIN              
		SELECT @lb_cursor_clause = @lb_cursor_clause + ' AND bm.group_code = ''' + @bin_group + ''''               
	END              

               
	IF @search_type = 'AUTOMATIC'              
		SELECT @lb_cursor_clause = @lb_cursor_clause + ' AND bm.usage_type_code IN (''OPEN'', ''REPLENISH'') '              
	ELSE         -- MANUAL               (
	BEGIN              
		SELECT @lb_cursor_clause = @lb_cursor_clause + ' AND bm.usage_type_code = ' + @bin_type              
		SET @lbs_order_by = ''              
	END              
          
	SELECT @lb_cursor_clause = @lb_cursor_clause +              
	' GROUP BY lb.location, lb.part_no, lb.lot_ser, lb.bin_no,   ' +              
	'          lb.date_expires, bm.usage_type_code, lb.qty   ' +              
	'HAVING SUM(qty) > (SELECT ISNULL((SELECT SUM(qty)   ' +               
	'         FROM tdc_soft_alloc_tbl    (NOLOCK) ' +              
	'        WHERE location = lb.location ' +               
	'          AND part_no  = lb.part_no  ' +               
	'          AND lot_ser  = lb.lot_ser  ' +               
	'          AND bin_no   = lb.bin_no)  ' +               
	'    , 0))       ' +              
	 ISNULL(@lbs_order_by,'')
   
	CREATE TABLE #lb_cur (  
	row_id   int IDENTITY(1,1),  
	lot_ser   varchar(25),  
	bin_no   varchar(30),  
	usage_type_code varchar(10),  
	qty_avail  decimal(20,8))  
	 
	EXEC (@lb_cursor_clause)  
  
	CREATE INDEX #lb_cur_ind0 ON #lb_cur ( row_id)  

	CREATE TABLE #lb_cur1 (  
	row_id   int IDENTITY(1,1),  
	lot_ser   varchar(25),  
	bin_no   varchar(30),  
	usage_type_code varchar(10),  
	qty_avail  decimal(20,8))

	INSERT INTO #lb_cur1(
		lot_ser,
		bin_no,
		usage_type_code,
		qty_avail)
	SELECT
		lot_ser,
		bin_no,
		usage_type_code,
		qty_avail
	FROM
		#lb_cur
	ORDER BY
		qty_avail DESC
	
	SET @row_id = 0  
	WHILE 1=1
	BEGIN  

		SELECT TOP 1 
			@row_id = row_id,  
			@lot_ser = lot_ser,   
			@bin_no = bin_no,   
			@usage_type_code = usage_type_code,   
			@qty_avail = qty_avail  
		FROM #lb_cur1  
		WHERE row_id > @row_id  
		ORDER BY row_id ASC  

		IF @@ROWCOUNT = 0
			BREAK

		IF @qty_avail >= @qty_needed
		BEGIN
			SET @qty_to_alloc = @qty_needed
			SET @qty_needed = 0
		END
		ELSE
		BEGIN
			SET @qty_to_alloc = @qty_avail
			SET @qty_needed = @qty_needed - @qty_to_alloc
		END
	
		INSERT INTO #no_stock_bins(
			bin_no,
			lot_ser,
			qty)
		SELECT
			@bin_no,
			@lot_ser,
			@qty_to_alloc

		IF @qty_needed <= 0
			BREAK
	END
END
GO
GRANT EXECUTE ON  [dbo].[cvo_no_stock_get_bins_sp] TO [public]
GO
