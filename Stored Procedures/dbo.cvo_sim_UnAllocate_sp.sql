SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_sim_UnAllocate_sp]	@order_no	int,
										@order_ext	int,
										@force		int = 0,
										@user_id	varchar(50) = '',
										@recreate	int = 0
									
AS
BEGIN
	-- NOTE: Based on cvo_UnAllocate_sp v2.2 - All changes must be kept in sync  

	-- DECLARATIONS  
	DECLARE @con_no   int,  
			@custom_bin  varchar(12),  
			@qty_to_remove decimal(20,8),  
			@tran_id  int,  
			@last_tran_id int,  
			@part_no  varchar(30),  
			@from_bin  varchar(12),  
			@to_bin   varchar(12),  
			@line_no  int,  
			@last_line  int,
			@consolidation_no int
  
	-- If order# = 0 this is initial creation we exit  
    IF @order_no = 0  
    BEGIN  
		SELECT '0'  
        RETURN 0  
    END  
  	
	IF (SELECT COUNT(1) FROM dbo.orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext) = 0  
	BEGIN  
		SELECT '0'  
        RETURN 0  
	END  
    
	-- If the order is not on a status of 'N' New or 'V' Void then return  
	IF NOT EXISTS (SELECT 1 FROM dbo.orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext AND status IN ('N','V','A','H','B')) 
	BEGIN  
		IF EXISTS (SELECT 1 FROM dbo.orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext AND status IN ('Q','P'))  
		BEGIN  
			IF EXISTS (SELECT 1 FROM #sim_tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext)  
			BEGIN  
				SELECT '-1'  
				RETURN -1  
			END  
			IF EXISTS (SELECT 1 FROM dbo.tdc_dist_item_pick (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext)  
			BEGIN  
				SELECT '-1'  
				RETURN -1  
			END  
			IF EXISTS (SELECT 1 FROM dbo.tdc_dist_item_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND shipped > 0)  
			BEGIN  
				SELECT '-1'  
				RETURN -1  
			END  
		END  
		ELSE  
		BEGIN  
			IF NOT EXISTS (SELECT 1 FROM dbo.orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext AND status IN ('C'))  
			BEGIN  
				SELECT '-1'  
				RETURN -1  
			END  
		END  
	END  
  
	SELECT	@con_no = consolidation_no  
	FROM	#sim_tdc_cons_ords (NOLOCK)  
	WHERE	order_no = @order_no  
	AND		order_ext = @order_ext  
	AND		order_type = 'S'  
  
	IF @con_no IS NULL  
	BEGIN  
		SELECT '0'  
		RETURN 0  
	END  
  
	IF EXISTS (SELECT 1 FROM #sim_tdc_pick_queue (NOLOCK) WHERE trans_type_no = @order_no  
		AND trans_type_ext = @order_ext AND tx_lock NOT IN ('H','R','E'))  
	BEGIN  
		SELECT '-1'  
		RETURN -1  
	END  
  
	SET @last_line = 0  
  
	SELECT TOP 1 @line_no = line_no   
	FROM ord_list (NOLOCK)  
	WHERE order_no = @order_no  
	AND  order_ext = @order_ext  
	AND  line_no > @last_line  
	ORDER BY line_no ASC  
  
	WHILE @@ROWCOUNT <> 0  
	BEGIN  
  
		-- If any of the order is picked then return  
		IF EXISTS (SELECT 1 FROM dbo.tdc_dist_item_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext  
			AND line_no = @line_no AND [function] = 'S' AND shipped > 0)  
		BEGIN  
			SELECT '-1'  
			RETURN -1  
		END  
  
		SELECT @custom_bin = ISNULL(value_str,'CUSTOM') FROM tdc_config (NOLOCK) WHERE [function] = 'CVO_CUSTOM_BIN'  
  
		-- Does the line have any substitutions   
		IF EXISTS (SELECT 1 FROM #sim_tdc_pick_queue (NOLOCK) WHERE trans_type_no = @order_no   
			AND trans_type_ext = @order_ext AND line_no = @line_no  
			AND trans = 'MGTB2B')  
		BEGIN  
			SET @last_tran_id = 0  
  
			SELECT	TOP 1 @tran_id = tran_id,  
					@part_no = part_no,  
					@qty_to_remove = qty_to_process,  
					@from_bin = bin_no,  
					@to_bin = next_op  
			FROM	#sim_tdc_pick_queue (NOLOCK)  
			WHERE	trans_type_no = @order_no   
			AND		trans_type_ext = @order_ext   
			AND		line_no = @line_no  
			AND		trans = 'MGTB2B'  
  
			WHILE @@rowcount <> 0  
			BEGIN  
  
				INSERT	#deleted
				SELECT	* FROM #sim_tdc_soft_alloc_tbl
				WHERE	part_no = @part_no  
				AND		bin_no = @from_bin  
				AND		dest_bin = @to_bin  
				AND		order_no = 0

				INSERT	#inserted
				SELECT	* FROM #sim_tdc_soft_alloc_tbl
				WHERE	part_no = @part_no  
				AND		bin_no = @from_bin  
				AND		dest_bin = @to_bin  
				AND		order_no = 0

				UPDATE	#inserted  
				SET		qty = qty - @qty_to_remove  
				WHERE	part_no = @part_no  
				AND		bin_no = @from_bin  
				AND		dest_bin = @to_bin  
				AND		order_no = 0  

				UPDATE	#sim_tdc_soft_alloc_tbl  
				SET		qty = qty - @qty_to_remove  
				WHERE	part_no = @part_no  
				AND		bin_no = @from_bin  
				AND		dest_bin = @to_bin  
				AND		order_no = 0  
  
				EXEC dbo.cvo_sim_tdc_soft_alloc_tbl_trg_sp 'UPDATE','','qty'
				TRUNCATE TABLE #inserted			
				TRUNCATE TABLE #deleted	

				DELETE	#sim_tdc_pick_queue  
				WHERE	tran_id = @tran_id  
  
				SET @last_tran_id = @tran_id  
  
				SELECT	TOP 1 @tran_id = tran_id,  
						@part_no = part_no,  
						@qty_to_remove = qty_to_process  
				FROM	#sim_tdc_pick_queue (NOLOCK)  
				WHERE	trans_type_no = @order_no   
				AND		trans_type_ext = @order_ext   
				AND		line_no = @line_no  
				AND		trans = 'MGTB2B'  
  
			END  
		END  
  
		DELETE	#sim_tdc_pick_queue   
		WHERE	trans_type_no = @order_no   
		AND		trans_type_ext = @order_ext  
		AND		line_no = @line_no  
		AND		trans = 'STDPICK'  
  
		DELETE	#sim_tdc_soft_alloc_tbl  
		WHERE	order_no = @order_no   
		AND		order_ext = @order_ext  
		AND		line_no = @line_no  
		AND		order_type = 'S'  
    
		SET @last_line = @line_no  
  
		SELECT	TOP 1 @line_no = line_no   
		FROM	ord_list (NOLOCK)  
		WHERE	order_no = @order_no  
		AND		order_ext = @order_ext  
		AND		line_no > @last_line  
		ORDER BY line_no ASC  
	END  
  
	IF EXISTS (SELECT 1 FROM cvo_masterpack_consolidation_det (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext)
	BEGIN
		SELECT	@consolidation_no = consolidation_no
		FROM	cvo_masterpack_consolidation_det (NOLOCK)
		WHERE	order_no = @order_no 
		AND		order_ext = @order_ext

		-- Remove parent records
		DELETE	#sim_tdc_pick_queue 
		WHERE	tran_id IN (SELECT parent_tran_id FROM dbo.cvo_masterpack_consolidation_picks (NOLOCK) WHERE consolidation_no = @consolidation_no)

		-- Unhide child records
		UPDATE	#sim_tdc_pick_queue
		SET		assign_user_id = NULL
		WHERE	tran_id IN (SELECT child_tran_id FROM dbo.cvo_masterpack_consolidation_picks (NOLOCK) WHERE consolidation_no = @consolidation_no)
	END

 SELECT '0'  
 RETURN 0  
  
END
GO
GRANT EXECUTE ON  [dbo].[cvo_sim_UnAllocate_sp] TO [public]
GO
