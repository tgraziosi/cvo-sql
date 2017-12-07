SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
        
CREATE PROCEDURE  [dbo].[cvo_sim_sa_plw_so_unallocate_sp]	@order_no		int,
														@order_ext		int,
														@sa_line_no		int,
														@part_no		varchar(30),
														@error_messages	varchar(500) OUTPUT,
														@cons_no		int OUTPUT
AS       
BEGIN 
	-- NOTE: Based on cvo_sa_plw_so_unallocate_sp v1.3 - All changes must be kept in sync   

	-- Directive
	SET NOCOUNT ON

	-- Declarations   
	DECLARE @trans_source	VARCHAR(5),         
			@trans			VARCHAR(10),         
			@trans_type_no	INT,        
			@location		VARCHAR(10),         
			@line_no		INT,              
			@lot_ser		VARCHAR(25),            
			@bin_no			VARCHAR(12),           
			@queue_qty		DECIMAL(20,8),        
			@alloc_qty		DECIMAL(20,8),        
			@tx_lock		CHAR(2),        
			@next_op		VARCHAR(50),        
			@target_bin     VARCHAR(12),        
			@tran_id		INT,  
			@mfg_batch		varchar(25),
			@user_id		varchar(50),
			@curr_alloc_pct	decimal(20,8)
  
	SET @error_messages = ''
	SET @user_id = 'Allocation Process'

	SET @line_no = @sa_line_no

	-- Check if anything is allocated
	IF (@line_no IS NULL) -- no line passed int
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM #sim_tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND order_type = 'S')
			RETURN
	END
	ELSE
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM #sim_tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND line_no = @line_no AND order_type = 'S')
			RETURN
	END

	-- If the line_no has been passed in then we are unallocating just the line otherwise we are unallocating the entire order
	IF (@line_no IS NOT NULL) 
    BEGIN
		DECLARE unalloc_cur CURSOR FAST_FORWARD FOR        
		SELECT	p.trans_source, 
				p.trans,  
				p.trans_type_no, 
				s.order_no, 
				s.order_ext, 
				p.location, 
				s.line_no,              
				p.part_no,      
				p.lot,    
				p.bin_no,        
				p.qty_to_process, 
				s.qty,      
				p.tx_lock, 
				p.next_op        
		FROM	#sim_tdc_pick_queue p (NOLOCK)        
		JOIN	#sim_tdc_soft_alloc_tbl s (NOLOCK)        
		ON		p.trans_type_no = s.order_no
		AND		p.trans_type_ext = s.order_ext
		AND		p.location = s.location
		AND		p.line_no = s.line_no
		AND		p.part_no = s.part_no
		AND		ISNULL(p.bin_no,'') = ISNULL(s.bin_no ,'')        
		AND		ISNULL(p.lot,   '') = ISNULL(s.lot_ser ,'')        
		WHERE	p.trans IN ('STDPICK', 'SO-CDOCK', 'PKGBLD')        
		AND		s.order_type = 'S'        
		AND		p.trans_type_no = @order_no
		AND		p.trans_type_ext = @order_ext
		AND		p.line_no = @sa_line_no
		AND		p.part_no = @part_no
	END
	ELSE
	BEGIN
		DECLARE unalloc_cur CURSOR FAST_FORWARD FOR        
		SELECT	p.trans_source, 
				p.trans,  
				p.trans_type_no, 
				s.order_no, 
				s.order_ext, 
				p.location, 
				s.line_no,              
				p.part_no,      
				p.lot,    
				p.bin_no,        
				p.qty_to_process, 
				s.qty,      
				p.tx_lock, 
				p.next_op        
		FROM	#sim_tdc_pick_queue p (NOLOCK)        
		JOIN	#sim_tdc_soft_alloc_tbl s (NOLOCK)        
		ON		p.trans_type_no = s.order_no
		AND		p.trans_type_ext = s.order_ext
		AND		p.location = s.location
		AND		p.line_no = s.line_no
		AND		p.part_no = s.part_no
		AND		ISNULL(p.bin_no,'') = ISNULL(s.bin_no ,'')        
		AND		ISNULL(p.lot,   '') = ISNULL(s.lot_ser ,'')        
		WHERE	p.trans IN ('STDPICK', 'SO-CDOCK', 'PKGBLD')        
		AND		s.order_type = 'S'        
		AND		p.trans_type_no = @order_no
		AND		p.trans_type_ext = @order_ext
	END        
        
	OPEN unalloc_cur    
	FETCH NEXT FROM unalloc_cur 
	INTO @trans_source, @trans,  @trans_type_no, @order_no, @order_ext, @location, @line_no,              
		 @part_no, @lot_ser, @bin_no, @queue_qty, @alloc_qty, @tx_lock, @next_op        
	WHILE @@FETCH_STATUS = 0        
	BEGIN        
         
		SELECT	@mfg_batch = mfg_batch  
		FROM	#sim_tdc_pick_queue (NOLOCK)  
		WHERE	trans_source = @trans_source  
		AND		trans = @trans  
		AND		trans_type_no = @trans_type_no  
		AND		trans_type_ext = @order_ext  
		AND		line_no = @line_no  
  
		-- Validate if the line can be unallocated
		IF NOT (@tx_lock = 'H' AND (PATINDEX('%SHIP_COMP%',@mfg_batch) > 0))  
		BEGIN  
			IF ((@tx_lock NOT IN ('R', '3', 'P', 'V', 'L', 'G', 'E')) OR (@queue_qty < @alloc_qty))    
				OR EXISTS (SELECT * FROM tdc_bin_master (NOLOCK)        
							WHERE	location = @location        
							AND		bin_no   = @bin_no        
							AND		(usage_type_code = 'RECEIPT' OR usage_type_code = 'PRODOUT'))        
			BEGIN        
				CLOSE unalloc_cur        
				DEALLOCATE unalloc_cur
				RETURN        
			END        
		END        	
        
		-- Lot/Bin Tracked parts    
		IF (@lot_ser IS NOT NULL AND @bin_no IS NOT NULL)
		BEGIN        
			IF (@queue_qty - @alloc_qty) = 0        
			BEGIN          
				IF (@sa_line_no IS NOT NULL)
				BEGIN        
					DELETE	#sim_tdc_pick_queue        
					WHERE	trans = @trans             
					AND		trans_type_no = @order_no         
					AND		trans_type_ext = @order_ext              
					AND		location = @location             
					AND		part_no = @part_no        
					AND		lot = @lot_ser        
					AND		bin_no = @bin_no             
					AND		line_no = @line_no        
					AND     trans_source = @trans_source         
				END     
				ELSE        
				BEGIN        
					DELETE	#sim_tdc_pick_queue        
					WHERE	trans = @trans             
					AND		trans_type_no = @order_no         
					AND		trans_type_ext = @order_ext              
					AND		location = @location             
					AND		part_no = @part_no        
					AND		lot = @lot_ser        
					AND		bin_no = @bin_no             
					AND		line_no = @line_no        
					AND     trans_source   = @trans_source       
				END        
  
				-- Remove custom frame breaks  
				DELETE	#sim_tdc_pick_queue  
				WHERE	trans = 'MGTB2B'             
				AND		trans_type_no = @order_no         
				AND		trans_type_ext = @order_ext              
				AND		location = @location             
				AND		line_no = @line_no        
				AND		trans_source = 'MGT'     

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
				IF (@sa_line_no IS NOT NULL)
				BEGIN        
					UPDATE	#sim_tdc_pick_queue        
					SET		qty_to_process = (@queue_qty - @alloc_qty)        
					WHERE	trans = @trans             
					AND		trans_type_no = @order_no         
					AND		trans_type_ext = @order_ext        
					AND		location = @location         
					AND		part_no = @part_no        
					AND		lot = @lot_ser        
					AND		bin_no = @bin_no        
					AND		line_no = @line_no        
					AND		trans_Source = @trans_source         
				END        
				ELSE        
				BEGIN        
					UPDATE	#sim_tdc_pick_queue        
					SET		qty_to_process = (@queue_qty - @alloc_qty)        
					WHERE	trans = @trans             
					AND		trans_type_no = @order_no         
					AND		trans_type_ext = @order_ext        
					AND		location = @location         
					AND		part_no = @part_no        
					AND		lot = @lot_ser        
					AND		bin_no = @bin_no        
					AND		line_no = @line_no        
					AND		trans_Source = @trans_source         
				END        
  
				-- Remove custom frame breaks  
				UPDATE	#sim_tdc_pick_queue        
				SET		qty_to_process = (@queue_qty - @alloc_qty)        
				WHERE	trans = 'MGTB2B'             
				AND		trans_type_no = @order_no         
				AND		trans_type_ext = @order_ext        
				AND		location = @location         
				AND		line_no = @line_no        
				AND		trans_Source = 'MGT'           
			END --(@queue_qty - @alloc_qty) != 0          
        
			IF (@sa_line_no IS NOT NULL)
			BEGIN        
				DELETE	#sim_tdc_soft_alloc_tbl        
				WHERE	order_no  = @order_no        
				AND		order_ext = @order_ext        
				AND		order_type = 'S'        
				AND		location  = @location        
				AND		line_no   = @line_no        
				AND		part_no   = @part_no        
				AND		lot_ser = @lot_ser        
				AND		bin_no = @bin_no        
			END        
			ELSE        
			BEGIN        
				DELETE	#sim_tdc_soft_alloc_tbl           
				WHERE	order_no = @order_no        
				AND		order_ext = @order_ext        
				AND		order_type = 'S'        
				AND		location = @location        
				AND		line_no = @line_no        
				AND		part_no = @part_no        
				AND		lot_ser = @lot_ser        
				AND		bin_no = @bin_no        
			END        
		END --LOT/BIN tracked part        
		ELSE        
		BEGIN --NON LOT/BIN tracked part        
			IF (@queue_qty - @alloc_qty) = 0 --Delete from the queue        
			BEGIN            
				IF (@sa_line_no IS NOT NULL)
				BEGIN        
					DELETE	#sim_tdc_pick_queue        
					FROM	#sim_tdc_pick_queue
					WHERE	trans = @trans             
					AND		trans_type_no = @order_no         
					AND		trans_type_ext = @order_ext              
					AND		location = @location             
					AND		part_no = @part_no        
					AND		lot IS NULL        
					AND		bin_no IS NULL            
					AND		line_no = @line_no        
					AND		trans_source = @trans_source         
				END        
				ELSE        
				BEGIN        
					DELETE	#sim_tdc_pick_queue        
					FROM	#sim_tdc_pick_queue
					WHERE	trans = @trans             
					AND		trans_type_no = @order_no         
					AND		trans_type_ext = @order_ext              
					AND		location = @location             
					AND		part_no = @part_no        
					AND		lot IS NULL        
					AND		bin_no IS NULL            
					AND		line_no = @line_no        
					AND		trans_source = @trans_source             
				END                
			END --(@queue_qty - @alloc_qty) = 0        
			ELSE        
			BEGIN  --(@queue_qty - @alloc_qty) != 0        
				--Update the Qty_To_Process              
				IF (@sa_line_no IS NOT NULL)
				BEGIN        
					UPDATE	#sim_tdc_pick_queue        
					SET		qty_to_process = (@queue_qty - @alloc_qty)        
					FROM	#sim_tdc_pick_queue
					WHERE	trans = @trans             
					AND		trans_type_no = @order_no         
					AND		trans_type_ext = @order_ext        
					AND		location = @location         
					AND		part_no = @part_no        
					AND		lot IS NULL        
					AND		bin_no IS NULL       
					AND		line_no = @line_no        
					AND		trans_Source = @trans_source         
				END        
				ELSE        
				BEGIN        
					UPDATE	#sim_tdc_pick_queue        
					SET		qty_to_process = (@queue_qty - @alloc_qty)        
					FROM	#sim_tdc_pick_queue
					WHERE	trans = @trans             
					AND		trans_type_no = @order_no         
					AND		trans_type_ext = @order_ext        
					AND		location = @location         
					AND		part_no = @part_no        
					AND		lot IS NULL        
					AND		bin_no IS NULL       
					AND		line_no = @line_no        
					AND		trans_Source = @trans_source         
				END                
			END --(@queue_qty - @alloc_qty) != 0         
        
			IF (@sa_line_no IS NOT NULL)
			BEGIN        
				DELETE	#sim_tdc_soft_alloc_tbl        
				FROM	#sim_tdc_soft_alloc_tbl
				WHERE	order_no = @order_no        
				AND		order_ext = @order_ext        
				AND		order_type = 'S'        
				AND		location = @location        
				AND		line_no   = @line_no        
				AND		part_no   = @part_no        
				AND		lot_ser IS NULL        
				AND		bin_no IS NULL        
			END        
			ELSE        
			BEGIN        
				DELETE	#sim_tdc_soft_alloc_tbl        
				FROM	#sim_tdc_soft_alloc_tbl
				WHERE	order_no = @order_no        
				AND		order_ext = @order_ext        
				AND		order_type = 'S'        
				AND		location = @location        
				AND		line_no   = @line_no        
				AND		part_no   = @part_no        
				AND		lot_ser IS NULL        
				AND		bin_no IS NULL        
			END

		END --NON lb tracked        
   
		FETCH NEXT FROM unalloc_cur INTO @trans_source, @trans, @trans_type_no, @order_no, @order_ext, @location, @line_no,              
                    @part_no, @lot_ser, @bin_no, @queue_qty, @alloc_qty, @tx_lock, @next_op        
        
	END --@@FETCH_STATUS = 0        
        
	CLOSE      unalloc_cur        
	DEALLOCATE unalloc_cur        
         
	SELECT	@cons_no = consolidation_no 
	FROM	#sim_tdc_cons_ords (NOLOCK)
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext

	RETURN 
END
GO
GRANT EXECUTE ON  [dbo].[cvo_sim_sa_plw_so_unallocate_sp] TO [public]
GO
