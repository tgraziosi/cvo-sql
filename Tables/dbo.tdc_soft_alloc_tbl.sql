CREATE TABLE [dbo].[tdc_soft_alloc_tbl]
(
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[line_no] [int] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty] [decimal] (20, 8) NOT NULL,
[target_bin] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dest_bin] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trg_off] [bit] NULL CONSTRAINT [DF__tdc_soft___trg_o__080EA119] DEFAULT ((0)),
[order_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[assigned_user] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[q_priority] [int] NULL,
[alloc_type] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__tdc_soft___alloc__644D3634] DEFAULT ('PT'),
[pkg_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_hold] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__tdc_soft___user___65415A6D] DEFAULT ('N')
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[tdc_del_softalloc_tg] ON [dbo].[tdc_soft_alloc_tbl]
FOR DELETE 
AS
BEGIN
	INSERT INTO tdc_soft_alloc_tbl_arch(order_no, order_ext, location, line_no, part_no, 
		lot_ser, bin_no, qty, target_bin, dest_bin ) 
		SELECT order_no, order_ext, location, line_no, part_no, lot_ser, bin_no, qty, target_bin, dest_bin 
		FROM deleted
END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- v1.1 CB 20/04/2015 - Performance Changes
CREATE TRIGGER [dbo].[tdc_ins_softalloc_tg] ON [dbo].[tdc_soft_alloc_tbl]  
FOR INSERT 
AS     
BEGIN  
  
	DECLARE @con_no  int,  
			@tran_id  int,   
			@seq_no  int,  
			@trans   varchar(10),   
			@order_no  int,   
			@order_ext  int,   
			@priority int,  
			@order_type  char(1),   
			@location  varchar(10),  
			@part_no  varchar(30),  
			@line_no  int,  
			@qty   decimal(20,8),  
			@lot_ser  varchar(25),   
			@bin_no  varchar(12),   
			@target_bin  varchar(12),   
			@dest_bin  varchar(12),   
			@assigned_user  varchar(50),   
			@assigned_group varchar(50),   
			@alloc_type  varchar(2),  
			@tx_lock char(1),  
			@user_hold char(1),  
			@status  char(1), --SCR#38203  
			@bin_to_bin_group varchar(25)  

	-- v1.1 Start 
	CREATE TABLE #inserted_cursor (
		row_id			int IDENTITY(1,1),
		order_no		int NULL,
		order_ext		int NULL,
		location		varchar(10) NULL,
		part_no			varchar(30) NULL,
		line_no			int,
		lot_ser			varchar(25) NULL,
		bin_no			varchar(12),
		qty				decimal(20,8) NULL,
		target_bin		varchar(12) NULL,
		dest_bin		varchar(12) NULL,
		alloc_type		char(2) NULL,
		tx_lock			char(1) NULL,
		order_type		char(1) NULL,
		trans			varchar(10) NULL,
		assigned_user	varchar(50) NULL,
		user_hold		char(1) NULL,
		q_priority		int NULL)

	DECLARE	@row_id			int,
			@last_row_id	int
	
	INSERT	#inserted_cursor (order_no, order_ext, location, part_no, line_no, lot_ser, bin_no, qty, target_bin, dest_bin, alloc_type, 
							tx_lock, order_type, trans, assigned_user, user_hold, q_priority)
	-- v1.1 DECLARE inserted_cursor CURSOR FOR  
	SELECT	order_no, order_ext, location, part_no, line_no, lot_ser, bin_no, qty, target_bin, dest_bin, alloc_type,   
			tx_lock =  CASE  WHEN alloc_type = 'HO' THEN 'H'  
                WHEN alloc_type = 'PT' THEN 'R'  
				WHEN alloc_type = 'PR' then 'P'  
			    WHEN alloc_type = 'PP' then '3'  
				WHEN alloc_type = 'PB' then 'G'  
				ELSE 'R' END,  
			order_type,  
			CASE order_type WHEN 'S' THEN 'STDPICK'   
				WHEN 'T' THEN 'XFERPICK'   
				WHEN 'W' THEN 'WOPPICK' END,  
			assigned_user,  
			user_hold,  
			q_priority  
	FROM	inserted  
	WHERE	bin_no != 'CDOCK' OR ISNULL(bin_no, '') = ''  
  
	-- v1.1 OPEN inserted_cursor  
	-- v1.1 FETCH NEXT FROM inserted_cursor INTO @order_no, @order_ext, @location, @part_no, @line_no, @lot_ser, @bin_no, @qty, @target_bin,   
    -- v1.1     @dest_bin, @alloc_type, @tx_lock, @order_type, @trans, @assigned_user, @user_hold, @priority  
	-- v1.1WHILE (@@FETCH_STATUS = 0)  

	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@order_no = order_no,   
			@order_ext = order_ext, 
			@location = location,   
			@part_no = part_no, 
			@line_no = line_no,    
			@lot_ser = lot_ser, 
			@bin_no = bin_no,        
			@qty = qty,   
			@target_bin = target_bin, 
			@dest_bin = dest_bin,  
			@alloc_type = alloc_type, 
			@tx_lock = tx_lock, 
			@order_type = order_type, 
			@trans = trans,   
			@assigned_user = assigned_user, 
			@user_hold = user_hold, 
			@priority = q_priority
	FROM	#inserted_cursor
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

	WHILE (@@ROWCOUNT <> 0)
	-- v1.1 End
	BEGIN  
		-- if @order_no = 0 then trans_type should be 'MGTB2B', so, pick queue table should be populated from stored procedure tdc_adhoc_bin_replenish_sp  
		IF @order_no = 0  
		BEGIN  
			SET @last_row_id = @row_id

			SELECT	TOP 1 @row_id = row_id,
					@order_no = order_no,   
					@order_ext = order_ext, 
					@location = location,   
					@part_no = part_no, 
					@line_no = line_no,    
					@lot_ser = lot_ser, 
					@bin_no = bin_no,        
					@qty = qty,   
					@target_bin = target_bin, 
					@dest_bin = dest_bin,  
					@alloc_type = alloc_type, 
					@tx_lock = tx_lock, 
					@order_type = order_type, 
					@trans = trans,   
					@assigned_user = assigned_user, 
					@user_hold = user_hold, 
					@priority = q_priority
			FROM	#inserted_cursor
			WHERE	row_id > @last_row_id
			ORDER BY row_id ASC

			-- v1.1 FETCH NEXT FROM inserted_cursor   
			-- v1.1 INTO @order_no,   @order_ext, @location,   @part_no, @line_no,    @lot_ser, @bin_no,        @qty,   
			-- v1.1		@target_bin, @dest_bin,  @alloc_type, @tx_lock, @order_type, @trans,   @assigned_user, @user_hold, @priority  
			CONTINUE  
		END  
     
		--------------------------------------------------------------  
		-- Change the trans for package builder  
		--------------------------------------------------------------  
		If @alloc_type = 'PB' SET @trans = 'PKGBLD'  
  
		--------------------------------------------------------------  
		-- If user hold, store the alloc_type, but change the tx_lock  
		--------------------------------------------------------------  
		If @user_hold = 'Y' SET @tx_lock = 'H'    
			--SCR#38203 Modified By Jim On 10/11/07 
  
		SELECT @status = status FROM orders (nolock) WHERE order_no = @order_no AND ext = @order_ext  
		
		IF (@status < 'N') SET @tx_lock = 'E'  
		--BEGIN SED009 -- AutoAllocation    
		--JVM 07/09/2010 
		DECLARE @user_code VARCHAR(8)
		SELECT	@user_code = ISNULL(user_stat_code,'') 
		FROM	so_usrstat (NOLOCK) -- v1.1
		WHERE	default_flag = 1 
		AND		status_code = 'A'

		IF (@status = 'A') AND EXISTS(SELECT * 
							   FROM  orders (NOLOCK) 
							   WHERE order_no	= @order_no			AND 
							         ext		= @order_ext		AND 
							         user_code	= @user_code    	AND 
							         hold_reason IN (SELECT hold_code FROM CVO_alloc_hold_values_tbl (NOLOCK)))
		BEGIN
			SET @tx_lock = 'R'
			--'3'= 'PickPack', 'R'='Released'  --jvm 100810 
			-- depends of alloc type 'PickPack/no console', 'Console Pick'
		END
 
		--END   SED009 -- AutoAllocation    
 
		--SCR#38203 Modified By Jim On 10/11/07    
		----------------------------------------  
		-- Assign a group/user to a transaction  
		----------------------------------------  
		IF @assigned_user = '' OR @assigned_user like '%DEFAULT%' SET @assigned_user = NULL  
		SELECT @assigned_group = group_id FROM tdc_group (NOLOCK) WHERE trans_type = @trans  
   
		----------------------------------------------------------  
		--   For NON LOT/BIN tracked parts   --  
		----------------------------------------------------------  
		IF (@bin_no IS NULL AND @lot_ser IS NULL)  
		BEGIN  
			-- Generate next seq_no   
			EXEC @seq_no = tdc_queue_get_next_seq_num  'tdc_pick_queue', @priority   
  
			IF (@seq_no = 0)   
			BEGIN  
				ROLLBACK TRAN  
				RAISERROR 84692 'Error Generating Sequence Number.'  
				RETURN  
			END  
    
			INSERT INTO tdc_pick_queue (trans_source, trans, priority, seq_no, location, trans_type_no, trans_type_ext, line_no, part_no, lot, qty_to_process,   
					qty_processed, qty_short, bin_no, date_time, assign_group, assign_user_id,  tx_control, tx_lock, next_op)  
			VALUES ('PLW', @trans, @priority, @seq_no, @location, @order_no, @order_ext, @line_no, @part_no, NULL,  
				@qty, 0, 0, @target_bin, GETDATE(), @assigned_group, @assigned_user, 'M', @tx_lock, @dest_bin)  
  
			IF @@ERROR <> 0   
			BEGIN  
				ROLLBACK TRAN  
				RAISERROR 84693 'Error Inserting into the Pick Queue table.'  
				RETURN  
			END  
  
		END -- NON LOT/BIN Tracked items  
		ELSE  
		BEGIN  
			----------------------------------------------------------  
			--   For LOT/BIN tracked parts   --  
			----------------------------------------------------------  
  
			-- Check if there is a record for this order/location/part/line  
			IF ( @target_bin IS NOT NULL AND @bin_no = @target_bin )  
			BEGIN     


				-- Generate next seq_no   
				EXEC @seq_no = tdc_queue_get_next_seq_num  'tdc_pick_queue', @priority   
  
				IF (@seq_no = 0)   
				BEGIN  
					ROLLBACK TRAN  
					RAISERROR 84695 'Error Generating Sequence Number.'  
					RETURN  
				END   
  
				INSERT INTO tdc_pick_queue (trans_source, trans, priority, seq_no, location, trans_type_no, trans_type_ext, line_no, part_no, lot, qty_to_process,   
					qty_processed, qty_short, bin_no, date_time, assign_group, assign_user_id, tx_control, tx_lock, next_op)  
				VALUES ('PLW', @trans, @priority, @seq_no, @location, @order_no, @order_ext, @line_no, @part_no, @lot_ser,  
					@qty, 0, 0, @target_bin, GETDATE(), @assigned_group, @assigned_user, 'M', @tx_lock, @dest_bin)  
  
				IF @@ERROR <> 0   
				BEGIN  
					ROLLBACK TRAN  
					RAISERROR 84696 'Error Inserting into the Pick Queue table.'  
					RETURN  
				END  
  
			END  -- IF ( @target_bin IS NOT NULL AND @bin_no = @target_bin )  
			ELSE IF (@target_bin IS NOT NULL AND @bin_no <> @target_bin )  
			BEGIN  
				--Get the bin to bin groupid  
				SELECT @bin_to_bin_group = (SELECT group_id   
											FROM tdc_group (NOLOCK)   
											WHERE trans_type = 'PLWB2B')   
  
				SELECT	@con_no   = consolidation_no   
				FROM	tdc_cons_ords (NOLOCK)  
				WHERE	order_no  = @order_no  
				AND		order_ext = @order_ext   
				AND		location  = @location  
  
				--Get the next seq no  
				EXEC @seq_no = tdc_queue_get_next_seq_num 'tdc_pick_queue', @priority  
  
				IF @seq_no = 0   
				BEGIN  
					-- v1.1 CLOSE inserted_cursor  
					-- v1.1 DEALLOCATE inserted_cursor    
					ROLLBACK TRAN  
					RAISERROR 84695 'Error Invalid Sequence.'  
					RETURN  
				END  
  
				IF NOT EXISTS(SELECT * FROM tdc_pick_queue (NOLOCK) WHERE trans_type_no  = @con_no AND trans_type_ext = 0  
					AND trans_source   = 'PLW' AND trans      = 'PLWB2B' AND part_no      = @part_no AND lot      = @lot_ser  
					AND bin_no      = @bin_no AND next_op        = @target_bin)  
				BEGIN   
					--Insert the record  
					INSERT INTO tdc_pick_queue (trans_source, trans, priority, seq_no, location, trans_type_no, trans_type_ext, line_no, part_no, lot,qty_to_process,   
						qty_processed, qty_short,next_op, bin_no, date_time, assign_group, assign_user_id, tx_control, tx_lock)  
					VALUES ('PLW', 'PLWB2B', @priority, @seq_no, @location, @con_no, 0, 0,   
						@part_no, @lot_ser, @qty, 0, 0, @target_bin, @bin_no, GETDATE(), @bin_to_bin_group, NULL, 'M', @tx_lock)   
				END  
				ELSE  
				BEGIN  
					UPDATE	tdc_pick_queue    
					SET		qty_to_process = qty_to_process + @qty  
					WHERE	trans_type_no  = @con_no  
					AND		trans_type_ext = 0  
					AND		trans_source = 'PLW'  
					AND		trans = 'PLWB2B'  
					AND		part_no = @part_no  
					AND		lot = @lot_ser  
					AND		bin_no = @bin_no  
					AND		next_op = @target_bin  
				END  
  
				IF @@ERROR <> 0   
				BEGIN  
					-- v1.1 CLOSE inserted_cursor  
					-- v1.1 DEALLOCATE inserted_cursor    
   
					ROLLBACK TRAN  
					RAISERROR 84691 'Error Inserting into tdc_pick_queue table.'  
					RETURN  
				END  
			END  
		END     -- NON LOT/BIN Tracked items  

		-- v1.1 Start  
		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@order_no = order_no,   
				@order_ext = order_ext, 
				@location = location,   
				@part_no = part_no, 
				@line_no = line_no,    
				@lot_ser = lot_ser, 
				@bin_no = bin_no,        
				@qty = qty,   
				@target_bin = target_bin, 
				@dest_bin = dest_bin,  
				@alloc_type = alloc_type, 
				@tx_lock = tx_lock, 
				@order_type = order_type, 
				@trans = trans,   
				@assigned_user = assigned_user, 
				@user_hold = user_hold, 
				@priority = q_priority
		FROM	#inserted_cursor
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC

		-- v1.1 FETCH NEXT FROM inserted_cursor INTO @order_no, @order_ext, @location, @part_no, @line_no, @lot_ser, @bin_no, @qty, @target_bin,   
        -- v1.1	@dest_bin, @alloc_type, @tx_lock, @order_type, @trans, @assigned_user, @user_hold, @priority  
  
	END  
  
	-- v1.1 CLOSE    inserted_cursor  
	-- v1.1 DEALLOCATE inserted_cursor  
  
	RETURN    
