SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
      
CREATE PROCEDURE  [dbo].[sim_tdc_plw_so_unallocate_sp]	@user_id     VARCHAR(50),      
													@con_no  int        
AS      
BEGIN
	-- NOTE: Based on tdc_plw_so_unallocate_sp v3.2 - All changes must be kept in sync     
	DECLARE	@trans_source  VARCHAR(5),       
			@trans  VARCHAR(10),       
			@trans_type_no INT,      
			@order_no INT,       
			@order_ext INT,       
			@location VARCHAR(10),       
			@line_no INT,            
			@part_no VARCHAR(30),            
			@lot_ser VARCHAR(25),          
			@bin_no  VARCHAR(12),         
			@queue_qty DECIMAL(20,8),      
			@alloc_qty DECIMAL(20,8),      
			@tx_lock CHAR(2),      
			@next_op VARCHAR(50),      
			@target_bin     VARCHAR(12),      
			@tran_id INT,
			@mfg_batch varchar(25),
			@unalloc_type varchar(30),
			@iret int,
			@err_ret int,
			@consolidation_no int

	DECLARE	@t_bin_no	varchar(12),
			@t_next_op	varchar(12),
			@t_qty		decimal(20,8),
			@qty_override decimal(20,8),
			@sa_qty		decimal(20,8),
			@cur_status int 
		
	DECLARE	@row_id				int,
			@last_row_id		int,
			@line_row_id		int,
			@last_line_row_id	int

	----------------------------------------------------------------------------------------------      
	---- If nothing selected to unallocate, exit      
	----------------------------------------------------------------------------------------------      
	IF NOT EXISTS(SELECT * FROM #so_alloc_management WHERE sel_flg2 <> 0)      
		RETURN      

	CREATE TABLE #plw_unalloc_cur (
		row_id			int IDENTITY(1,1),
		trans_source	varchar(5),
		trans			varchar(10),
		trans_type_no	int,
		order_no		int,
		order_ext		int,
		location		varchar(10),
		line_no			int,
		part_no			varchar(30),
		lot				varchar(25),
		bin_no			varchar(12),
		qty_to_process	decimal(20,8),
		qty				decimal(20,8),
		tx_lock			char(2),
		next_op			varchar(30))	

	------------------------------------------------------------------------------------------------------------------------      
	---- Build the cursor for unallocation of STDPICK's and SO-CDOCKS      
	------------------------------------------------------------------------------------------------------------------------      

	IF EXISTS(SELECT line_no FROM #so_soft_alloc_byline_tbl)      
	BEGIN      

		SET @unalloc_type = 'UnAllocate By Line: ' 

		INSERT	#plw_unalloc_cur (trans_source, trans, trans_type_no, order_no, order_ext, location, line_no, part_no, 
							lot, bin_no, qty_to_process, qty, tx_lock, next_op)
		SELECT	p.trans_source, p.trans,  p.trans_type_no, s.order_no, s.order_ext, p.location, s.line_no,            
				p.part_no,      p.lot,    p.bin_no,        p.qty_to_process, s.qty,      
				p.tx_lock, p.next_op      
		FROM	#sim_tdc_pick_queue       p (NOLOCK),      
				#sim_tdc_soft_alloc_tbl   s (NOLOCK),      
				#so_alloc_management t,      
				#so_soft_alloc_byline_tbl u      
		WHERE	p.trans               IN('STDPICK', 'SO-CDOCK', 'PKGBLD')      
		AND		t.sel_flg2     != 0      
		AND s.order_no      = t.order_no      
		AND s.order_ext           = t.order_ext      
		AND s.location       = t.location      
		AND s.order_type      = 'S'      
		AND s.part_no      = p.part_no      
		AND p.location      = t.location      
		AND p.line_no      = s.line_no        
		AND ISNULL(p.bin_no,'')   = ISNULL(s.bin_no ,'')      
		AND ISNULL(p.lot,   '')   = ISNULL(s.lot_ser ,'')      
		AND p.trans_type_no       = t.order_no       
		AND p.trans_type_ext      = t.order_ext      
		AND s.line_no      = u.line_no      
		AND s.part_no      = u.part_no      
	END      
	ELSE      
	BEGIN    

		SET @unalloc_type = 'UnAllocate Order: ' 
  
		INSERT	#plw_unalloc_cur (trans_source, trans, trans_type_no, order_no, order_ext, location, line_no, part_no, 
							lot, bin_no, qty_to_process, qty, tx_lock, next_op)
		SELECT	p.trans_source, p.trans,  p.trans_type_no, s.order_no, s.order_ext, p.location, s.line_no,            
				p.part_no,      p.lot,    p.bin_no,        p.qty_to_process, s.qty,      p.tx_lock, p.next_op      
		FROM	#sim_tdc_pick_queue       p (NOLOCK),      
				#sim_tdc_soft_alloc_tbl   s (NOLOCK),      
				#so_alloc_management t      
		WHERE p.trans              IN ('STDPICK', 'SO-CDOCK', 'PKGBLD')      
		AND t.sel_flg2     != 0      
		AND s.order_no      = t.order_no      
		AND s.order_ext           = t.order_ext      
		AND s.location       = t.location      
		AND s.order_type      = 'S'      
		AND s.part_no      = p.part_no      
		AND p.location      = t.location      
		AND p.line_no      = s.line_no        
		AND ISNULL(p.bin_no,'')   = ISNULL(s.bin_no ,'')      
		AND ISNULL(p.lot,'')      = ISNULL(s.lot_ser ,'')      
		AND p.trans_type_no = t.order_no       
		AND p.trans_type_ext = t.order_ext       
	END      
        
	SET @last_row_id = 0 

	SELECT	TOP 1 @row_id = row_id,
			@trans_source = trans_source, 
			@trans = trans,  
			@trans_type_no = trans_type_no, 
			@order_no = order_no, 
			@order_ext = order_ext, 
			@location = location,  
			@line_no = line_no,            
			@part_no = part_no,
			@lot_ser = lot,    
			@bin_no = bin_no, 
			@queue_qty = qty_to_process, 
			@alloc_qty = qty, 
			@tx_lock = tx_lock, 
			@next_op = next_op
	FROM	#plw_unalloc_cur
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

	WHILE (@@ROWCOUNT <> 0)
	BEGIN

		----------------------------------------------------------------------------------------------      
		---- Make sure the transaction is not locked or in progress      
		----------------------------------------------------------------------------------------------      

		SELECT	@mfg_batch = mfg_batch
		FROM	#sim_tdc_pick_queue (NOLOCK)
		WHERE	trans_source = @trans_source
		AND		trans = @trans
		AND		trans_type_no = @trans_type_no
		AND		trans_type_ext = @order_ext
		AND		line_no = @line_no

		IF NOT EXISTS (SELECT 1 FROM #so_soft_alloc_byline_tbl WHERE order_no = @order_no AND order_ext = @order_ext AND line_no = @line_no AND qty_override <> 0)
		BEGIN
			IF NOT (@tx_lock = 'H' AND (PATINDEX('%SHIP_COMP%',@mfg_batch) > 0))
			BEGIN
				IF ((@tx_lock NOT IN ('R', '3', 'P', 'V', 'L', 'G', 'E')) OR (@queue_qty < @alloc_qty))  
					OR EXISTS (SELECT * FROM tdc_bin_master (NOLOCK) WHERE location = @location      
					AND bin_no   = @bin_no AND (   usage_type_code = 'RECEIPT' OR usage_type_code = 'PRODOUT'))      
				BEGIN    
					DROP TABLE #plw_unalloc_cur
					RETURN      
				END      
			END
		END

		IF EXISTS(SELECT line_no FROM #so_soft_alloc_byline_tbl)      
		BEGIN
			SELECT	@alloc_qty = qty_override
			FROM	#so_soft_alloc_byline_tbl
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
			AND		line_no = @line_no
			AND		qty_override <> 0
		END
		----------------------------------------------------------------------------------------------      
		---- Lot/Bin Tracked parts       
		----------------------------------------------------------------------------------------------       
		IF @lot_ser IS NOT NULL AND @bin_no IS NOT NULL      
		BEGIN      
      
			IF (@queue_qty - @alloc_qty) = 0      
			BEGIN        
				IF EXISTS(SELECT line_no FROM #so_soft_alloc_byline_tbl)      
				BEGIN      
					DELETE FROM #sim_tdc_pick_queue      
					FROM #sim_tdc_pick_queue a, #so_soft_alloc_byline_tbl b      
					WHERE  a.trans         = @trans           
					AND  a.trans_type_no  = @order_no       
					AND  a.trans_type_ext = @order_ext            
					AND  a.location       = @location           
					AND  a.part_no        = @part_no      
					AND  a.lot           = @lot_ser      
					AND  a.bin_no         = @bin_no           
					AND a.line_no        = @line_no      
					AND     a.trans_source   = @trans_source       
					AND  a.line_no   = b.line_no      
					AND  a.part_no   = b.part_no      
				END   
				ELSE      
				BEGIN      
					DELETE FROM #sim_tdc_pick_queue      
					WHERE  trans         = @trans           
					AND  trans_type_no  = @order_no       
					AND  trans_type_ext = @order_ext            
					AND  location       = @location           
					AND  part_no        = @part_no      
					AND  lot           = @lot_ser      
					AND  bin_no         = @bin_no           
					AND line_no        = @line_no      
					AND     trans_source   = @trans_source     
				END      

				IF EXISTS (SELECT 1 FROM #sim_tdc_pick_queue (NOLOCK) WHERE trans_type_no = @order_no AND trans_type_ext = @order_ext 
					AND part_no = @part_no AND line_no = @line_no AND trans = 'MGTB2B')
				BEGIN		
					INSERT	#deleted
					SELECT	a.*
					FROM	#sim_tdc_soft_alloc_tbl a
					JOIN	#sim_tdc_pick_queue b (NOLOCK)
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
					JOIN	#sim_tdc_pick_queue b (NOLOCK)
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
					JOIN	#sim_tdc_pick_queue b (NOLOCK)
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
					JOIN	#sim_tdc_pick_queue b (NOLOCK)
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

				DELETE	#sim_tdc_pick_queue
				WHERE	trans         = 'STDPICK'           
				AND		trans_type_no  = @order_no       
				AND		trans_type_ext = @order_ext            
				AND		location       = @location           
				AND		line_no        = @line_no      
				AND		trans_source   = 'PLW'
				AND		company_no = 'CF'
               
			END --(@queue_qty - @alloc_qty) = 0      
			ELSE      
			BEGIN  --(@queue_qty - @alloc_qty) != 0      
				IF EXISTS(SELECT line_no FROM #so_soft_alloc_byline_tbl)      
				BEGIN      
					UPDATE #sim_tdc_pick_queue      
					SET qty_to_process =  (@queue_qty - @alloc_qty)      
					FROM #sim_tdc_pick_queue a, #so_soft_alloc_byline_tbl b      
					WHERE a.trans          = @trans           
					AND a.trans_type_no     = @order_no       
					AND a.trans_type_ext  = @order_ext      
					AND a.location         = @location       
					AND a.part_no  = @part_no      
					AND a.lot        = @lot_ser      
					AND a.bin_no     = @bin_no      
					AND a.line_no  = @line_no      
					AND a.trans_Source   = @trans_source       
					AND a.line_no   = b.line_no      
					AND a.part_no   = b.part_no      
				END      
				ELSE      
				BEGIN      
					UPDATE #sim_tdc_pick_queue      
					SET qty_to_process =  (@queue_qty - @alloc_qty)      
					WHERE trans          = @trans           
					AND trans_type_no     = @order_no       
					AND trans_type_ext  = @order_ext      
					AND location         = @location       
					AND part_no  = @part_no      
					AND lot        = @lot_ser      
					AND bin_no     = @bin_no      
					AND line_no  = @line_no      
					AND trans_Source   = @trans_source       
				END      

				UPDATE	#sim_tdc_pick_queue      
				SET		qty_to_process =  (@queue_qty - @alloc_qty)      
				WHERE	trans          = 'MGTB2B'           
				AND		trans_type_no     = @order_no       
				AND		trans_type_ext  = @order_ext      
				AND		location         = @location       
				AND		line_no  = @line_no      
				AND		trans_Source   = 'MGT' 
      
			END --(@queue_qty - @alloc_qty) != 0        
      
			IF EXISTS(SELECT line_no FROM #so_soft_alloc_byline_tbl)      
			BEGIN      
				DELETE #sim_tdc_soft_alloc_tbl      
				FROM #sim_tdc_soft_alloc_tbl a, #so_soft_alloc_byline_tbl b      
				WHERE a.order_no  = @order_no      
				AND a.order_ext = @order_ext      
				AND a.order_type = 'S'      
				AND a.location  = @location      
				AND a.line_no   = @line_no      
				AND a.part_no   = @part_no      
				AND a.lot_ser = @lot_ser      
				AND a.bin_no = @bin_no      
				AND a.line_no = b.line_no      
				AND a.part_no = b.part_no
				AND b.qty_override = 0 

				SELECT	@qty_override = qty_override
				FROM	#so_soft_alloc_byline_tbl
				WHERE	order_no  = @order_no      
				AND		order_ext = @order_ext      
				AND		line_no = @line_no      
				AND		part_no = @part_no  

				IF (@qty_override <> 0)
				BEGIN

					SELECT	@sa_qty = qty 
					FROM	#sim_tdc_soft_alloc_tbl (NOLOCK) 
					WHERE	order_no = @order_no 
					AND		order_ext = @order_ext 
					AND		line_no = @line_no 
					AND		part_no = @part_no
					AND		bin_no = @bin_no

					IF (@qty_override >= @sa_qty AND @qty_override <> 0) 
					BEGIN
						DELETE	#sim_tdc_soft_alloc_tbl      
						FROM	#sim_tdc_soft_alloc_tbl a, #so_soft_alloc_byline_tbl b      
						WHERE	a.order_no  = @order_no      
						AND		a.order_ext = @order_ext      
						AND		a.order_type = 'S'      
						AND		a.location  = @location      
						AND		a.line_no   = @line_no      
						AND		a.part_no   = @part_no      
						AND		a.lot_ser = @lot_ser      
						AND		a.bin_no = @bin_no      
						AND		a.line_no = b.line_no      
						AND		a.part_no = b.part_no		
		
						UPDATE	#so_soft_alloc_byline_tbl
						SET		qty_override = qty_override - @qty_override -- v2.2 @sa_qty
						WHERE	order_no  = @order_no      
						AND		order_ext = @order_ext      
						AND		line_no = @line_no      
						AND		part_no = @part_no 
					END
					ELSE -- Consume partial
					BEGIN
						INSERT	#deleted
						SELECT	a.*
						FROM	#sim_tdc_soft_alloc_tbl a, #so_soft_alloc_byline_tbl b      
						WHERE	a.order_no  = @order_no      
						AND		a.order_ext = @order_ext      
						AND		a.order_type = 'S'      
						AND		a.location  = @location      
						AND		a.line_no   = @line_no      
						AND		a.part_no   = @part_no      
						AND		a.lot_ser = @lot_ser      
						AND		a.bin_no = @bin_no      
						AND		a.line_no = b.line_no      
						AND		a.part_no = b.part_no

						INSERT	#inserted
						SELECT	a.*
						FROM	#sim_tdc_soft_alloc_tbl a, #so_soft_alloc_byline_tbl b      
						WHERE	a.order_no  = @order_no      
						AND		a.order_ext = @order_ext      
						AND		a.order_type = 'S'      
						AND		a.location  = @location      
						AND		a.line_no   = @line_no      
						AND		a.part_no   = @part_no      
						AND		a.lot_ser = @lot_ser      
						AND		a.bin_no = @bin_no      
						AND		a.line_no = b.line_no      
						AND		a.part_no = b.part_no

						UPDATE	a
						SET		qty = qty - @qty_override,
								trg_off    = 1   
						FROM	#inserted a, #so_soft_alloc_byline_tbl b      
						WHERE	a.order_no  = @order_no      
						AND		a.order_ext = @order_ext      
						AND		a.order_type = 'S'      
						AND		a.location  = @location      
						AND		a.line_no   = @line_no      
						AND		a.part_no   = @part_no      
						AND		a.lot_ser = @lot_ser      
						AND		a.bin_no = @bin_no      
						AND		a.line_no = b.line_no      
						AND		a.part_no = b.part_no
					
						UPDATE	a
						SET		qty = qty - @qty_override,
								trg_off    = 1   
						FROM	#sim_tdc_soft_alloc_tbl a, #so_soft_alloc_byline_tbl b      
						WHERE	a.order_no  = @order_no      
						AND		a.order_ext = @order_ext      
						AND		a.order_type = 'S'      
						AND		a.location  = @location      
						AND		a.line_no   = @line_no      
						AND		a.part_no   = @part_no      
						AND		a.lot_ser = @lot_ser      
						AND		a.bin_no = @bin_no      
						AND		a.line_no = b.line_no      
						AND		a.part_no = b.part_no		

						EXEC dbo.cvo_sim_tdc_soft_alloc_tbl_trg_sp 'UPDATE','','qty'
						TRUNCATE TABLE #inserted			
						TRUNCATE TABLE #deleted	

						INSERT	#deleted
						SELECT	a.*
						FROM	#sim_tdc_soft_alloc_tbl a, #so_soft_alloc_byline_tbl b      
						WHERE	a.order_no  = @order_no      
						AND		a.order_ext = @order_ext      
						AND		a.order_type = 'S'      
						AND		a.location  = @location      
						AND		a.line_no   = @line_no      
						AND		a.part_no   = @part_no      
						AND		a.lot_ser = @lot_ser      
						AND		a.bin_no = @bin_no      
						AND		a.line_no = b.line_no      
						AND		a.part_no = b.part_no

						INSERT	#inserted
						SELECT	a.*
						FROM	#sim_tdc_soft_alloc_tbl a, #so_soft_alloc_byline_tbl b      
						WHERE	a.order_no  = @order_no      
						AND		a.order_ext = @order_ext      
						AND		a.order_type = 'S'      
						AND		a.location  = @location      
						AND		a.line_no   = @line_no      
						AND		a.part_no   = @part_no      
						AND		a.lot_ser = @lot_ser      
						AND		a.bin_no = @bin_no      
						AND		a.line_no = b.line_no      
						AND		a.part_no = b.part_no

						UPDATE	a
						SET		trg_off    = NULL
						FROM	#inserted a, #so_soft_alloc_byline_tbl b      
						WHERE	a.order_no  = @order_no      
						AND		a.order_ext = @order_ext      
						AND		a.order_type = 'S'      
						AND		a.location  = @location      
						AND		a.line_no   = @line_no      
						AND		a.part_no   = @part_no      
						AND		a.lot_ser = @lot_ser      
						AND		a.bin_no = @bin_no      
						AND		a.line_no = b.line_no      
						AND		a.part_no = b.part_no

						UPDATE	a
						SET		trg_off    = NULL
						FROM	#sim_tdc_soft_alloc_tbl a, #so_soft_alloc_byline_tbl b      
						WHERE	a.order_no  = @order_no      
						AND		a.order_ext = @order_ext      
						AND		a.order_type = 'S'      
						AND		a.location  = @location      
						AND		a.line_no   = @line_no      
						AND		a.part_no   = @part_no      
						AND		a.lot_ser = @lot_ser      
						AND		a.bin_no = @bin_no      
						AND		a.line_no = b.line_no      
						AND		a.part_no = b.part_no		

						EXEC dbo.cvo_sim_tdc_soft_alloc_tbl_trg_sp 'UPDATE','',''
						TRUNCATE TABLE #inserted			
						TRUNCATE TABLE #deleted	

		
						UPDATE	#so_soft_alloc_byline_tbl
						SET		qty_override = qty_override - @qty_override -- v2.2 @sa_qty
						WHERE	order_no  = @order_no      
						AND		order_ext = @order_ext      
						AND		line_no = @line_no      
						AND		part_no = @part_no 
					END
				END
			END      
			ELSE      
			BEGIN      
				DELETE #sim_tdc_soft_alloc_tbl         
				WHERE order_no  = @order_no      
				AND order_ext = @order_ext      
				AND order_type = 'S'      
				AND location  = @location      
				AND line_no   = @line_no      
				AND part_no   = @part_no      
				AND lot_ser = @lot_ser      
				AND bin_no = @bin_no      
			END      
		END --LOT/BIN tracked part      
		ELSE      
		BEGIN --NON LOT/BIN tracked part      
			 ----------------------------------------------------------------------------------------------      
			---- NON Lot/Bin Tracked parts       
			----------------------------------------------------------------------------------------------       
			IF (@queue_qty - @alloc_qty) = 0 --Delete from the queue      
			BEGIN          
				IF EXISTS(SELECT line_no FROM #so_soft_alloc_byline_tbl)      
				BEGIN      
					DELETE FROM #sim_tdc_pick_queue      
					FROM #sim_tdc_pick_queue a, #so_soft_alloc_byline_tbl b      
					WHERE  a.trans         = @trans           
					AND  a.trans_type_no  = @order_no       
					AND  a.trans_type_ext = @order_ext            
					AND  a.location       = @location           
					AND  a.part_no        = @part_no      
					AND  a.lot             IS NULL      
					AND  a.bin_no           IS NULL          
					AND a.line_no        = @line_no      
					AND  a.trans_source   = @trans_source       
					AND  a.line_no   = b.line_no      
					AND  a.part_no   = b.part_no      
				END      
				ELSE      
				BEGIN      
					DELETE FROM #sim_tdc_pick_queue      
					WHERE  trans         = @trans           
					AND  trans_type_no = @order_no       
					AND  trans_type_ext = @order_ext            
					AND  location       = @location           
					AND  part_no        = @part_no      
					AND  lot             IS NULL      
					AND  bin_no           IS NULL          
					AND line_no        = @line_no      
					AND  trans_source   = @trans_source       
				END      
			END --(@queue_qty - @alloc_qty) = 0      
			ELSE      
			BEGIN  --(@queue_qty - @alloc_qty) != 0      
				--Update the Qty_To_Process            
				IF EXISTS(SELECT line_no FROM #so_soft_alloc_byline_tbl)      
				BEGIN      
					UPDATE #sim_tdc_pick_queue      
					SET qty_to_process =  (@queue_qty - @alloc_qty)      
					FROM #sim_tdc_pick_queue a, #so_soft_alloc_byline_tbl b      
					WHERE a.trans          = @trans           
					AND a.trans_type_no     = @order_no       
					AND a.trans_type_ext  = @order_ext      
					AND a.location         = @location       
					AND a.part_no  = @part_no      
					AND a.lot          IS NULL      
					AND a.bin_no       IS NULL      
					AND a.line_no  = @line_no      
					AND a.trans_Source   = @trans_source       
					AND a.line_no   = b.line_no      
					AND a.part_no   = b.part_no      
				END      
				ELSE      
				BEGIN      
					UPDATE #sim_tdc_pick_queue      
					SET qty_to_process =  (@queue_qty - @alloc_qty)      
					WHERE trans          = @trans           
					AND trans_type_no     = @order_no       
					AND trans_type_ext  = @order_ext      
					AND location         = @location       
					AND part_no  = @part_no      
					AND lot          IS NULL      
					AND bin_no       IS NULL      
					AND line_no  = @line_no      
					AND trans_Source   = @trans_source       
				END      
			END --(@queue_qty - @alloc_qty) != 0       
      
			IF EXISTS(SELECT line_no FROM #so_soft_alloc_byline_tbl)      
			BEGIN      
				DELETE FROM #sim_tdc_soft_alloc_tbl      
				FROM #sim_tdc_soft_alloc_tbl a, #so_soft_alloc_byline_tbl b      
				WHERE a.order_no  = @order_no      
				AND a.order_ext = @order_ext      
				AND a.order_type = 'S'      
				AND a.location  = @location      
				AND a.line_no   = @line_no      
				AND a.part_no   = @part_no      
				AND a.lot_ser IS NULL      
				AND a.bin_no IS NULL      
				AND a.line_no = b.line_no      
				AND a.part_no = b.part_no      
			END      
			ELSE      
			BEGIN      
				DELETE FROM #sim_tdc_soft_alloc_tbl         
				WHERE order_no  = @order_no      
				AND order_ext = @order_ext      
				AND order_type = 'S'      
				AND location  = @location      
				AND line_no   = @line_no      
				AND part_no   = @part_no      
				AND lot_ser IS NULL      
				AND bin_no IS NULL      
			END      
		END --NON lb tracked      
 

		SET @last_row_id = @row_id 

		SELECT	TOP 1 @row_id = row_id,
				@trans_source = trans_source, 
				@trans = trans,  
				@trans_type_no = trans_type_no, 
				@order_no = order_no, 
				@order_ext = order_ext, 
				@location = location,  
				@line_no = line_no,            
				@part_no = part_no,
				@lot_ser = lot,    
				@bin_no = bin_no, 
				@queue_qty = qty_to_process, 
				@alloc_qty = qty, 
				@tx_lock = tx_lock, 
				@next_op = next_op
		FROM	#plw_unalloc_cur
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC   
	END
      
	DROP TABLE #plw_unalloc_cur
     
	------------------------------------------------------------------------------------------------------------------------      
	---- Build the cursor for unallocation of PLWB2B's      
	------------------------------------------------------------------------------------------------------------------------      
	IF @con_no > 0      
	BEGIN      

		CREATE TABLE #plw_b2b_queue_cur (
			row_id			int IDENTITY(1,1),
			tran_id			int, 
			location		varchar(10), 
			part_no			varchar(30), 
			lot				varchar(25), 
			bin_no			varchar(20), 
			qty_to_process	decimal(20,8))

		CREATE TABLE #plw_b2b_alloc_cur (
			line_row_id		int IDENTITY(1,1),
			order_no		int,
			order_ext		int,
			line_no			int,
			qty				decimal(20,8),
			target_bin		varchar(20))


		INSERT #plw_b2b_queue_cur (tran_id, location, part_no, lot, bin_no, qty_to_process) 
		SELECT tran_id, location, part_no, lot, bin_no, SUM(qty_to_process)      
		FROM #sim_tdc_pick_queue (NOLOCK)      
		WHERE trans_type_no = @con_no      
		AND trans       = 'PLWB2B'      
		GROUP BY tran_id, location, part_no, lot, bin_no      

		CREATE INDEX #plw_b2b_queue_cur_ind0 ON #plw_b2b_queue_cur(row_id)
      
		SET @last_row_id = 0

		SELECT	TOP 1 @row_id = row_id,
				@tran_id = tran_id, 
				@location = location, 
				@part_no = part_no, 
				@lot_ser = lot, 
				@bin_no = bin_no, 
				@queue_qty = qty_to_process
		FROM	#plw_b2b_queue_cur  
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC

		WHILE (@@ROWCOUNT <> 0)
		BEGIN

			DELETE #plw_b2b_alloc_cur

			IF EXISTS(SELECT line_no FROM #so_soft_alloc_byline_tbl)      
			BEGIN   
				INSERT #plw_b2b_alloc_cur (order_no, order_ext, line_no, qty, target_bin)
				SELECT a.order_no, a.order_ext, a.line_no, a.qty, a.target_bin      
				FROM #sim_tdc_soft_alloc_tbl   a (NOLOCK),      
					#so_alloc_management b,      
					#so_soft_alloc_byline_tbl c      
				WHERE a.order_no   = b.order_no      
				AND a.order_ext  = b.order_ext      
				AND a.order_type = 'S'      
				AND a.location   = b.location      
				AND a.location   = @location      
				AND a.part_no    = @part_no      
				AND a.lot_ser    = @lot_ser      
				AND a.bin_no     = @bin_no      
				AND b.sel_flg2  != 0      
				AND a.line_no = c.line_no      
				AND a.part_no = c.part_no      
			END      
			ELSE      
			BEGIN      
				INSERT #plw_b2b_alloc_cur (order_no, order_ext, line_no, qty, target_bin)
				SELECT a.order_no, a.order_ext, a.line_no, a.qty, a.target_bin      
				  FROM #sim_tdc_soft_alloc_tbl   a (NOLOCK),      
					   #so_alloc_management b      
				 WHERE a.order_no   = b.order_no      
				   AND a.order_ext  = b.order_ext      
				   AND a.order_type = 'S'      
				   AND a.location   = b.location      
				   AND a.location   = @location      
				   AND a.part_no    = @part_no      
				   AND a.lot_ser    = @lot_ser      
				   AND a.bin_no     = @bin_no      
				   AND b.sel_flg2  != 0      
			END   

			SET @last_line_row_id = 0

			SELECT	TOP 1 @line_row_id = line_row_id,
					@order_no = order_no, 
					@order_ext = order_ext, 
					@line_no = line_no, 
					@alloc_qty = qty, 
					@target_bin = target_bin
			FROM	#plw_b2b_alloc_cur
			WHERE	line_row_id > @last_line_row_id
			ORDER BY line_row_id ASC

			WHILE ((@@ROWCOUNT <> 0) AND @queue_qty > 0)
			BEGIN
      
				IF @queue_qty > @alloc_qty      
				BEGIN      
					IF EXISTS(SELECT line_no FROM #so_soft_alloc_byline_tbl)      
					BEGIN      
						DELETE FROM #sim_tdc_soft_alloc_tbl      
						FROM #sim_tdc_soft_alloc_tbl a, #so_soft_alloc_byline_tbl b      
						WHERE a.order_no   = @order_no      
						AND a.order_ext  = @order_ext      
						AND a.order_type = 'S'      
						AND a.location   = @location      
						AND a.line_no    = @line_no      
						AND a.part_no    = @part_no      
						AND a.lot_ser    = @lot_ser      
						AND a.bin_no     = @bin_no      
						AND a.target_bin = @target_bin       
						AND a.line_no    = b.line_no      
						AND a.part_no    = b.part_no      
					END      
					ELSE      
					BEGIN      
						DELETE FROM #sim_tdc_soft_alloc_tbl      
						WHERE order_no   = @order_no      
						AND order_ext  = @order_ext      
						AND order_type = 'S'      
						AND location   = @location      
						AND line_no    = @line_no      
						AND part_no    = @part_no      
						AND lot_ser    = @lot_ser      
						AND bin_no     = @bin_no      
						AND target_bin = @target_bin       
					END      
					UPDATE #sim_tdc_pick_queue      
					SET qty_to_process = qty_to_process - @alloc_qty      
					WHERE tran_id = @tran_id      
      
					SELECT @queue_qty = @queue_qty - @alloc_qty      
				END      
				ELSE IF @queue_qty < @alloc_qty      
				BEGIN      
					IF EXISTS(SELECT line_no FROM #so_soft_alloc_byline_tbl)      
					BEGIN      
						INSERT	#deleted
						SELECT	a.*
						FROM #sim_tdc_soft_alloc_tbl a, #so_soft_alloc_byline_tbl b      
						WHERE a.order_no   = @order_no      
						AND a.order_ext  = @order_ext      
						AND a.order_type = 'S'      
						AND a.location   = @location      
						AND a.line_no    = @line_no      
						AND a.part_no    = @part_no      
						AND a.lot_ser    = @lot_ser      
						AND a.bin_no     = @bin_no      
						AND a.target_bin = @target_bin       
						AND a.line_no    = b.line_no      
						AND a.part_no    = b.part_no

						INSERT	#inserted
						SELECT	a.*
						FROM #sim_tdc_soft_alloc_tbl a, #so_soft_alloc_byline_tbl b      
						WHERE a.order_no   = @order_no      
						AND a.order_ext  = @order_ext      
						AND a.order_type = 'S'      
						AND a.location   = @location      
						AND a.line_no    = @line_no      
						AND a.part_no    = @part_no      
						AND a.lot_ser    = @lot_ser      
						AND a.bin_no     = @bin_no      
						AND a.target_bin = @target_bin       
						AND a.line_no    = b.line_no      
						AND a.part_no    = b.part_no

						UPDATE #inserted      
						SET qty        = qty - @queue_qty,      
						trg_off    = 1      
						FROM #inserted a, #so_soft_alloc_byline_tbl b      
						WHERE a.order_no   = @order_no      
						AND a.order_ext  = @order_ext      
						AND a.order_type = 'S'      
						AND a.location   = @location      
						AND a.line_no    = @line_no      
						AND a.part_no    = @part_no      
						AND a.lot_ser    = @lot_ser      
						AND a.bin_no     = @bin_no      
						AND a.target_bin = @target_bin       
						AND a.line_no    = b.line_no      
						AND a.part_no    = b.part_no 

						UPDATE #sim_tdc_soft_alloc_tbl      
						SET qty        = qty - @queue_qty,      
						trg_off    = 1      
						FROM #sim_tdc_soft_alloc_tbl a, #so_soft_alloc_byline_tbl b      
						WHERE a.order_no   = @order_no      
						AND a.order_ext  = @order_ext      
						AND a.order_type = 'S'      
						AND a.location   = @location      
						AND a.line_no    = @line_no      
						AND a.part_no    = @part_no      
						AND a.lot_ser    = @lot_ser      
						AND a.bin_no     = @bin_no      
						AND a.target_bin = @target_bin       
						AND a.line_no    = b.line_no      
						AND a.part_no    = b.part_no     

						EXEC dbo.cvo_sim_tdc_soft_alloc_tbl_trg_sp 'UPDATE','','qty'
						TRUNCATE TABLE #inserted			
						TRUNCATE TABLE #deleted	 

						INSERT	#deleted
						SELECT	a.*
						FROM #sim_tdc_soft_alloc_tbl a, #so_soft_alloc_byline_tbl b       
						WHERE a.order_no   = @order_no      
						AND a.order_ext  = @order_ext      
						AND a.order_type = 'S'      
						AND a.location   = @location      
						AND a.line_no    = @line_no      
						AND a.part_no    = @part_no      
						AND a.lot_ser    = @lot_ser      
						AND a.bin_no     = @bin_no      
						AND a.target_bin = @target_bin       
						AND a.line_no    = b.line_no      
						AND a.part_no    = b.part_no

						INSERT	#inserted
						SELECT	a.*
						FROM #sim_tdc_soft_alloc_tbl a, #so_soft_alloc_byline_tbl b       
						WHERE a.order_no   = @order_no      
						AND a.order_ext  = @order_ext      
						AND a.order_type = 'S'      
						AND a.location   = @location      
						AND a.line_no    = @line_no      
						AND a.part_no    = @part_no      
						AND a.lot_ser    = @lot_ser      
						AND a.bin_no     = @bin_no      
						AND a.target_bin = @target_bin       
						AND a.line_no    = b.line_no      
						AND a.part_no    = b.part_no

						UPDATE #inserted      
						SET trg_off    = NULL      
						FROM #inserted a, #so_soft_alloc_byline_tbl b       
						WHERE a.order_no   = @order_no      
						AND a.order_ext  = @order_ext      
						AND a.order_type = 'S'      
						AND a.location   = @location      
						AND a.line_no    = @line_no      
						AND a.part_no    = @part_no      
						AND a.lot_ser    = @lot_ser      
						AND a.bin_no     = @bin_no      
						AND a.target_bin = @target_bin       
						AND a.line_no    = b.line_no      
						AND a.part_no    = b.part_no 
           
						UPDATE #sim_tdc_soft_alloc_tbl      
						SET trg_off    = NULL      
						FROM #sim_tdc_soft_alloc_tbl a, #so_soft_alloc_byline_tbl b       
						WHERE a.order_no   = @order_no      
						AND a.order_ext  = @order_ext      
						AND a.order_type = 'S'      
						AND a.location   = @location      
						AND a.line_no    = @line_no      
						AND a.part_no    = @part_no      
						AND a.lot_ser    = @lot_ser      
						AND a.bin_no     = @bin_no      
						AND a.target_bin = @target_bin       
						AND a.line_no    = b.line_no      
						AND a.part_no    = b.part_no   

						EXEC dbo.cvo_sim_tdc_soft_alloc_tbl_trg_sp 'UPDATE','',''
						TRUNCATE TABLE #inserted			
						TRUNCATE TABLE #deleted	   
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
						AND target_bin = @target_bin

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
						AND target_bin = @target_bin

						UPDATE #inserted      
						SET qty        = qty - @queue_qty,      
						trg_off    = 1      
						WHERE order_no   = @order_no      
						AND order_ext  = @order_ext      
						AND order_type = 'S'      
						AND location   = @location      
						AND line_no    = @line_no      
						AND part_no    = @part_no      
						AND lot_ser    = @lot_ser      
						AND bin_no     = @bin_no      
						AND target_bin = @target_bin 					
  
						UPDATE #sim_tdc_soft_alloc_tbl      
						SET qty        = qty - @queue_qty,      
						trg_off    = 1      
						WHERE order_no   = @order_no      
						AND order_ext  = @order_ext      
						AND order_type = 'S'      
						AND location   = @location      
						AND line_no    = @line_no      
						AND part_no    = @part_no      
						AND lot_ser    = @lot_ser      
						AND bin_no     = @bin_no      
						AND target_bin = @target_bin    

						EXEC dbo.cvo_sim_tdc_soft_alloc_tbl_trg_sp 'UPDATE','','qty'
						TRUNCATE TABLE #inserted			
						TRUNCATE TABLE #deleted	   

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
						AND target_bin = @target_bin

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
						AND target_bin = @target_bin

						UPDATE #inserted      
						SET trg_off    = NULL      
						WHERE order_no   = @order_no      
						AND order_ext  = @order_ext      
						AND order_type = 'S'      
						AND location   = @location      
						AND line_no    = @line_no      
						AND part_no    = @part_no      
						AND lot_ser    = @lot_ser      
						AND bin_no     = @bin_no      
						AND target_bin = @target_bin
      
						UPDATE #sim_tdc_soft_alloc_tbl      
						SET trg_off    = NULL      
						WHERE order_no   = @order_no      
						AND order_ext  = @order_ext      
						AND order_type = 'S'      
						AND location   = @location      
						AND line_no    = @line_no      
						AND part_no    = @part_no      
						AND lot_ser    = @lot_ser      
						AND bin_no     = @bin_no      
						AND target_bin = @target_bin    

						EXEC dbo.cvo_sim_tdc_soft_alloc_tbl_trg_sp 'UPDATE','',''
						TRUNCATE TABLE #inserted			
						TRUNCATE TABLE #deleted	   
					END      
      
					DELETE FROM #sim_tdc_pick_queue       
					WHERE tran_id = @tran_id      
      
					SELECT @queue_qty = 0      
				END      
				ELSE IF @queue_qty = @alloc_qty       
				BEGIN      
					IF EXISTS(SELECT line_no FROM #so_soft_alloc_byline_tbl)      
					BEGIN      
						DELETE FROM #sim_tdc_soft_alloc_tbl      
						FROM tdc_soft_alloc_tbl a , #so_soft_alloc_byline_tbl b      
						WHERE a.order_no   = @order_no      
						AND a.order_ext  = @order_ext      
						AND a.order_type = 'S'      
						AND a.location   = @location      
						AND a.line_no    = @line_no      
						AND a.part_no    = @part_no      
						AND a.lot_ser    = @lot_ser      
						AND a.bin_no     = @bin_no      
						AND a.target_bin = @target_bin       
						AND a.line_no    = b.line_no      
						AND a.part_no    = b.part_no      
					END      
					ELSE      
					BEGIN      
						DELETE FROM #sim_tdc_soft_alloc_tbl      
						WHERE order_no   = @order_no      
						AND order_ext  = @order_ext      
						AND order_type = 'S'      
						AND location   = @location      
						AND line_no    = @line_no      
						AND part_no    = @part_no      
						AND lot_ser    = @lot_ser      
						AND bin_no     = @bin_no      
						AND target_bin = @target_bin       
					END      
					DELETE FROM #sim_tdc_pick_queue       
					WHERE tran_id = @tran_id      
      
					SELECT @queue_qty = 0      
				END       
      
				SET @last_line_row_id = @line_row_id

				SELECT	TOP 1 @line_row_id = line_row_id,
						@order_no = order_no, 
						@order_ext = order_ext, 
						@line_no = line_no, 
						@alloc_qty = qty, 
						@target_bin = target_bin
				FROM	#plw_b2b_alloc_cur
				WHERE	line_row_id > @last_line_row_id
				ORDER BY line_row_id ASC
			END      
     
			SET @last_row_id = @row_id

			SELECT	TOP 1 @row_id = row_id,
					@tran_id = tran_id, 
					@location = location, 
					@part_no = part_no, 
					@lot_ser = lot, 
					@bin_no = bin_no, 
					@queue_qty = qty_to_process
			FROM	#plw_b2b_queue_cur  
			WHERE	row_id > @last_row_id
			ORDER BY row_id ASC
		END      
      
		DROP TABLE #plw_b2b_queue_cur
		DROP TABLE #plw_b2b_alloc_cur

	END      
      
	DECLARE	@sa_count	int, 
			@new_soft_alloc_no int,
			@id			int,
			@last_id	int

	CREATE TABLE #tmp_alloc (
			line_no		int,
			qty			decimal(20,8))

	CREATE TABLE #tmp_orders_to_process (
			id			int IDENTITY(1,1),
			order_no	int,
			order_ext	int,
			location	varchar(10))

	DELETE	a
	FROM	#sim_tdc_pick_queue a
	JOIN	cvo_masterpack_consolidation_picks b (NOLOCK)
	ON		a.tran_id = b.parent_tran_id
	JOIN	#so_alloc_management c
	ON		c.mp_consolidation_no = b.consolidation_no
	WHERE	c.sel_flg2 != 0      

	IF OBJECT_ID('tempdb..#consolidate_picks') IS NOT NULL
		DROP TABLE #consolidate_picks

	CREATE TABLE #consolidate_picks(  
		consolidation_no	int,  
		order_no			int,  
		ext					int) 

	INSERT	#tmp_orders_to_process (order_no, order_ext, location)
	SELECT	order_no, order_ext, location
	FROM	#so_alloc_management
	WHERE	sel_flg2 != 0      
	ORDER BY order_no, order_ext

	SET @last_id = 0

	SELECT	TOP 1 @id = id,
			@order_no = order_no,
			@order_ext = order_ext,
			@location = location
	FROM	#tmp_orders_to_process
	WHERE	id > @last_id
	ORDER BY id ASC

	WHILE @@ROWCOUNT <> 0
	BEGIN

		SET @cur_status = 0

		IF EXISTS (SELECT 1 FROM #sim_cvo_soft_alloc_hdr (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND status = -3)
			SET @cur_status = -3

		TRUNCATE TABLE #tmp_alloc

		INSERT	#tmp_alloc
		SELECT	line_no, SUM(qty)
		FROM	#sim_tdc_soft_alloc_tbl (NOLOCK)
		WHERE	order_no = @order_no
		AND		order_ext= @order_ext
		GROUP BY line_no

		UPDATE	#sim_cvo_soft_alloc_hdr
		SET		status = -2
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext	

		UPDATE	#sim_cvo_soft_alloc_det
		SET		status = -2
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext	

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

		IF (@new_soft_alloc_no IS NULL)
		BEGIN
			UPDATE	dbo.cvo_soft_alloc_next_no
			SET		next_no = next_no + 1

			SELECT	@new_soft_alloc_no = next_no
			FROM	dbo.cvo_soft_alloc_next_no
		END

		-- Insert cvo_soft_alloc header
		INSERT INTO #sim_cvo_soft_alloc_hdr (soft_alloc_no, order_no, order_ext, location, bo_hold, status)
		VALUES (@new_soft_alloc_no, @order_no, @order_ext, @location, 0, @cur_status) 

		-- Insert cvo_soft_alloc detail
		IF EXISTS(SELECT line_no FROM #so_soft_alloc_byline_tbl)  -- Only selected lines
		BEGIN

			INSERT INTO	#sim_cvo_soft_alloc_det (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
										kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status, add_case_flag) 
			SELECT	@new_soft_alloc_no, @order_no, @order_ext, a.line_no, a.location, a.part_no, (((a.ordered - a.shipped) + ISNULL(c.qty_override,0)) - ISNULL(d.qty,0)), 
					0, 0, 0, b.is_case, b.is_pattern, b.is_pop_gif, @cur_status, b.add_case 
			FROM	ord_list a (NOLOCK)
			JOIN	cvo_ord_list b (NOLOCK)
			ON		a.order_no = b.order_no
			AND		a.order_ext = b.order_ext
			AND		a.line_no = b.line_no
			LEFT JOIN	#so_soft_alloc_byline_tbl c
			ON		a.order_no = c.order_no
			AND		a.order_ext = c.order_ext
			AND		a.line_no = c.line_no
			LEFT JOIN
					#tmp_alloc d (NOLOCK)
			ON		a.line_no = d.line_no
			WHERE	a.order_no = @order_no
			AND		a.order_ext = @order_ext
			AND		(((a.ordered - a.shipped) + ISNULL(c.qty_override,0)) - ISNULL(d.qty,0)) > 0

		END
		ELSE
		BEGIN
			INSERT INTO	#sim_cvo_soft_alloc_det (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
										kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status, add_case_flag)
			SELECT	@new_soft_alloc_no, @order_no, @order_ext, a.line_no, a.location, a.part_no, ((a.ordered - a.shipped) - ISNULL(d.qty,0)),
					0, 0, 0, b.is_case, b.is_pattern, b.is_pop_gif, @cur_status, b.add_case 
			FROM	ord_list a (NOLOCK)
			JOIN	cvo_ord_list b (NOLOCK)
			ON		a.order_no = b.order_no
			AND		a.order_ext = b.order_ext
			AND		a.line_no = b.line_no
			LEFT JOIN
					#tmp_alloc d (NOLOCK)
			ON		a.line_no = d.line_no
			WHERE	a.order_no = @order_no
			AND		a.order_ext = @order_ext
			AND		((a.ordered - a.shipped) - ISNULL(d.qty,0)) > 0 

		END
			
		-- Insert cvo_soft_alloc for any kit items
		IF EXISTS(SELECT line_no FROM #so_soft_alloc_byline_tbl)  -- Only selected lines
		BEGIN
			INSERT INTO	#sim_cvo_soft_alloc_det (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
										kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status)			
			SELECT	@new_soft_alloc_no, @order_no, @order_ext, a.line_no, a.location, b.part_no, (((a.ordered - a.shipped) + ISNULL(c.qty_override,0)) - ISNULL(d.qty,0)), -- v2.8
					1, 0, 0, 0, 0, 0, @cur_status -- v1.9
			FROM	ord_list a (NOLOCK)
			JOIN	cvo_ord_list_kit b (NOLOCK)
			ON		a.order_no = b.order_no
			AND		a.order_ext = b.order_ext
			AND		a.line_no = b.line_no
			LEFT JOIN	#so_soft_alloc_byline_tbl c
			ON		a.order_no = c.order_no
			AND		a.order_ext = c.order_ext
			AND		a.line_no = c.line_no
			LEFT JOIN
					#tmp_alloc d (NOLOCK)
			ON		a.line_no = d.line_no
			WHERE	a.order_no = @order_no
			AND		a.order_ext = @order_ext	
			AND		b.replaced = 'S'		
			AND		(((a.ordered - a.shipped) + ISNULL(c.qty_override,0)) - ISNULL(d.qty,0)) > 0 -- v2.8
		END
		ELSE
		BEGIN
			INSERT INTO	#sim_cvo_soft_alloc_det (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
										kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status)			
			SELECT	@new_soft_alloc_no, @order_no, @order_ext, a.line_no, a.location, b.part_no, ((a.ordered - a.shipped) - ISNULL(d.qty,0)), -- v2.8
					1, 0, 0, 0, 0, 0, @cur_status -- v1.9
			FROM	ord_list a (NOLOCK)
			JOIN	cvo_ord_list_kit b (NOLOCK)
			ON		a.order_no = b.order_no
			AND		a.order_ext = b.order_ext
			AND		a.line_no = b.line_no
			LEFT JOIN
					#tmp_alloc d (NOLOCK)
			ON		a.line_no = d.line_no
			WHERE	a.order_no = @order_no
			AND		a.order_ext = @order_ext	
			AND		b.replaced = 'S'	
			AND		((a.ordered - a.shipped) - ISNULL(d.qty,0)) > 0
		END

		SET @last_id = @id

		SELECT	TOP 1 @id = id,
				@order_no = order_no,
				@order_ext = order_ext,
				@location = location	
		FROM	#tmp_orders_to_process
		WHERE	id > @last_id
		ORDER BY id ASC	
	END

	DROP TABLE #tmp_orders_to_process
	DROP TABLE #tmp_alloc

	RETURN 
END
GO
GRANT EXECUTE ON  [dbo].[sim_tdc_plw_so_unallocate_sp] TO [public]
GO
