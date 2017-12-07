SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[sim_tdc_plw_so_allocbylot_process_sp]	@location      varchar(10),  
														@part_no       varchar(30),  
														@line_no       int,  
														@order_no      int,  
														@order_ext     int,  
														@user_id       varchar(50),  
														@con_no_passed_in  int,  
														@template_code  varchar(20)  
AS
BEGIN
	-- NOTE: Routine based on tdc_plw_so_allocbylot_process_sp v3.5 - All changes must be kept in sync
  
	DECLARE @lot_ser          varchar(25),  
		    @bin_no           varchar(12),  
			@name     varchar(100),  
			@desc     varchar(100),  
			@qty_to_alloc     decimal(24,8),  
			@qty_to_unalloc   decimal(24,8),  
			@allocated_qty    decimal(24,8),  
			@in_stock_qty     decimal(24,8),  
			@needed_qty       decimal(24,8),  
			@conv_factor   decimal(20,8),  
			@mgtb2b_qty   decimal(24,8),  
			@plwb2b_qty   decimal(24,8),  
			@con_name   varchar(255),  
			@con_desc   varchar(255),  
			@con_seq_no   int,  
			@con_no_from_temp_table int,  
			@next_con_no   int,  
			@alloc_type varchar(20),  
			@pass_bin varchar(12),  
			@q_priority     int,       
			@user_hold      char(1),  
			@cdock_flg      char(1),  
			@multiple_parts char(1),  
			@replen_group varchar(12),  
			@pkg_code varchar(20),  
			@assigned_user varchar(50),  
			@type           varchar(10),  
			@data  varchar(1000),  
			@pre_pack_flag char(1),
			@sa_qty	decimal(20,8), 
			@alloc_qty decimal(20,8),
			@new_soft_alloc_no int, 
			@cur_status int,
			@is_custom int, 
			@custom_bin varchar(20),
			@unalloc_type varchar(30),
			@iRet int, 
			@err_ret int, 
			@consolidation_no int,
			@last_line int,
			@part_no_original varchar(30),
			@part_type varchar(10),
			@qty decimal(20,8) 

	DECLARE	@row_id			int,
			@last_row_id	int

	-- Check if any line items exist in the queue that do not exist on the order
	IF EXISTS (SELECT 1 FROM #sim_tdc_pick_queue a (NOLOCK) LEFT JOIN ord_list b (NOLOCK) ON a.trans_type_no = b.order_no AND a.trans_type_ext = b.order_ext
			AND	a.line_no = b.line_no WHERE a.trans_type_no = @order_no AND a.trans_type_ext = @order_ext AND a.trans = 'STDPICK' AND b.line_no IS NULL)
	BEGIN
		-- Need to unallocate the lines that do not exist on the order
		DELETE	a 
		FROM	#sim_tdc_soft_alloc_tbl a
		LEFT JOIN	ord_list b (NOLOCK)
		ON		a.order_no = b.order_no 
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.line_no 
		WHERE	a.order_no = @order_no 
		AND		a.order_ext = @order_ext 
		AND		b.line_no IS NULL
		AND		a.order_type = 'S'

		DELETE	a 
		FROM	#sim_tdc_pick_queue a
		LEFT JOIN	ord_list b (NOLOCK)
		ON		a.trans_type_no = b.order_no 
		AND		a.trans_type_ext = b.order_ext
		AND		a.line_no = b.line_no 
		WHERE	a.trans_type_no = @order_no 
		AND		a.trans_type_ext = @order_ext 
		AND		b.line_no IS NULL
		AND		a.trans IN ('STDPICK','MGTB2B')

	END

	IF EXISTS(SELECT 1 FROM CVO_ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND line_no = @line_no AND is_customized = 'S')
		SET @is_custom = 1
	ELSE
		SET @is_custom = 0
  
	IF @con_no_passed_in > 0  
		SET @type = 'cons'  
	ELSE  
		SET @type = 'one4one'  
  
	SELECT @con_seq_no = 0  
  
	SELECT @q_priority = 5  
	SELECT @q_priority = CAST(value_str AS INT) FROM tdc_config(NOLOCK) where [function] = 'Pick_Q_Priority'  
	IF @q_priority IN ('', 0) SELECT @q_priority = 5  
   
	IF EXISTS(SELECT * FROM ord_list (NOLOCK)  
		WHERE order_no  = @order_no AND order_ext = @order_ext AND line_no   = @line_no AND part_type = 'C')  
	BEGIN  
		SELECT @conv_factor = conv_factor  
		FROM ord_list_kit (NOLOCK)  
		WHERE order_no  = @order_no  
		AND order_ext = @order_ext  
		AND line_no   = @line_no  
		AND part_no   = @part_no  
	END  
	ELSE  
	BEGIN  
		SELECT @conv_factor = conv_factor  
		FROM ord_list (NOLOCK)  
		WHERE order_no  = @order_no  
		AND order_ext = @order_ext  
		AND line_no   = @line_no  
	END  
  
	--*********************************** Do unallocate first ************************************************  

	CREATE TABLE #lbp_unallocate_cursor (
		row_id			int IDENTITY(1,1),
		lot_ser			varchar(25),
		bin_no			varchar(12),
		qty_to_alloc	decimal(20,8))

	INSERT	#lbp_unallocate_cursor (lot_ser, bin_no, qty_to_alloc)
	SELECT	lot_ser, bin_no, qty FROM #plw_alloc_by_lot_bin WHERE sel_flg2 <> 0 AND qty > 0  

	CREATE INDEX #lbp_unallocate_cursor_ind0 ON #lbp_unallocate_cursor (row_id)
  
	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@lot_ser = lot_ser,
			@bin_no = bin_no,
			@qty_to_unalloc = qty_to_alloc
	FROM	#lbp_unallocate_cursor
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

	WHILE (@@ROWCOUNT <> 0)
	BEGIN    
		 /* Determine if any of the transactions on the queue are being processed.  */  
		 /* If so, then rollback. Otherwise, continue on and change the queue by    */  
		 /* updating & deleting all the applicable pick transactions for the        */  
		 /* order / part / lot/ bin being unallocated.        */  
		IF EXISTS (SELECT * FROM #sim_tdc_pick_queue (NOLOCK)
			WHERE trans         IN ('STDPICK', 'PKGBLD')  
			AND trans_type_no  = @order_no  
			AND trans_type_ext = @order_ext  
			AND location       = @location  
			AND part_no        = @part_no  
			AND lot            = @lot_ser  
			AND bin_no         = @bin_no  
			AND tx_lock   NOT IN ('R','3','P', 'G', 'H','E'))  
		BEGIN 
			DROP TABLE #lbp_unallocate_cursor			
			RETURN  
		END  

		IF (@is_custom = 1)
		BEGIN
			SELECT @custom_bin = ISNULL((SELECT value_str FROM tdc_config (nolock)  
										WHERE [function] = 'CVO_CUSTOM_BIN' AND active = 'Y'), 'CUSTOM')
			INSERT	#deleted
			SELECT	*
			FROM	#sim_tdc_soft_alloc_tbl		
			WHERE	order_no   = @order_no  
			AND		order_ext  = @order_ext  
			AND		order_type = 'S'  
			AND		location   = @location  
			AND		line_no    = @line_no  
			AND		part_no    = @part_no  
			AND		lot_ser    = @lot_ser  
			AND		bin_no     = @custom_bin

			INSERT	#inserted
			SELECT	*
			FROM	#sim_tdc_soft_alloc_tbl		
			WHERE	order_no   = @order_no  
			AND		order_ext  = @order_ext  
			AND		order_type = 'S'  
			AND		location   = @location  
			AND		line_no    = @line_no  
			AND		part_no    = @part_no  
			AND		lot_ser    = @lot_ser  
			AND		bin_no     = @custom_bin

			UPDATE	#inserted   
			SET		qty = qty  - @qty_to_unalloc,  
					trg_off = 1 --SCR 38010 Jim 8/16/07 : disable tdc_upd_softalloc_tg  
			WHERE	order_no   = @order_no  
			AND		order_ext  = @order_ext  
			AND		order_type = 'S'  
			AND		location   = @location  
			AND		line_no    = @line_no  
			AND		part_no    = @part_no  
			AND		lot_ser    = @lot_ser  
			AND		bin_no     = @custom_bin

			UPDATE	#sim_tdc_soft_alloc_tbl   
			SET		qty = qty  - @qty_to_unalloc,  
					trg_off = 1 --SCR 38010 Jim 8/16/07 : disable tdc_upd_softalloc_tg  
			WHERE	order_no   = @order_no  
			AND		order_ext  = @order_ext  
			AND		order_type = 'S'  
			AND		location   = @location  
			AND		line_no    = @line_no  
			AND		part_no    = @part_no  
			AND		lot_ser    = @lot_ser  
			AND		bin_no     = @custom_bin

			EXEC dbo.cvo_sim_tdc_soft_alloc_tbl_trg_sp 'UPDATE','','qty'
			TRUNCATE TABLE #inserted			
			TRUNCATE TABLE #deleted	
		END
		ELSE
		BEGIN  
			INSERT	#deleted
			SELECT	*
			FROM	#sim_tdc_soft_alloc_tbl		
			WHERE	order_no   = @order_no  
			AND		order_ext  = @order_ext  
			AND		order_type = 'S'  
			AND		location   = @location  
			AND		line_no    = @line_no  
			AND		part_no    = @part_no  
			AND		lot_ser    = @lot_ser  
			AND		bin_no     = @bin_no

			INSERT	#inserted
			SELECT	*
			FROM	#sim_tdc_soft_alloc_tbl		
			WHERE	order_no   = @order_no  
			AND		order_ext  = @order_ext  
			AND		order_type = 'S'  
			AND		location   = @location  
			AND		line_no    = @line_no  
			AND		part_no    = @part_no  
			AND		lot_ser    = @lot_ser  
			AND		bin_no     = @bin_no

			UPDATE	#inserted  
			SET		qty = qty  - @qty_to_unalloc,  
					trg_off = 1 --SCR 38010 Jim 8/16/07 : disable tdc_upd_softalloc_tg  
			WHERE	order_no   = @order_no  
			AND		order_ext  = @order_ext  
			AND		order_type = 'S'  
			AND		location   = @location  
			AND		line_no    = @line_no  
			AND		part_no    = @part_no  
			AND		lot_ser    = @lot_ser  
			AND		bin_no     = @bin_no 

			UPDATE	#sim_tdc_soft_alloc_tbl  
			SET		qty = qty  - @qty_to_unalloc,  
					trg_off = 1 --SCR 38010 Jim 8/16/07 : disable tdc_upd_softalloc_tg  
			WHERE	order_no   = @order_no  
			AND		order_ext  = @order_ext  
			AND		order_type = 'S'  
			AND		location   = @location  
			AND		line_no    = @line_no  
			AND		part_no    = @part_no  
			AND		lot_ser    = @lot_ser  
			AND		bin_no     = @bin_no  

			EXEC dbo.cvo_sim_tdc_soft_alloc_tbl_trg_sp 'UPDATE','','qty'
			TRUNCATE TABLE #inserted			
			TRUNCATE TABLE #deleted	
		END

		IF @@ERROR <> 0  
		BEGIN  
			DROP TABLE #lbp_unallocate_cursor
			RETURN  
		END  
	  
		IF (@is_custom = 1)
		BEGIN
			SELECT @custom_bin = ISNULL((SELECT value_str FROM tdc_config (nolock)  
										WHERE [function] = 'CVO_CUSTOM_BIN' AND active = 'Y'), 'CUSTOM')

			UPDATE #sim_tdc_pick_queue 
			SET qty_to_process = qty_to_process - @qty_to_unalloc  
			WHERE trans         IN ('STDPICK', 'PKGBLD')  
			AND trans_type_no  = @order_no  
			AND trans_type_ext = @order_ext  
			AND location       = @location  
			AND part_no        = @part_no  
			AND lot            = @lot_ser  
			AND bin_no         = @custom_bin  
			AND line_no		  = @line_no

		END
		ELSE
		BEGIN
			UPDATE #sim_tdc_pick_queue   
			SET qty_to_process = qty_to_process - @qty_to_unalloc  
			WHERE trans         IN ('STDPICK', 'PKGBLD')  
			AND trans_type_no  = @order_no  
			AND trans_type_ext = @order_ext  
			AND location       = @location  
			AND part_no        = @part_no  
			AND lot            = @lot_ser  
			AND bin_no         = @bin_no  
			AND line_no		  = @line_no 
		END
	 
		IF @@ERROR <> 0  
		BEGIN          
			DROP TABLE #lbp_unallocate_cursor
			RETURN  
		END  
	  
		IF (@is_custom = 1)
		BEGIN
			SELECT @custom_bin = ISNULL((SELECT value_str FROM tdc_config (nolock)  
										WHERE [function] = 'CVO_CUSTOM_BIN' AND active = 'Y'), 'CUSTOM')

			DELETE FROM #sim_tdc_pick_queue   
			WHERE trans          IN ('STDPICK', 'PKGBLD')  
			AND trans_type_no   = @order_no  
			AND trans_type_ext  = @order_ext  
			AND location        = @location  
			AND part_no         = @part_no  
			AND lot             = @lot_ser  
			AND bin_no          = @custom_bin  
			AND line_no		   = @line_no 
			AND qty_to_process <= 0  
		END
		ELSE
		BEGIN
			DELETE FROM #sim_tdc_pick_queue 
			WHERE trans          IN ('STDPICK', 'PKGBLD')  
			AND trans_type_no   = @order_no  
			AND trans_type_ext  = @order_ext  
			AND location        = @location  
			AND part_no         = @part_no  
			AND lot             = @lot_ser  
			AND bin_no          = @bin_no  
			AND line_no		   = @line_no 
			AND qty_to_process <= 0  
		END
		
		IF EXISTS (SELECT 1 FROM #sim_tdc_pick_queue (NOLOCK) WHERE trans_type_no = @order_no AND trans_type_ext = @order_ext 
					AND part_no = @part_no AND line_no = @line_no AND trans = 'MGTB2B')
		BEGIN		
			INSERT	#deleted
			SELECT	a.*
			FROM	#sim_tdc_soft_alloc_tbl a
			JOIN	tdc_pick_queue b (NOLOCK)
			ON		a.location = b.location
			AND		a.part_no = b.part_no
			AND		a.bin_no = b.bin_no
			AND		a.target_bin = b.next_op
			WHERE	b.trans_type_no = @order_no 
			AND		b.trans_type_ext = @order_ext 
			AND		b.trans = 'MGTB2B'
			AND		b.line_no = @line_no
			AND		a.order_type = 'S'
			AND		a.order_no = 0

			INSERT	#inserted
			SELECT	a.*
			FROM	#sim_tdc_soft_alloc_tbl a
			JOIN	tdc_pick_queue b (NOLOCK)
			ON		a.location = b.location
			AND		a.part_no = b.part_no
			AND		a.bin_no = b.bin_no
			AND		a.target_bin = b.next_op
			WHERE	b.trans_type_no = @order_no 
			AND		b.trans_type_ext = @order_ext 
			AND		b.trans = 'MGTB2B'
			AND		b.line_no = @line_no
			AND		a.order_type = 'S'
			AND		a.order_no = 0

			UPDATE	a 
			SET		qty = a.qty - b.qty_to_process
			FROM	#inserted a
			JOIN	tdc_pick_queue b (NOLOCK)
			ON		a.location = b.location
			AND		a.part_no = b.part_no
			AND		a.bin_no = b.bin_no
			AND		a.target_bin = b.next_op
			WHERE	b.trans_type_no = @order_no 
			AND		b.trans_type_ext = @order_ext 
			AND		b.trans = 'MGTB2B'
			AND		b.line_no = @line_no
			AND		a.order_type = 'S'
			AND		a.order_no = 0
	
			UPDATE	a 
			SET		qty = a.qty - b.qty_to_process
			FROM	#sim_tdc_soft_alloc_tbl a
			JOIN	tdc_pick_queue b (NOLOCK)
			ON		a.location = b.location
			AND		a.part_no = b.part_no
			AND		a.bin_no = b.bin_no
			AND		a.target_bin = b.next_op
			WHERE	b.trans_type_no = @order_no 
			AND		b.trans_type_ext = @order_ext 
			AND		b.trans = 'MGTB2B'
			AND		b.line_no = @line_no
			AND		a.order_type = 'S'
			AND		a.order_no = 0

			EXEC dbo.cvo_sim_tdc_soft_alloc_tbl_trg_sp 'UPDATE','','qty'
			TRUNCATE TABLE #inserted			
			TRUNCATE TABLE #deleted	

			DELETE	#sim_tdc_soft_alloc_tbl
			WHERE	location = @location
			AND		order_no = 0
			AND		order_type = 'S'
			AND		qty <= 0

		END
		
		DELETE	#sim_tdc_pick_queue
		WHERE	trans         = 'MGTB2B'           
		AND		trans_type_no  = @order_no       
		AND		trans_type_ext = @order_ext            
		AND		location       = @location           
		AND		line_no        = @line_no      
		AND		trans_source   = 'MGT'  
	  
		IF @con_no_passed_in > 0  
		BEGIN  

			UPDATE #sim_tdc_pick_queue  
			SET qty_to_process = qty_to_process  - @qty_to_unalloc  
			WHERE trans           = 'PLWB2B'  
			AND trans_type_no   = @con_no_passed_in  
			AND trans_type_ext  = 0  
			AND location        = @location  
			AND part_no         = @part_no  
			AND lot             = @lot_ser  
			AND bin_no          = @bin_no  
	     
			DELETE FROM #sim_tdc_pick_queue   
			WHERE trans           = 'PLWB2B'  
			AND trans_type_no   = @con_no_passed_in  
			AND trans_type_ext  = 0  
			AND location        = @location  
			AND part_no         = @part_no  
			AND lot             = @lot_ser  
			AND bin_no          = @bin_no  
			AND qty_to_process <= 0    
		END  
	  
		IF (@is_custom = 1)
		BEGIN
			SELECT @custom_bin = ISNULL((SELECT value_str FROM tdc_config (nolock)  
										WHERE [function] = 'CVO_CUSTOM_BIN' AND active = 'Y'), 'CUSTOM')

			INSERT	#deleted
			SELECT	*
			FROM	#sim_tdc_soft_alloc_tbl
			WHERE order_no   = @order_no  
			AND order_ext  = @order_ext  
			AND order_type = 'S'  
			AND location   = @location  
			AND line_no    = @line_no  
			AND part_no    = @part_no  
			AND lot_ser    = @lot_ser  
			AND bin_no     = @custom_bin

			INSERT	#inserted
			SELECT	*
			FROM	#sim_tdc_soft_alloc_tbl
			WHERE order_no   = @order_no  
			AND order_ext  = @order_ext  
			AND order_type = 'S'  
			AND location   = @location  
			AND line_no    = @line_no  
			AND part_no    = @part_no  
			AND lot_ser    = @lot_ser  
			AND bin_no     = @custom_bin

			UPDATE #inserted   
			SET trg_off = 0 --SCR 37993 Jim 8/16/07 : enable tdc_upd_softalloc_tg  
			WHERE order_no   = @order_no  
			AND order_ext  = @order_ext  
			AND order_type = 'S'  
			AND location   = @location  
			AND line_no    = @line_no  
			AND part_no    = @part_no  
			AND lot_ser    = @lot_ser  
			AND bin_no     = @custom_bin

			UPDATE #sim_tdc_soft_alloc_tbl   
			SET trg_off = 0 --SCR 37993 Jim 8/16/07 : enable tdc_upd_softalloc_tg  
			WHERE order_no   = @order_no  
			AND order_ext  = @order_ext  
			AND order_type = 'S'  
			AND location   = @location  
			AND line_no    = @line_no  
			AND part_no    = @part_no  
			AND lot_ser    = @lot_ser  
			AND bin_no     = @custom_bin  

			EXEC dbo.cvo_sim_tdc_soft_alloc_tbl_trg_sp 'UPDATE','',''
			TRUNCATE TABLE #inserted			
			TRUNCATE TABLE #deleted	

			DELETE	#sim_tdc_soft_alloc_tbl
			WHERE	order_no   = @order_no  
			AND		order_ext  = @order_ext  
			AND		order_type = 'S'  
			AND		location   = @location  
			AND		line_no    = @line_no  
			AND		part_no    = @part_no  
			AND		lot_ser    = @lot_ser  
			AND		bin_no     = @custom_bin 
			AND		qty <= 0
		END
		ELSE
		BEGIN
			INSERT	#deleted
			SELECT	*
			FROM	#sim_tdc_soft_alloc_tbl
			WHERE order_no   = @order_no  
			AND order_ext  = @order_ext  
			AND order_type = 'S'  
			AND location   = @location  
			AND line_no    = @line_no  
			AND part_no    = @part_no  
			AND lot_ser    = @lot_ser  
			AND bin_no     = @bin_no 

			INSERT	#inserted
			SELECT	*
			FROM	#sim_tdc_soft_alloc_tbl
			WHERE order_no   = @order_no  
			AND order_ext  = @order_ext  
			AND order_type = 'S'  
			AND location   = @location  
			AND line_no    = @line_no  
			AND part_no    = @part_no  
			AND lot_ser    = @lot_ser  
			AND bin_no     = @bin_no

			UPDATE #inserted  
			SET trg_off = 0 --SCR 37993 Jim 8/16/07 : enable tdc_upd_softalloc_tg  
			WHERE order_no   = @order_no  
			AND order_ext  = @order_ext  
			AND order_type = 'S'  
			AND location   = @location  
			AND line_no    = @line_no  
			AND part_no    = @part_no  
			AND lot_ser    = @lot_ser  
			AND bin_no     = @bin_no 

			UPDATE #sim_tdc_soft_alloc_tbl  
			SET trg_off = 0 --SCR 37993 Jim 8/16/07 : enable tdc_upd_softalloc_tg  
			WHERE order_no   = @order_no  
			AND order_ext  = @order_ext  
			AND order_type = 'S'  
			AND location   = @location  
			AND line_no    = @line_no  
			AND part_no    = @part_no  
			AND lot_ser    = @lot_ser  
			AND bin_no     = @bin_no  

			EXEC dbo.cvo_sim_tdc_soft_alloc_tbl_trg_sp 'UPDATE','',''
			TRUNCATE TABLE #inserted			
			TRUNCATE TABLE #deleted	
		END

		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@lot_ser = lot_ser,
				@bin_no = bin_no,
				@qty_to_unalloc = qty_to_alloc
		FROM	#lbp_unallocate_cursor
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC

	END  
  
	DROP TABLE #lbp_unallocate_cursor 
  
	--************************* Do allocate **********************************************************  
	
	SET @unalloc_type = 'Allocate By Lot/Bin: ' -- v2.0
  
	-- 1. Get template's settings  
	SELECT	@q_priority       = tran_priority,  
			@user_hold        = on_hold,  
			@pass_bin         = pass_bin,  
			@pkg_code  = pkg_code,  
			@assigned_user    = CASE WHEN user_group = ''   
             OR user_group LIKE '%DEFAULT%'   
				THEN NULL  
				ELSE user_group  END,   
			@alloc_type       = CASE dist_type   
				WHEN 'PrePack'   THEN 'PR'  
				WHEN 'ConsolePick'  THEN 'PT'  
				WHEN 'PickPack'  THEN 'PP'  
				WHEN 'PackageBuilder'  THEN 'PB' END  
	FROM tdc_plw_process_templates (NOLOCK)  
	WHERE template_code  = @template_code  
	AND UserID         = @user_id  
	AND location       = @location  
	AND order_type     = 'S'  
	AND type           = @type  
  
	SET @data = 'Line: ' + CAST(@line_no as varchar(3)) + '; Order Type: S; ' + 'Alloc Type: ' + @alloc_type +  '; Alloc Template Code: ' + @template_code + '; One4One/Con: ' + @type  
  
	-- 2. Get needed qty  
	IF EXISTS(SELECT * FROM ord_list (NOLOCK)  
		WHERE order_no  = @order_no AND order_ext = @order_ext AND line_no   = @line_no AND part_type = 'C')  
	BEGIN  
  
		SELECT @needed_qty = 0  
		SELECT @needed_qty = ISNULL((SELECT (ordered * qty_per_kit) - picked     -- Ordered - Shipped  
                  FROM tdc_ord_list_kit (NOLOCK)  
				WHERE order_no  = @order_no  
				AND order_ext = @order_ext  
                AND line_no   = @line_no  
                AND location  = @location         
                AND kit_part_no   = @part_no), 0) -   
			(SELECT ISNULL( (SELECT SUM(qty)  -- Allocated Qty  
                 FROM #sim_tdc_soft_alloc_tbl (NOLOCK)
				WHERE order_no   = @order_no  
                AND order_ext  = @order_ext  
                AND order_type = 'S'  
                AND location   = @location  
                AND line_no    = @line_no  
                AND part_no    = @part_no  
                GROUP BY location), 0))  
	END  
	ELSE  
	BEGIN  
		SELECT @needed_qty = 0  
		SELECT @needed_qty = ISNULL((SELECT ordered - shipped     -- Ordered - Shipped  
                  FROM ord_list  (NOLOCK) 
               WHERE order_no  = @order_no  
				AND order_ext = @order_ext  
                AND line_no   = @line_no  
                AND location  = @location         
                AND part_no   = @part_no), 0)  -   
			(SELECT ISNULL( (SELECT SUM(qty)  -- Allocated Qty  
                 FROM #sim_tdc_soft_alloc_tbl (NOLOCK)
				WHERE order_no   = @order_no  
                  AND order_ext  = @order_ext  
                  AND order_type = 'S'  
                  AND location   = @location  
                  AND line_no    = @line_no  
                  AND part_no    = @part_no  
                GROUP BY location), 0))  
		SELECT @needed_qty = @needed_qty * @conv_factor    
	END  
  
	CREATE TABLE #lbpa_allocate_cursor (
		row_id			int IDENTITY(1,1),
		lot_ser			varchar(25),
		bin_no			varchar(12),
		qty_to_alloc	decimal(20,8))

	INSERT #lbpa_allocate_cursor (lot_ser, bin_no, qty_to_alloc)
	SELECT	lot_ser, bin_no, qty FROM #plw_alloc_by_lot_bin WHERE sel_flg1 <> 0 AND qty > 0 

	CREATE INDEX #lbpa_allocate_cursor_ind0 ON #lbpa_allocate_cursor(row_id)
  
	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@lot_ser = lot_ser,
			@bin_no = bin_no,
			@qty_to_alloc = qty_to_alloc
	FROM	#lbpa_allocate_cursor
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

	WHILE (@@ROWCOUNT <> 0)
	BEGIN  
		-- 3. Check if we still need to allocate for the part_no / line_no  
		IF @needed_qty < @qty_to_alloc   
		BEGIN  
			DROP TABLE #lbpa_allocate_cursor
			RETURN  
		END  
  
		-- 4. Check if we have enough in stock qty  
		SELECT @in_stock_qty = 0  
		SELECT @in_stock_qty = qty  
		FROM lot_bin_stock (NOLOCK)  
		WHERE location  = @location  
		AND part_no   = @part_no  
		AND bin_no    = @bin_no  
		AND lot_ser   = @lot_ser   
  
		-- Get inventory for this part / location /lot / bin that a warehouse manager requested a MGTB2B move on.  
		SELECT @mgtb2b_qty = 0  
		SELECT @mgtb2b_qty =  SUM(qty_to_process)  
		FROM #sim_tdc_pick_queue (NOLOCK)  
		WHERE location = @location   
		AND part_no  = @part_no   
		AND lot      = @lot_ser   
		AND bin_no   = @bin_no   
		AND trans    = 'MGTBIN2BIN'  
		GROUP BY location  
  
		-- Get inventory for this part / location /lot / bin that a warehouse manager requested a PLWB2B move on.  
		SELECT @plwb2b_qty = 0  
		SELECT @plwb2b_qty =  SUM(qty_to_process)  
		FROM #sim_tdc_pick_queue (NOLOCK)  
		WHERE location = @location   
		AND part_no  = @part_no   
		AND lot      = @lot_ser   
		AND bin_no   = @bin_no   
		AND trans    = 'PLWB2B'  
		GROUP BY location  
  
		SELECT @in_stock_qty = @in_stock_qty - @mgtb2b_qty - @plwb2b_qty  
  
		SELECT @allocated_qty = 0  
		SELECT @allocated_qty = SUM(qty)      
        FROM #sim_tdc_soft_alloc_tbl (NOLOCK)  
        WHERE location   = @location  
        AND part_no    = @part_no  
        AND lot_ser    = @lot_ser   
        AND bin_no     = @bin_no  
        GROUP BY location  
  
		IF (@in_stock_qty - @allocated_qty) < @qty_to_alloc  
		BEGIN  
			DROP TABLE #lbpa_allocate_cursor
			RETURN  
		END  
  
		-- 5. Insert / Update tdc_soft_alloc_tbl  
		IF EXISTS(SELECT * FROM #sim_tdc_soft_alloc_tbl (NOLOCK)  
			WHERE order_no   = @order_no  
			AND order_ext  = @order_ext  
			AND order_type = 'S'  
			AND location   = @location  
			AND line_no    = @line_no  
			AND part_no    = @part_no  
			AND lot_ser    = @lot_ser  
            AND bin_no     = @bin_no)  
		BEGIN    

			INSERT	#deleted
			SELECT	*
			FROM	#sim_tdc_soft_alloc_tbl
			WHERE order_no      = @order_no  
			AND order_ext     = @order_ext  
			AND order_type    = 'S'  
			AND location      = @location  
			AND line_no       = @line_no  
			AND part_no       = @part_no  
			AND lot_ser       = @lot_ser  
            AND bin_no        = @bin_no

			INSERT	#inserted
			SELECT	*
			FROM	#sim_tdc_soft_alloc_tbl
			WHERE order_no      = @order_no  
			AND order_ext     = @order_ext  
			AND order_type    = 'S'  
			AND location      = @location  
			AND line_no       = @line_no  
			AND part_no       = @part_no  
			AND lot_ser       = @lot_ser  
            AND bin_no        = @bin_no

			UPDATE #inserted
			SET qty           = qty  + @qty_to_alloc,  
				dest_bin      = @pass_bin,  
				q_priority    = @q_priority,  
				assigned_user = @assigned_user,  
				user_hold     = @user_hold,  
				pkg_code      = @pkg_code  
			WHERE order_no      = @order_no  
			AND order_ext     = @order_ext  
			AND order_type    = 'S'  
			AND location      = @location  
			AND line_no       = @line_no  
			AND part_no       = @part_no  
			AND lot_ser       = @lot_ser  
            AND bin_no        = @bin_no

			UPDATE #sim_tdc_soft_alloc_tbl
			SET qty           = qty  + @qty_to_alloc,  
				dest_bin      = @pass_bin,  
				q_priority    = @q_priority,  
				assigned_user = @assigned_user,  
				user_hold     = @user_hold,  
				pkg_code      = @pkg_code  
			WHERE order_no      = @order_no  
			AND order_ext     = @order_ext  
			AND order_type    = 'S'  
			AND location      = @location  
			AND line_no       = @line_no  
			AND part_no       = @part_no  
			AND lot_ser       = @lot_ser  
            AND bin_no        = @bin_no  

			EXEC dbo.cvo_sim_tdc_soft_alloc_tbl_trg_sp 'UPDATE','','qty'
			TRUNCATE TABLE #inserted			
			TRUNCATE TABLE #deleted	
		END  
		ELSE  
		BEGIN  

			INSERT	#inserted
			VALUES (@order_no, @order_ext, @location, @line_no, @part_no,  @lot_ser,  @bin_no, @qty_to_alloc, 'S',  
				@bin_no, @pass_bin, @alloc_type, @q_priority, @assigned_user, @user_hold, @pkg_code)			

			INSERT INTO #sim_tdc_soft_alloc_tbl (order_no, order_ext, location, line_no, part_no,lot_ser, bin_no, qty, order_type, 
				target_bin, dest_bin, alloc_type, q_priority, assigned_user, user_hold, pkg_code)  
			VALUES (@order_no, @order_ext, @location, @line_no, @part_no,  @lot_ser,  @bin_no, @qty_to_alloc, 'S',  
				@bin_no, @pass_bin, @alloc_type, @q_priority, @assigned_user, @user_hold, @pkg_code)  

			EXEC dbo.cvo_sim_tdc_soft_alloc_tbl_trg_sp 'INSERT'
			TRUNCATE TABLE #inserted			
			TRUNCATE TABLE #deleted	
		END  
  
 		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@lot_ser = lot_ser,
				@bin_no = bin_no,
				@qty_to_alloc = qty_to_alloc
		FROM	#lbpa_allocate_cursor
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC
	END  
  
	DROP TABLE #lbpa_allocate_cursor

	IF EXISTS(SELECT 1 FROM CVO_ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND line_no = @line_no AND is_customized = 'S') 
	BEGIN
		IF EXISTS (SELECT 1 FROM #sim_tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND order_type = 'S')
		BEGIN

			EXEC dbo.CVO_sim_Create_Frame_Bin_Moves_sp @order_no, @order_ext

			-- Code taken from CVO_ord_list_kit_trg
			CREATE TABLE #kit_table (
				row_id				int IDENTITY(1,1),
				location			varchar(10),
				part_no				varchar(30),
				order_no			int,
				order_ext			int,
				line_no				int,
				part_no_original	varchar(30),
				part_type			varchar(10))

			INSERT	#kit_table (location, part_no, order_no, order_ext, line_no, part_no_original, part_type)
			SELECT	a.location,
					a.part_no,
					a.order_no,
					a.order_ext,
					a.line_no,		
					a.part_no_original,
					b.part_type 
			FROM	CVO_ord_list_kit a
			JOIN	ord_list b (NOLOCK)
			ON		a.order_no = b.order_no
			AND		a.order_ext = b.order_ext
			AND		a.line_no = b.line_no
			WHERE	a.replaced = 'S'
			AND		b.status IN ('N','A','C','Q')
			AND		a.order_no = @order_no
			AND		a.order_ext = @order_ext
			ORDER BY order_no, order_ext, line_no

			SET @last_row_id = 0
			SET @last_line = 0

			SELECT	TOP 1 @location = location,
					@part_no = part_no,
					@order_no = order_no,
					@order_ext = order_ext,
					@line_no = line_no,
					@row_id = row_id,
					@part_no_original = part_no_original,
					@part_type = part_type
			FROM	#kit_table
			WHERE	row_id > @last_row_id
			ORDER BY row_id ASC

			WHILE @@ROWCOUNT <> 0
			BEGIN

				IF (@part_type <> 'C')
				BEGIN
					-- Get the qty from the ord_list record for the frame
					SELECT	@qty = ordered
					FROM	ord_list (NOLOCK)
					WHERE	order_no = @order_no
					AND		order_ext = @order_ext
					AND		line_no = @line_no
				
					-- Call custom routine to generate MGTB2B for sustituted component items
					EXEC dbo.CVO_sim_Create_Substitution_MGMB2B_Moves_sp @order_no, @order_ext, @line_no, @location, @part_no, @part_no, @part_no_original, @qty

				END
				ELSE
				BEGIN

					IF (@line_no > @last_line)
					BEGIN
						EXEC dbo.cvo_sim_process_custom_kit_sp @order_no, @order_ext, @line_no, 0
					END
					SET @last_line = @line_no

				END	

				SET @last_row_id = @row_id

				SELECT	TOP 1 @location = location,
						@part_no = part_no,
						@order_no = order_no,
						@order_ext = order_ext,
						@line_no = line_no,
						@row_id = row_id,
						@part_no_original = part_no_original,
						@part_type = part_type -- v1.4
				FROM	#kit_table
				WHERE	row_id > @last_row_id
				ORDER BY row_id ASC
			END

			DROP TABLE #kit_table
			
		END 
	END
  
	IF @alloc_type = 'PR'  
		SELECT @pre_pack_flag = 'Y'  
	ELSE  
		SELECT @pre_pack_flag = 'N'  
  
	------------------------------------------------------------------------------------------------------------------  
	-- Consolidation Number / ONE_FOR_ONE logic  
	------------------------------------------------------------------------------------------------------------------  
	IF NOT EXISTS(SELECT *  FROM #sim_tdc_cons_ords(NOLOCK)  
        WHERE order_no  = @order_no AND order_ext = @order_ext AND location  = @location)  
	BEGIN  
		IF @con_no_passed_in = 0 --ONE_FOR_ONE  
		BEGIN  
   
			-- create a new record in tdc_main   
			--get the next available cons number  
			SELECT @next_con_no = MAX(consolidation_no) + 1 FROM #sim_tdc_main
	   
			--our generic description and name   
			SELECT @con_name = 'Ord ' +  CONVERT(VARCHAR(20),@order_no) + ' Ext ' + CONVERT(VARCHAR(4),@order_ext)   
			SELECT @con_desc = 'Ord ' +  CONVERT(VARCHAR(20),@order_no) + ' Ext ' + CONVERT(VARCHAR(4),@order_ext)   
	   
	   
			INSERT INTO #sim_tdc_main WITH (ROWLOCK)( consolidation_no, consolidation_name, order_type,
				[description], status, created_by, creation_date, pre_pack  )   
			VALUES (@next_con_no , @con_name, 'S', @con_desc, 'O' , @user_id , GETDATE(), @pre_pack_flag )  
	   
			--only one order per consolidation set for ONE_FOR_ONE   
			DELETE FROM #sim_tdc_cons_ords   
			WHERE order_no = @order_no  
			AND order_ext = @order_ext  
			AND location = @location  
			AND order_type = 'S'  
	  
			INSERT INTO #sim_tdc_cons_ords WITH (ROWLOCK)(consolidation_no, order_no, order_ext,location, 
					status, seq_no, print_count, order_type, alloc_type)  
			VALUES ( @next_con_no,@order_no,@order_ext,@location,'O', 1 , 0, 'S', @alloc_type)  
	     
		END  
		------------------------------------------------------------------------------------------------------------------  
		ELSE --NOT ONE_FOR_ONE  
		------------------------------------------------------------------------------------------------------------------  
		BEGIN  
  
			SELECT @con_seq_no = @con_seq_no + 1   
	  
			--Make sure the user is some how getting an order already assigned  
			SELECT @con_no_from_temp_table = 0  
			SELECT @con_no_from_temp_table = consolidation_no  
			FROM #so_alloc_management  
			WHERE order_no  = @order_no  
			AND order_ext = @order_ext  
			AND location  = @location  
	  
			IF ISNULL(@con_no_from_temp_table, 0) = 0   
			BEGIN  
				--We want to ensure that we are not inserting another record for the same order , ext     
				IF NOT EXISTS(SELECT * FROM #sim_tdc_cons_ords (NOLOCK)  
					WHERE order_no = @order_no AND order_ext = @order_ext AND order_type = 'S' AND location = @location )   
				BEGIN   
					INSERT INTO #sim_tdc_cons_ords WITH (ROWLOCK)(consolidation_no, order_no,order_ext,location,status,seq_no,print_count,order_type, alloc_type)   -- v3.5
					VALUES ( @con_no_passed_in, @order_no,@order_ext,@location,'O', @con_seq_no , 0, 'S', @alloc_type)  
				END  
			END  
		END --Not ONE_FOR_ONE    
	END  
  
	IF @con_no_passed_in != 0  
	BEGIN  
		UPDATE #sim_tdc_main  
		SET pre_pack = @pre_pack_flag  
		WHERE consolidation_no = @con_no_passed_in  
	END  

	SET @cur_status = 0

	IF EXISTS (SELECT 1 FROM #sim_cvo_soft_alloc_hdr (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND status = -3)
		SET @cur_status = -3

	CREATE TABLE #tmp_alloc (
		line_no		int,
		qty			decimal(20,8))

	SELECT	@alloc_qty = SUM(qty) 
	FROM	#sim_tdc_soft_alloc_tbl (NOLOCK)
	WHERE	order_no = @order_no
	AND		order_ext= @order_ext
	AND		line_no = @line_no
	AND		part_no = @part_no

	IF (@alloc_qty IS NULL)
		SET @alloc_qty = 0

	INSERT	#tmp_alloc
	SELECT	line_no, SUM(qty)
	FROM	#sim_tdc_soft_alloc_tbl (NOLOCK)
	WHERE	order_no = @order_no
	AND		order_ext= @order_ext
	GROUP BY line_no

	SELECT	@sa_qty = SUM(ordered)
	FROM	ord_list (NOLOCK)
	WHERE	order_no = @order_no
	AND		order_ext= @order_ext
	AND		line_no = @line_no
	AND		part_no = @part_no

	IF	(@sa_qty = @alloc_qty) -- Line Fully allocated
	BEGIN

		UPDATE	#sim_cvo_soft_alloc_det
		SET		status = -2
		WHERE	order_no = @order_no
		AND		order_ext= @order_ext
		AND		line_no = @line_no
		AND		part_no = @part_no
		AND		status IN (0,-1,-3,1)
	
		UPDATE	#sim_cvo_soft_alloc_det 
		SET		status = -2
		WHERE	order_no = @order_no
		AND		order_ext= @order_ext
		AND		line_no = @line_no
		AND		kit_part = 1
		AND		status IN (0,-1,-3,1) 

		IF NOT EXISTS (SELECT 1 FROM #sim_cvo_soft_alloc_det (NOLOCK) WHERE order_no = @order_no AND order_ext= @order_ext AND status IN (0,-1,-3,1))
		BEGIN
			UPDATE	#sim_cvo_soft_alloc_hdr
			SET		status = -2
			WHERE	order_no = @order_no
			AND		order_ext= @order_ext
			AND		status IN (0,-1,-3,1) 
		END

		DELETE	#sim_cvo_soft_alloc_hdr 
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		AND		status = -2 

		DELETE	#sim_cvo_soft_alloc_det 
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		AND		status = -2 

		SELECT	@new_soft_alloc_no = soft_alloc_no
		FROM	cvo_soft_alloc_no_assign (NOLOCK)
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext

	END
	ELSE
	BEGIN
		UPDATE	#sim_cvo_soft_alloc_hdr 
		SET		status = -2
		WHERE	order_no = @order_no
		AND		order_ext= @order_ext
		AND		status IN (0,-1,-3)

		UPDATE	#sim_cvo_soft_alloc_det
		SET		status = -2
		WHERE	order_no = @order_no
		AND		order_ext= @order_ext				
		AND		status IN (0,-1,-3)

		DELETE	#sim_cvo_soft_alloc_hdr 
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		AND		status = -2 

		DELETE	#sim_cvo_soft_alloc_det
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		AND		status = -2 

		SET	@new_soft_alloc_no = NULL

		SELECT	@new_soft_alloc_no = soft_alloc_no
		FROM	cvo_soft_alloc_no_assign (NOLOCK)
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext

		-- Insert cvo_soft_alloc header
		INSERT INTO #sim_cvo_soft_alloc_hdr  (soft_alloc_no, order_no, order_ext, location, bo_hold, status) 
		VALUES (@new_soft_alloc_no, @order_no, @order_ext, @location, 0, @cur_status)		

		INSERT INTO	#sim_cvo_soft_alloc_det  (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity, 
									kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status, add_case_flag) 
		SELECT	@new_soft_alloc_no, @order_no, @order_ext, a.line_no, a.location, a.part_no, ((a.ordered - a.shipped) - ISNULL(c.qty,0)), 
				0, 0, 0, b.is_case, b.is_pattern, b.is_pop_gif, @cur_status, b.add_case -- v1.8
		FROM	ord_list a (NOLOCK)
		JOIN	cvo_ord_list b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.line_no
		LEFT JOIN
				#tmp_alloc c (NOLOCK)
		ON		a.line_no = c.line_no
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @order_ext
		AND		((a.ordered - a.shipped) - ISNULL(c.qty,0)) > 0

		INSERT INTO	#sim_cvo_soft_alloc_det (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
									kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status)			
		SELECT	@new_soft_alloc_no, @order_no, @order_ext, a.line_no, a.location, b.part_no, ((a.ordered - a.shipped) - ISNULL(c.qty,0)), 
				1, 0, 0, 0, 0, 0, @cur_status
		FROM	ord_list a (NOLOCK)
		JOIN	cvo_ord_list_kit b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.line_no
		LEFT JOIN
				#tmp_alloc c (NOLOCK)
		ON		a.line_no = c.line_no
		AND		a.line_no = c.line_no
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @order_ext	
		AND		b.replaced = 'S'
		AND		((a.ordered - a.shipped) - ISNULL(c.qty,0)) > 0 
	END

	DROP TABLE #tmp_alloc
  
	DELETE #sim_tdc_main WHERE consolidation_no NOT IN (SELECT consolidation_no  FROM #sim_tdc_cons_ords (NOLOCK))
 
	RETURN   
END
GO
GRANT EXECUTE ON  [dbo].[sim_tdc_plw_so_allocbylot_process_sp] TO [public]
GO