END  

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 20/04/2015 - Performance Changes   
CREATE TRIGGER [dbo].[tdc_upd_softalloc_tg] ON [dbo].[tdc_soft_alloc_tbl]  
FOR UPDATE   
AS   
BEGIN  
	DECLARE	@order_no   INT,   
			@order_ext   INT,  
			@location   VARCHAR(10),  
			@part_no   VARCHAR(30),  
			@line_no   INT,   
			@priority  int,  
			@wo_seq_no  VARCHAR(20),  
			@lot    VARCHAR(25),  
			@bin_no   VARCHAR(12),   
			@tran_id          INT,           
			@pass_bin   VARCHAR(12),   
			@order_type   CHAR(1),    
			@trans    VARCHAR(10),   
			@tx_lock   CHAR(1),   
			@ConNo    INT,   
			@seq_no   INT,   
			@bin_to_bin_group  VARCHAR(25),  
			@assigned_group  varchar(50),  
			@assigned_user  varchar(50),  
			@update_q_flg   BIT,   
			@del_target_bin  VARCHAR(12),           
			@del_qty   DECIMAL(24,8),   
			@upd_target_bin  VARCHAR(12),   
			@upd_qty   DECIMAL(24,8),   
			@qty_upd_minus_del  DECIMAL(24,8),   
			@qty_to_process  DECIMAL(24,8),  
			@qty_processed  DECIMAL(24,8),  
			@user_hold  char(1),  
			@alloc_type  varchar(2)  
                 
	--If we don't update the target_bin or qty then EXIT  
	IF (NOT UPDATE(target_bin) AND NOT UPDATE(Qty))  
		RETURN   
  
	SELECT @qty_to_process = 0, @qty_processed = 0  

	-- v1.0 Start  
	DECLARE @row_id			int,
			@last_row_id	int

	CREATE TABLE #upd_soft_alloc_cur (
		row_id			int IDENTITY(1,1),
		order_no		int,
		order_ext		int,
		order_type		char(1) NULL,
		location		varchar(10) NULL,
		line_no			int,
		part_no			varchar(30) NULL,
		lot_ser			varchar(25) NULL,
		bin_no			varchar(12) NULL,
		target_bin		varchar(12) NULL,
		dest_bin		varchar(12) NULL,
		qty				decimal(20,8) NULL,
		trg_off			bit NULL,
		alloc_type		char(2) NULL,
		tx_lock			char(1) NULL,
		trans			varchar(10) NULL,
		assigned_user	varchar(50) NULL,
		user_hold		char(1) NULL,
		q_priority		int NULL)

	INSERT	#upd_soft_alloc_cur (order_no, order_ext, order_type, location, line_no, part_no, lot_ser, bin_no, target_bin, dest_bin,
							qty, trg_off, alloc_type, tx_lock, trans, assigned_user, user_hold, q_priority)
	-- v1.0 DECLARE upd_soft_alloc_cur CURSOR FOR   
	SELECT	order_no, order_ext, order_type, location,   line_no,   
			part_no,  lot_ser,   bin_no,     target_bin, dest_bin,   
			qty,      trg_off,   alloc_type,  
			TxLock = CASE WHEN alloc_type = 'HO' THEN 'H'   
				WHEN alloc_type = 'PT' THEN 'R'  
				WHEN alloc_type = 'PR' THEN 'P'   
				WHEN alloc_type = 'PP' THEN '3'  
				WHEN alloc_type = 'PB' THEN 'G'  
				ELSE 'R' END,  
			trans = CASE WHEN order_type = 'S'  THEN 'STDPICK'  
				WHEN order_type = 'T'  THEN 'XFERPICK'  
				WHEN order_type = 'W'  THEN 'WOPPICK' END,  
			assigned_user,  
			user_hold,  
			q_priority  
	FROM	inserted   
    WHERE	bin_no != 'CDOCK' OR bin_no IS NULL   
    
	-- v1.0 OPEN upd_soft_alloc_cur  
	-- v1.0 FETCH NEXT FROM upd_soft_alloc_cur   
	-- v1.0INTO @order_no,  @order_ext, @order_type,   @location,  @line_no,  @part_no, @lot,           @bin_no,    @upd_target_bin,   
    -- v1.0 @pass_bin,  @upd_qty,   @update_q_flg, @alloc_type, @tx_lock,  @trans,   @assigned_user, @user_hold, @priority  
    
	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@order_no = order_no,  
			@order_ext = order_ext, 
			@order_type = order_type,   
			@location = location,  
			@line_no = line_no,  
			@part_no = part_no, 
			@lot = lot_ser,           
			@bin_no = bin_no,    
			@upd_target_bin = target_bin,   
			@pass_bin = dest_bin,  
			@upd_qty = qty,   
			@update_q_flg = trg_off, 
			@alloc_type = alloc_type, 
			@tx_lock = tx_lock,  
			@trans = trans,   
			@assigned_user = assigned_user, 
			@user_hold = user_hold, 
			@priority = q_priority
	FROM	#upd_soft_alloc_cur
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC
  
	-- v1.0 WHILE @@FETCH_STATUS = 0  
	WHILE (@@ROWCOUNT <> 0)
	-- v1.0 End
	BEGIN  
		/*******************************************************************************************************  
		Initialize the variables  
		********************************************************************************************************/  
		SELECT @tran_id = 0  
		SELECT @seq_no = 0  
   
		--------------------------------------------------------------  
		-- Change the trans for package builder  
		--------------------------------------------------------------  
		If @alloc_type = 'PB' SET @trans = 'PKGBLD'  
  
		--------------------------------------------------------------  
		-- If user hold, store the alloc_type, but change the tx_lock  
		--------------------------------------------------------------  
		If @user_hold = 'Y' SET @tx_lock = 'H'  
  
		 ----------------------------------------  
		-- Assign a group/user to a transaction  
		----------------------------------------  
		IF @assigned_user = '' OR @assigned_user like '%DEFAULT%' SET @assigned_user = NULL  
		SELECT @assigned_group = group_id FROM tdc_group (NOLOCK) WHERE trans_type = @trans  
   
		--Get the deleted values   
		SELECT	@del_target_bin  = target_bin,    
				@del_qty  = qty      
		FROM	deleted   
		WHERE	order_no  = @order_no   
		AND		order_ext  = @order_ext   
		AND		order_type = @order_type  
		AND		location  = @location  
		AND		line_no   = @line_no   
		AND		part_no   = @part_no  
		AND ((lot_ser = @lot  AND bin_no = @bin_no)  
			OR  (lot_ser IS NULL AND bin_no IS NULL))  
      
		--Get the consolidation Number we are working with  
		SELECT @ConNo = 0  
		SELECT	@ConNo = consolidation_no   
		FROM	tdc_cons_ords(NOLOCK)  
		WHERE	order_no   = @order_no   
		AND		order_ext  = @order_ext   
		AND		location   = @location   
		AND		order_type = @order_type  
  
		-------------------------------------------------------------------------------------------------------------------  
		--Lot bin tracked part  
		-------------------------------------------------------------------------------------------------------------------  
		IF (@lot IS NOT NULL AND @bin_no IS NOT NULL)   
		BEGIN   
			/*******************************************************************************************************  
			If updating the queue with stop trigger bit on   
			In this case, update target bin and pass bin and exit.  
			********************************************************************************************************/  
			IF @update_q_flg = 1   
			BEGIN        
				--' We need to update the record on the Queue and set there target bin and PASS bin   
				--'Get the tran Id and Seq_no of the record in the queue   
				UPDATE	tdc_pick_queue   
				SET		next_op = @upd_target_bin,  
						priority = @priority,  
						assign_user_id = @assigned_user  
				WHERE	trans_type_no = @ConNo  
				AND		trans_type_ext = 0  
				AND		location = @location  
				AND		line_no = @line_no  
				AND		part_no = @part_no  
				AND		lot = @lot  
				AND		bin_no = @bin_no  
				AND		next_op = @del_target_bin         
  
				-- v1.0 CLOSE upd_soft_alloc_cur  
				-- v1.0 DEALLOCATE upd_soft_alloc_cur  
   
				IF @@ERROR <> 0   
				BEGIN    
					ROLLBACK TRAN  
					RAISERROR 84651 'Error Updating TDC_Soft_Alloc_Tbl with the Trigger Bit Off  .'  
					RETURN  
				END  
   
				RETURN  
			END -- update_q_flg = 1   
   
			/*******************************************************************************************************  
			If updating target bin but not quantity and need a bin to bin move  
			********************************************************************************************************/  
			IF (UPDATE(target_bin) AND NOT UPDATE(Qty) AND @bin_no <> @upd_target_bin)  
			BEGIN  
				IF EXISTS(SELECT * FROM tdc_pick_queue (NOLOCK) WHERE trans = 'PLWB2B' AND trans_type_no  = @ConNo   
					AND trans_type_ext = 0 AND location = @location AND part_no = @part_no AND lot = @lot   
					AND bin_no = @bin_no AND trans_source = 'PLW' AND next_op = @upd_target_bin )  		     
				BEGIN  
					SELECT	@tran_id = tran_id,  
							@seq_no = seq_no   
					FROM	tdc_pick_queue (NOLOCK)  
					WHERE	trans = 'PLWB2B'  
					AND		trans_type_no = @ConNo   
					AND		trans_type_ext = 0         
					AND		location = @location   
					AND		part_no = @part_no   
					AND		lot = @lot   
					AND		bin_no = @bin_no   
					AND		trans_source = 'PLW'   
					AND		next_op = @upd_target_bin   
  
					UPDATE	tdc_pick_queue   
					SET		next_op = @upd_target_bin,   
							qty_to_process = qty_to_process + @upd_qty,  
							tx_lock = @tx_lock,  
							priority = @priority,  
							assign_user_id = @assigned_user  
					WHERE	tran_id = @tran_id   
     
					IF @@ERROR <> 0   
					BEGIN  
						-- v1.0 CLOSE upd_soft_alloc_cur  
						-- v1.0 DEALLOCATE upd_soft_alloc_cur  
						ROLLBACK TRAN  
						RAISERROR 84691 'Error Inserting into Pick_queue table.'  
						RETURN  
					END  
	  
					DELETE FROM tdc_pick_queue  
					WHERE	tran_id = @tran_id  
					AND		qty_to_process <= 0  
	  
					IF @@ERROR <> 0   
					BEGIN  
						-- v1.0 CLOSE upd_soft_alloc_cur  
						-- v1.0 DEALLOCATE upd_soft_alloc_cur  
						ROLLBACK TRAN  
						RAISERROR 84701 'Error deleting from pick queue'  
						RETURN  
					END  
				END --Record exists  
				ELSE  
				BEGIN --Does not exist, insert the record  
	   
					--Get the bin to bin groupid  
					SELECT @bin_to_bin_group = (SELECT group_id FROM tdc_group (NOLOCK) WHERE trans_type = 'PLWB2B')   
	      
					--Get the next seq no  
					EXEC @seq_no = tdc_queue_get_next_seq_num 'tdc_pick_queue', @priority  
	   
					IF @seq_no = 0   
					BEGIN  
						-- v1.0 CLOSE upd_soft_alloc_cur  
						-- v1.0 DEALLOCATE upd_soft_alloc_cur  
						ROLLBACK TRAN  
						RAISERROR 84695 'Error Invalid Sequence.'  
						RETURN  
					END  
	  
					--Insert the record  
					INSERT INTO tdc_pick_queue (trans_source, trans, priority, seq_no, location, trans_type_no, trans_type_ext, line_no, part_no,   
						lot,qty_to_process, qty_processed, qty_short,next_op, bin_no, date_time, assign_group, tx_control, tx_lock)  
					VALUES ('PLW', 'PLWB2B', @priority, @seq_no, @location, @ConNo, 0, 0,   
						@part_no, @lot, @upd_qty, 0, 0, @upd_target_bin, @bin_no, GETDATE(), @bin_to_bin_group, 'M', @tx_lock)   
	  
					IF @@ERROR <> 0   
					BEGIN  
						-- v1.0 CLOSE upd_soft_alloc_cur  
						-- v1.0DEALLOCATE upd_soft_alloc_cur    
						ROLLBACK TRAN  
						RAISERROR 84691 'Error Inserting into tdc_pick_queue table.'  
						RETURN  
					END  
	   
				END --Record does not exist        
			END -- (UPDATE(target_bin) AND NOT UPDATE(Qty) AND @bin_no <> @upd_target_bin)  
	      
			/*******************************************************************************************************  
			If updating target bin but not quantity and not needing a bin to bin move   
			********************************************************************************************************/  
			IF (UPDATE(target_bin) AND NOT UPDATE(Qty) AND @bin_no = @upd_target_bin AND @upd_qty > 0)  
			BEGIN  
	  
				--Check to see if the record exists.    
				--If so, get the tran_id and seq_no  
				IF EXISTS(SELECT * FROM tdc_pick_queue (NOLOCK) WHERE trans   = @trans AND trans_type_no  = @order_no AND trans_type_ext = @order_ext         
						AND location = @location AND part_no  = @part_no AND lot = @lot AND bin_no  = @bin_no AND line_no  = @line_no AND trans_source  = 'PLW')   
				BEGIN  
	  
					SELECT	@tran_id  = tran_id,  
							@seq_no   = seq_no  
					FROM	tdc_pick_queue (NOLOCK)  
					WHERE	trans   = @trans   
					AND		trans_type_no  = @order_no   
					AND		trans_type_ext  = @order_ext         
					AND		location  = @location   
					AND		part_no   = @part_no   
					AND		lot   = @lot    
					AND		bin_no   = @bin_no    
					AND		line_no   = @line_no  
					AND		trans_source  = 'PLW'   
	  
					--'Update the existing transaction just add the qty's   
					UPDATE	tdc_pick_queue   
					SET		qty_to_process = qty_to_process - @del_qty + @upd_qty,  
							tx_lock       = @tx_lock,  
							priority       = @priority,  
							assign_user_id = @assigned_user  
					WHERE	tran_id        = @tran_id    
		   
					IF @@ERROR <> 0   
					BEGIN  
						-- v1.0 CLOSE upd_soft_alloc_cur  
						-- v1.0 DEALLOCATE upd_soft_alloc_cur  
						ROLLBACK TRAN  
						RAISERROR 84691 'Error Inserting into Pick_queue table.'  
						RETURN			
					END   
		  
					DELETE	FROM tdc_pick_queue  
					WHERE	tran_id = @tran_id  
					AND		qty_to_process <= 0  
		  
					IF @@ERROR <> 0   
					BEGIN  
						-- v1.0 CLOSE upd_soft_alloc_cur  
						-- v1.0 DEALLOCATE upd_soft_alloc_cur    
						ROLLBACK TRAN  
						RAISERROR 84701 'Error deleting from pick queue'  
						RETURN  
					END        
				END   
				ELSE  
				BEGIN --Record does not exist     
					--Get the seq no  
				   EXEC @seq_no = tdc_queue_get_next_seq_num 'tdc_pick_queue', @priority  
	   
					IF @seq_no = 0   
					BEGIN  
						-- v1.0 CLOSE upd_soft_alloc_cur  
						-- v1.0 DEALLOCATE upd_soft_alloc_cur    
						ROLLBACK TRAN  
						RAISERROR 84695 'Error Invalid Sequence or Trans Id or Priority .'  
						RETURN  
					END  
	    
					INSERT INTO tdc_pick_queue (trans_source, trans, priority, seq_no, location, trans_type_no, trans_type_ext, line_no,   
						part_no,lot, qty_to_process,  qty_processed, qty_short, bin_no, date_time, assign_group, assign_user_id,  
						tx_control, tx_lock, next_op )  
					VALUES ('PLW', @trans, @priority, @seq_no, @location, @order_no, @order_ext, @line_no, @part_no, @lot, @upd_qty,   
						0, 0, @upd_target_bin, GETDATE(), @assigned_group, @assigned_user, 'M', @tx_lock, @pass_bin )  
	  
					IF @@ERROR <> 0   
					BEGIN  
						-- v1.0 CLOSE upd_soft_alloc_cur  
						-- v1.0 DEALLOCATE upd_soft_alloc_cur  
						ROLLBACK TRAN  
						RAISERROR 84691 'Error Inserting into Pick_queue table.'  
						RETURN  
					END      
				END    
			END --(UPDATE(target_bin) AND NOT UPDATE(Qty) AND @bin_no = @upd_target_bin)  
	    
			/*******************************************************************************************************  
			If not updating target bin and updating quantity and not needing a bin to bin move   
			********************************************************************************************************/  
			IF (NOT UPDATE(target_bin) AND UPDATE(Qty) AND @bin_no = @upd_target_bin)  
			BEGIN  
				--Test to see if the record exists  
				--If so, get the tran_id and seq_no        
	  
				IF EXISTS(SELECT * FROM tdc_pick_queue (NOLOCK) WHERE trans = @trans AND trans_type_no = @order_no AND trans_type_ext = @order_ext AND location = @location   
					AND part_no = @part_no AND lot = @lot AND bin_no = @bin_no AND line_no = @line_no AND trans_source = 'PLW' )            
				BEGIN --Record exists  
					--Call 1751172ESC 04/20/09  
					-- If stop update queue flag is ON,   
					IF ((@update_q_flg IS NULL) OR (@update_q_flg != 1)) --SCR 38010 Jim 8/16/07 : disable tdc_upd_softalloc_tg  
					BEGIN  
						SELECT	@tran_id = tran_id,  
								@qty_to_process = qty_to_process,  
								@qty_processed  = qty_processed        
						FROM	tdc_pick_queue (NOLOCK)  
						WHERE	trans = @trans   
						AND		trans_type_no       = @order_no   
						AND		trans_type_ext      = @order_ext    
						AND		location       = @location   
						AND		part_no        = @part_no   
						AND		lot            = @lot   
						AND		bin_no         = @bin_no   
						AND		line_no        = @line_no  
						AND		trans_source   = 'PLW'   
	   
						IF (@qty_to_process > (@qty_to_process + @upd_qty - @del_qty))  
							SELECT @qty_processed = @qty_processed + @del_qty - @upd_qty  
						ELSE  
							SELECT @qty_processed = 0  
	   
						UPDATE	tdc_pick_queue   
						SET		qty_to_process = qty_to_process + ( @upd_qty - @del_qty ),  
								qty_processed  = @qty_processed,  
								tx_lock        = @tx_lock,  
								priority       = @priority,  
								assign_user_id = @assigned_user  
						WHERE	tran_id        = @tran_id   
	      
						IF @@ERROR <> 0   
						BEGIN  
							-- v1.0 CLOSE upd_soft_alloc_cur  
							-- v1.0 DEALLOCATE upd_soft_alloc_cur  
							ROLLBACK TRAN  
							RAISERROR 84701 'Error Updating Pick_queue table Qty_to_Process.'  
							RETURN  
						END  
					END  
	  
					DELETE FROM tdc_pick_queue  
					WHERE	tran_id = @tran_id  
					AND		qty_to_process <= 0  
	  
					IF @@ERROR <> 0   
					BEGIN  
						-- v1.0 CLOSE upd_soft_alloc_cur  
						-- v1.0 DEALLOCATE upd_soft_alloc_cur  
						ROLLBACK TRAN  
						RAISERROR 84701 'Error deleting from pick queue'  
						RETURN  
					END  
				END   
				ELSE  
				BEGIN --Record does not exist  
	  
					EXEC @seq_no = tdc_queue_get_next_seq_num 'tdc_pick_queue', @priority  
	   
					IF @seq_no = 0   
					BEGIN  
						-- v1.0 CLOSE upd_soft_alloc_cur  
						-- v1.0 DEALLOCATE upd_soft_alloc_cur  
						ROLLBACK TRAN  
						RAISERROR 84699 'Error Invalid Sequence or Trans Id or Priority .'  
						RETURN  
					END  
	     
					INSERT INTO tdc_pick_queue (trans_source, trans, priority, seq_no, location, trans_type_no, trans_type_ext, line_no, part_no,  
						lot, qty_to_process, qty_processed, qty_short, bin_no, date_time, assign_group, assign_user_id, tx_control, tx_lock, next_op)  
					VALUES ('PLW', @trans, @priority, @seq_no, @location, @order_no, @order_ext, @line_no, @part_no, @lot,   
						( @upd_qty - @del_qty ), 0, 0, @bin_no, GETDATE(), @assigned_group, @assigned_group, 'M', @tx_lock, @pass_bin )  
	   
					IF @@ERROR <> 0   
					BEGIN  
						-- v1.0 CLOSE upd_soft_alloc_cur  
						-- v1.0 DEALLOCATE upd_soft_alloc_cur    
						ROLLBACK TRAN  
						RAISERROR 84701 'Error Inserting into Pick_queue table.'  
						RETURN  
					END      
				END --Record does not exist        
			END   
    
			/*******************************************************************************************************  
			If not updating target bin and updating quantity and needing a bin to bin move for cons no  
			********************************************************************************************************/  
			IF (NOT UPDATE(target_bin) AND UPDATE(Qty) AND @bin_no <> @upd_target_bin AND @order_no = 0)  
			BEGIN  
				SELECT @qty_upd_minus_del = @upd_qty - @del_qty  
	     
				IF ( @qty_upd_minus_del < 0 )  
				BEGIN   
					-- v1.0 CLOSE      upd_soft_alloc_cur  
					-- v1.0 DEALLOCATE upd_soft_alloc_cur  
					--processing a MGTB2B and putting away inventory.  Exit       
					RETURN  
				END   
  
				--Test to see if the record exists  
				--If so, get the tran_id and seq_no  
				SELECT	@tran_id        = tran_id,   
						@qty_to_process = qty_to_process,   
						@qty_processed  = qty_processed  
				FROM	tdc_pick_queue (NOLOCK)  
				WHERE	trans          = 'MGTB2B'   
				AND		trans_type_no  = @order_no   
				AND		trans_type_ext = @order_ext    
				AND		location       = @location   
				AND		part_no        = @part_no   
				AND		lot            = @lot   
				AND		bin_no         = @bin_no  
				AND		next_op        = @upd_target_bin  
				AND		line_no        = @line_no  
				AND		trans_source   = 'MGT'   
  
				IF @tran_id IS NOT NULL  
				BEGIN  
					IF (@qty_to_process > (@qty_to_process + @upd_qty - @del_qty))  
						SELECT @qty_processed = @qty_processed + @del_qty - @upd_qty  
					ELSE  
						SELECT @qty_processed = 0  
  
					UPDATE	tdc_pick_queue   
					SET		qty_to_process =  qty_to_process + (@upd_qty - @del_qty),  
							qty_processed  = @qty_processed,  
							tx_lock        = @tx_lock,  
							priority       = @priority,  
							assign_user_id = @assigned_user  
					WHERE	tran_id        = @tran_id  
  
					IF @@ERROR <> 0   
					BEGIN  
						-- v1.0 CLOSE upd_soft_alloc_cur  
						-- v1.0 DEALLOCATE upd_soft_alloc_cur  
						ROLLBACK TRAN  
						RAISERROR 84701 'Error Updating Pick_queue table Qty_to_Process.'  
						RETURN  
					END  
  
					DELETE FROM tdc_pick_queue  
					WHERE	tran_id = @tran_id  
					AND		qty_to_process <= 0  
  
					IF @@ERROR <> 0   
					BEGIN  
						-- v1.0 CLOSE upd_soft_alloc_cur  
						-- v1.0 DEALLOCATE upd_soft_alloc_cur    
						ROLLBACK TRAN  
						RAISERROR 84701 'Error deleting from pick queue'  
						RETURN  
					END  
				END   
				ELSE  
				BEGIN  
					-- v1.0 CLOSE upd_soft_alloc_cur  
					-- v1.0 DEALLOCATE upd_soft_alloc_cur   
					ROLLBACK TRAN  
					RAISERROR 84741 'Error Updating Pick_queue For MGTB2B.'  
					RETURN  
				END  
			END --(NOT UPDATE(target_bin) AND UPDATE(Qty) AND @bin_no <> @upd_target_bin AND @order_no = 0)  
		END --LB Tracked  
		ELSE  
		-------------------------------------------------------------------------------------------------------------------  
		--Non lot bin tracked part  
		-------------------------------------------------------------------------------------------------------------------  
		BEGIN  
			-- If stop update queue flag is ON,   
			IF @update_q_flg = 1 RETURN  
  
			--Test to see if the record exists  
			--If so, get the tran_id and seq_no   
			IF EXISTS(SELECT * FROM tdc_pick_queue (NOLOCK) WHERE trans = @trans AND trans_type_no = @order_no AND trans_type_ext = @order_ext   
				AND location = @location AND part_no = @part_no AND tx_lock != 'H' AND line_no = @line_no AND trans_source   = 'PLW' )           
			BEGIN  
				SELECT	@tran_id = tran_id, 
						@qty_to_process = qty_to_process, 
						@qty_processed = qty_processed  
				FROM	tdc_pick_queue (NOLOCK)  
				WHERE	trans        = @trans   
				AND		trans_type_no  = @order_no   
				AND		trans_type_ext = @order_ext   
				AND		location       = @location   
				AND		part_no        = @part_no   
				AND		tx_lock       != 'H'   
				AND		line_no        = @line_no   
				AND		trans_source   = 'PLW'     
  
				IF (@qty_to_process > (@qty_to_process + @upd_qty - @del_qty))  
					SELECT @qty_processed = @qty_processed + @del_qty - @upd_qty  
				ELSE  
					SELECT @qty_processed = 0  
  
				UPDATE	tdc_pick_queue   
				SET		qty_to_process =  qty_to_process + (@upd_qty - @del_qty),  
						qty_processed  = @qty_processed,  
						tx_lock        = @tx_lock,  
						priority       = @priority,  
						assign_user_id = @assigned_user  
				WHERE	tran_id = @tran_id   
  
				IF @@ERROR <> 0   
				BEGIN  
					-- v1.0 CLOSE upd_soft_alloc_cur  
					-- v1.0 DEALLOCATE upd_soft_alloc_cur  
					ROLLBACK TRAN  
					RAISERROR 84691 'Error Updating the Pick Queue table.'  
					RETURN  
				END  
  
				DELETE FROM tdc_pick_queue  
				WHERE	tran_id = @tran_id  
				AND		qty_to_process <= 0  
  
				IF @@ERROR <> 0   
				BEGIN  
					-- v1.0 CLOSE upd_soft_alloc_cur  
					-- v1.0 DEALLOCATE upd_soft_alloc_cur  
					ROLLBACK TRAN  
					RAISERROR 84701 'Error deleting from pick queue'  
					RETURN  
				END  
			END  
			ELSE --Record does not exist  
			BEGIN  
				-- Generate next seq_no    
				EXEC @seq_no = tdc_queue_get_next_seq_num  'tdc_pick_queue', @priority   
  
				IF (@seq_no = 0)   
				BEGIN  
					-- v1.0 CLOSE upd_soft_alloc_cur  
					-- v1.0 DEALLOCATE upd_soft_alloc_cur  
					ROLLBACK TRAN  
					RAISERROR 84692 'Error Generating Sequence Number.'  
					RETURN  
				END  
     
				INSERT INTO tdc_pick_queue   
					(trans_source, trans, priority, seq_no, location, trans_type_no, trans_type_ext, line_no, part_no, lot,   
					qty_to_process, qty_processed, qty_short, bin_no, date_time, assign_group, tx_control, tx_lock, next_op)  
				VALUES ('PLW', @trans, @priority, @seq_no, @location, @order_no, @order_ext, @line_no, @part_no, NULL,  
					@upd_qty, 0, 0, @upd_target_bin, GETDATE(), @assigned_group, 'M', @tx_lock, @pass_bin )  
  
				IF @@ERROR <> 0   
				BEGIN  
					-- v1.0 CLOSE upd_soft_alloc_cur  
					-- v1.0 DEALLOCATE upd_soft_alloc_cur    
					ROLLBACK TRAN  
					RAISERROR 84693 'Error Inserting into the Pick Queue table.'  
					RETURN  
				END  
			END --record does not exist  
		END --Non lb tracked part  
  
  
		DELETE FROM tdc_soft_alloc_tbl  
		WHERE	order_no = @order_no  
		AND		order_ext = @order_ext  
		AND		order_type = @order_type  
		AND		location = @location  
		AND		line_no = @line_No  
		AND		ISNULL(lot_ser, '') = ISNULL(@lot, '')  
		AND		ISNULL(bin_no, '') = ISNULL(@bin_no, '')  
		AND		part_no = @part_no  
		AND		qty <= 0  
  
 		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@order_no = order_no,  
				@order_ext = order_ext, 
				@order_type = order_type,   
				@location = location,  
				@line_no = line_no,  
				@part_no = part_no, 
				@lot = lot_ser,           
				@bin_no = bin_no,    
				@upd_target_bin = target_bin,   
				@pass_bin = dest_bin,  
				@upd_qty = qty,   
				@update_q_flg = trg_off, 
				@alloc_type = alloc_type, 
				@tx_lock = tx_lock,  
				@trans = trans,   
				@assigned_user = assigned_user, 
				@user_hold = user_hold, 
				@priority = q_priority
		FROM	#upd_soft_alloc_cur
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC

		-- v1.0 FETCH NEXT FROM upd_soft_alloc_cur   
		-- v1.0 INTO @order_no,       @order_ext, @order_type, @location,     @line_no,   @part_no, @lot, @bin_no,   
		-- v1.0 @upd_target_bin, @pass_bin,  @upd_qty,    @update_q_flg, @alloc_type, @tx_lock,  @trans, @assigned_user, @user_hold, @priority  
  
	END  
  
	-- v1.0 CLOSE upd_soft_alloc_cur  
	-- v1.0 DEALLOCATE upd_soft_alloc_cur  
  
	RETURN  
END
GO
CREATE NONCLUSTERED INDEX [tdc_soft_alloc_indx2] ON [dbo].[tdc_soft_alloc_tbl] ([location], [part_no], [lot_ser], [bin_no], [target_bin]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_soft_alloc_indx1] ON [dbo].[tdc_soft_alloc_tbl] ([order_no], [order_ext], [order_type], [location], [line_no], [part_no], [lot_ser], [bin_no], [target_bin]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_soft_alloc_indx3] ON [dbo].[tdc_soft_alloc_tbl] ([order_no], [order_ext], [qty]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [RCM_tdc_soft_alloc_tbl] ON [dbo].[tdc_soft_alloc_tbl] ([part_no], [bin_no], [location], [lot_ser]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_soft_alloc_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_soft_alloc_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_soft_alloc_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_soft_alloc_tbl] TO [public]
GO
