SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_cancel_order_sp]	@order_no	int,
									@order_ext	int,
									@user_id	varchar(50),
									@customer_code	varchar(10),
									@location	varchar(10),
									@no_stock	int = 0
AS
BEGIN
	-- Directives
	SET NOCOUNT ON
	SET QUOTED_IDENTIFIER OFF
	
	-- Declarations
	DECLARE	@ret					int,
			@message				varchar(255),
			@status					char(1),
			@carton_no				int,
			@last_carton_no			int,
			@cancel_bin				varchar(12),
			@cf_cancel_bin			varchar(12),
			@custom_bin				varchar(12),
			@line_no				int,
			@last_line_no			int,
			@part_no				varchar(30),
			@lot_ser				varchar(25),
			@qty					decimal(20,8),
			@bin_no					varchar(20),
			@last_bin_no			varchar(20),
			@bin_qty				decimal(20,8),
			@cons_no				int,
			@tran_id				int,
			@last_tran_id			int,
			@new_order_no			int,
			@iret					int,
			@shipcomplete			int -- v1.8

	-- START v1.7
	DECLARE @promo_id				VARCHAR(20),  
			@promo_level			VARCHAR(30),
			@is_drawdown			SMALLINT,		
			@hdr_rec_id				INT,			
			@promo_amount			DECIMAL(20,8)
	-- END v1.7	
	
	-- Initialize
	SET	@ret = 0 -- 0 = OK status reset, 1 = OK order cancelled but prompt for note, -1 = error
	SET @message = ''
	SET @new_order_no = 0
	SET @shipcomplete = 0 -- v1.8

	-- v1.8 Start
	IF (@no_stock = 2)
	BEGIN
		SET @no_stock = 1
		SET @shipcomplete = 1
	END
	-- v1.8 
	
	SELECT	@cancel_bin = ISNULL(value_str,'') FROM tdc_config (NOLOCK) WHERE [function] = 'CANCEL_BIN' 
	SELECT	@cf_cancel_bin = ISNULL(value_str,'') FROM tdc_config (NOLOCK) WHERE [function] = 'CUSTOM_CANCEL_BIN'
	SELECT	@custom_bin = ISNULL(value_str,'') FROM tdc_config (NOLOCK) WHERE [function] = 'CVO_CUSTOM_BIN'

	-- Get the status from the order
	SELECT	@status = status
	FROM	orders_all (NOLOCK)
	WHERE	order_no = @order_no
	AND		ext = @order_ext

	IF (@status < 'P' AND @shipcomplete = 0) -- v1.5
	BEGIN
		SELECT	@ret, @message, 0 -- v1.5
		RETURN
	END

	-- Validation for cancelling an order 
	-- Check for order being masterpacked
	IF EXISTS (SELECT 1 FROM tdc_master_pack_ctn_tbl a (NOLOCK) JOIN tdc_carton_tx b (NOLOCK) ON a.carton_no = b.carton_no
				WHERE b.order_no = @order_no AND b.order_ext = @order_ext AND b.order_type = 'S')
	BEGIN
		SET @ret = -1
		SET @message = 'Order cannot be cancelled as it has been masterpacked.'
		-- v1.8 Start
		IF (@shipcomplete = 1)
		BEGIN
			RETURN @ret
		END
		ELSE
		BEGIN
			SELECT	@ret, @message, 0
			RETURN
		END
		-- v1.8 End
	END

	-- Check for order begin freighted or staged
	IF EXISTS (SELECT 1 FROM tdc_carton_tx (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND order_type = 'S' AND status NOT IN ('O','C'))
	BEGIN
		SET @ret = -1
		SET @message = 'Order cannot be cancelled as it has been freighted/staged.'
		-- v1.8 Start
		IF (@shipcomplete = 1)
		BEGIN
			RETURN @ret
		END
		ELSE
		BEGIN
			SELECT	@ret, @message, 0
			RETURN
		END
		-- v1.8 End
	END

	-- validate that the cancellation bins have been set up
	IF (@cancel_bin = '')
	BEGIN
		SET @ret = -1
		SET @message = 'Cannot cancel order. Cancellation bin is missing.'
		-- v1.8 Start
		IF (@shipcomplete = 1)
		BEGIN
			RETURN @ret
		END
		ELSE
		BEGIN
			SELECT	@ret, @message, 0
			RETURN
		END
		-- v1.8 End
	END

	IF (@cf_cancel_bin = '')
	BEGIN
		SET @ret = -1
		SET @message = 'Cannot cancel order. Custom Frame Cancellation bin is missing.'
		-- v1.8 Start
		IF (@shipcomplete = 1)
		BEGIN
			RETURN @ret
		END
		ELSE
		BEGIN
			SELECT	@ret, @message, 0
			RETURN
		END
		-- v1.8 End
	END

	-- Validate the cancel bins
	IF NOT EXISTS (SELECT 1 FROM tdc_bin_master (NOLOCK) WHERE location = @location AND bin_no = @cancel_bin AND status = 'A' AND usage_type_code = 'QUARANTINE')
	BEGIN
		SET @ret = -1
		SET @message = 'Cannot cancel order. Cancellation bin does not exist or is not set up incorrectly.'
		-- v1.8 Start
		IF (@shipcomplete = 1)
		BEGIN
			RETURN @ret
		END
		ELSE
		BEGIN
			SELECT	@ret, @message, 0
			RETURN
		END
		-- v1.8 End
	END
 
	IF NOT EXISTS (SELECT 1 FROM tdc_bin_master (NOLOCK) WHERE location = @location AND bin_no = @cf_cancel_bin AND status = 'A' AND usage_type_code = 'QUARANTINE')
	BEGIN
		SET @ret = -1
		SET @message = 'Cannot cancel order. Custom Frame cancellation bin does not exist or is not set up incorrectly.'
		-- v1.8 Start
		IF (@shipcomplete = 1)
		BEGIN
			RETURN @ret
		END
		ELSE
		BEGIN
			SELECT	@ret, @message, 0
			RETURN
		END
		-- v1.8 End
	END

	-- If the processing has reached here then we are cancelling the order
	-- Is the order packed and the carton is closed
	IF EXISTS (SELECT 1 FROM tdc_carton_tx (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND order_type = 'S' AND status = 'C')
	BEGIN
		-- Reopen all cartons 
		SET @last_carton_no = 0

		SELECT	TOP 1 @carton_no = carton_no
		FROM	tdc_carton_tx (NOLOCK)
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		AND		status = 'C'
		AND		carton_no > @last_carton_no
		ORDER BY carton_no ASC

		WHILE @@ROWCOUNT <> 0
		BEGIN

			EXEC tdc_open_carton_sp @carton_no, '999',@user_id, 1, @message OUTPUT

			IF (@@ERROR <> 0)
			BEGIN
				SET @ret = -1
				SET @message = 'Order cancellation Failed, could not reopen a closed carton.'
				-- v1.8 Start
				IF (@shipcomplete = 1)
				BEGIN
					RETURN @ret
				END
				ELSE
				BEGIN
					SELECT	@ret, @message, 0
					RETURN
				END
				-- v1.8 End
			END

			IF (@message > '')
			BEGIN
				SET @ret = -1
				-- v1.8 Start
				IF (@shipcomplete = 1)
				BEGIN
					RETURN @ret
				END
				ELSE
				BEGIN
					SELECT	@ret, @message, 0
					RETURN
				END
				-- v1.8 End
			END

			SET @last_carton_no = @carton_no

			SELECT	TOP 1 @carton_no = carton_no
			FROM	tdc_carton_tx (NOLOCK)
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
			AND		status = 'C'
			AND		carton_no > @last_carton_no
			ORDER BY carton_no ASC
		END
	END
	
	-- Need to unpack any items that have been packed
	IF EXISTS (SELECT 1 FROM tdc_carton_tx (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND order_type = 'S' AND status = 'O')
	BEGIN

		-- Run through each carton and unpack them 
		SET @last_carton_no = 0

		SELECT	TOP 1 @carton_no = carton_no
		FROM	tdc_carton_tx (NOLOCK)
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		AND		status = 'O'
		AND		carton_no > @last_carton_no
		ORDER BY carton_no ASC

		WHILE @@ROWCOUNT <> 0
		BEGIN

			-- Run through each item in the carton
			SET	@last_line_no = 0

			SELECT	TOP 1 @line_no = line_no,
					@part_no = part_no,
					@lot_ser = lot_ser,
					@qty = pack_qty
			FROM	tdc_carton_detail_tx (NOLOCK)
			WHERE	carton_no = @carton_no
			AND		order_no = @order_no
			AND		order_ext = @order_ext
			AND		line_no > @last_line_no
			ORDER BY line_no ASC

			WHILE @@ROWCOUNT <> 0
			BEGIN

				-- The item could have been packed from multiple bins
				-- Go through each bin/qty
				SET @last_bin_no = ''

				SELECT	TOP 1 @bin_no = bin_no,
						@bin_qty = qty
				FROM	lot_bin_ship (NOLOCK)
				WHERE	location = @location
				AND		tran_no = @order_no
				AND		tran_ext = @order_ext
				AND		line_no = @line_no
				AND		tran_code = 'P'
				AND		bin_no > @last_bin_no
				ORDER by bin_no ASC

				WHILE @@ROWCOUNT <> 0
				BEGIN		

					-- Call the warehouse unpack routine
					EXEC tdc_pps_unpack_sp 1, @carton_no, @user_id, '999', '', @order_no, @order_ext, '', '', @line_no, @part_no, '', @location, 
											@lot_ser, @bin_no, @bin_qty, @message OUTPUT

					IF (@@ERROR <> 0)
					BEGIN
						SET @ret = -1
						SET @message = 'Order cancellation Failed, could not unpack carton.'
						-- v1.8 Start
						IF (@shipcomplete = 1)
						BEGIN
							RETURN @ret
						END
						ELSE
						BEGIN
							SELECT	@ret, @message, 0
							RETURN
						END
						-- v1.8 End
					END

					IF (@message > '')
					BEGIN
						SET @ret = -1
						-- v1.8 Start
						IF (@shipcomplete = 1)
						BEGIN
							RETURN @ret
						END
						ELSE
						BEGIN
							SELECT	@ret, @message, 0
							RETURN
						END
						-- v1.8 End
					END

					SET @last_bin_no = @bin_no

					SELECT	TOP 1 @bin_no = bin_no,
							@bin_qty = qty
					FROM	lot_bin_ship (NOLOCK)
					WHERE	location = @location
					AND		tran_no = @order_no
					AND		tran_ext = @order_ext
					AND		line_no = @line_no
					AND		tran_code = 'P'
					AND		bin_no > @last_bin_no
					ORDER by bin_no ASC
				END

				SET	@last_line_no = @line_no

				SELECT	TOP 1 @line_no = line_no,
						@part_no = part_no,
						@lot_ser = lot_ser,
						@qty = pack_qty
				FROM	tdc_carton_detail_tx (NOLOCK)
				WHERE	carton_no = @carton_no
				AND		order_no = @order_no
				AND		order_ext = @order_ext
				AND		line_no > @last_line_no
				ORDER BY line_no ASC
			END

			SET @last_carton_no = @carton_no

			SELECT	TOP 1 @carton_no = carton_no
			FROM	tdc_carton_tx (NOLOCK)
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
			AND		status = 'O'
			AND		carton_no > @last_carton_no
			ORDER BY carton_no ASC
		END
	END


	-- Need to unpick the items from the order
	-- Create the working tables
	IF (SELECT OBJECT_ID('tempdb..#adm_bin_xfer')) IS NOT NULL 
	BEGIN   
		DROP TABLE #adm_bin_xfer  
	END

	CREATE TABLE #adm_bin_xfer (
		issue_no		int null,
		location		varchar(10) not null,
		part_no			varchar(30)	not null,
		lot_ser			varchar(25)	not null,
		bin_from		varchar(12) not null,
		bin_to			varchar(12)	not null,
		date_expires	datetime not null,
		qty				decimal(20,8) not null,
		who_entered		varchar(50)	not null,
		reason_code		varchar(10)	null,
		err_msg			varchar(255) null,
		row_id			int identity not null)

	IF (SELECT OBJECT_ID('tempdb..#adm_pick_ship')) IS NOT NULL 
	BEGIN   
		DROP TABLE #adm_pick_ship  
	END

	CREATE TABLE #adm_pick_ship (
		order_no		int not null, 
		ext				int not null, 
		line_no			int not null, 
		part_no			varchar(30) not null, 
		tracking_no		varchar(30) null, 
		bin_no			varchar(12) null, 
		lot_ser			varchar(25) null, 
		location		varchar(10)	null, 
		date_exp		datetime null, 
		qty				decimal(20,8) not null, 
		err_msg			varchar(255) null, 
		row_id			int identity not null)

	IF (SELECT OBJECT_ID('tempdb..#pick_custom_kit_order')) IS NOT NULL 
	BEGIN   
		DROP TABLE #pick_custom_kit_order  
	END

	CREATE TABLE #pick_custom_kit_order (
		method			varchar(2) not null,
		order_no		int not null,
		order_ext		int not null,
		line_no			int not null,
		location		varchar(10) not null,
		item			varchar(30) null,
		part_no			varchar(30) not null,
		sub_part_no		varchar(30) null,
		lot_ser			varchar(25) null,bin_no varchar(12) null,quantity decimal(20,8) not null,who varchar(50) not null,row_id int identity not null)	

	IF (SELECT OBJECT_ID('tempdb..#tdc_unpick_item')) IS NOT NULL 
	BEGIN   
		DROP TABLE #tdc_unpick_item  
	END

	CREATE TABLE #tdc_unpick_item (
		order_no		int not null, 
		order_ext		int not null, 
		item			varchar(30) null, 
		part_no			varchar(30) not null, 
		lot_ser			varchar(25) null, 
		to_bin			varchar(12) null, 
		location		varchar(10)	not null, 
		qty				decimal(20,8) not null, 
		who				varchar(50) not	null, 
		tote_bin		varchar(12) null, 
		line_no			int not null, 
		row_id			int identity not null)

	IF (SELECT OBJECT_ID('tempdb..#serial_no')) IS NOT NULL 
	BEGIN   
		DROP TABLE #serial_no  
	END

	CREATE TABLE #serial_no (
		serial_no		varchar(40)	not null, 
		serial_raw		varchar(40)	not null) 

	-- v1.5 Start - As this can now be called from the console do not create #temp_who if it already exists
    IF (OBJECT_ID('tempdb..#temp_who') IS NULL) 
	BEGIN

		CREATE TABLE #temp_who (
				who			varchar(50),
				login_id	varchar(50))

		INSERT #temp_who SELECT @user_id, @user_id
	END
	-- v1.5 End

	-- Run through each line on the order where the quantity has been picked
	SET @last_line_no = 0

	SELECT	TOP 1 @line_no = line_no,
			@part_no = part_no,
			@qty = shipped
	FROM	ord_list (NOLOCK)
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext
	AND		shipped > 0
	AND		line_no > @last_line_no
	ORDER BY line_no ASC

	WHILE @@ROWCOUNT <> 0
	BEGIN

		DELETE #adm_bin_xfer
		DELETE #adm_pick_ship
		DELETE #pick_custom_kit_order
		DELETE #tdc_unpick_item
		DELETE #serial_no

		-- If the line has been auto purchased then you can not cancel the order
		IF EXISTS(SELECT 1 FROM orders_auto_po (NOLOCK) WHERE order_no = @order_no AND line_no = @line_no AND part_no = @part_no AND status > 'N')
		BEGIN
			SET @ret = -1
			SET @message = 'Error cancelling order, the order contains an auto puchased item.'
			-- v1.8 Start
			IF (@shipcomplete = 1)
			BEGIN
				RETURN @ret
			END
			ELSE
			BEGIN
				SELECT	@ret, @message, 0
				RETURN
			END
			-- v1.8 End
		END

		-- If the item was part of a custom frame break then it needs to be unpicked to a different location
		-- and any remaining transaction for the custom frame break need to removed.
		IF EXISTS (SELECT 1 FROM cvo_ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND line_no = @line_no AND is_customized = 'S')
		BEGIN
			-- Unpick the custom frame into the custom frame cancel bin
			INSERT INTO #tdc_unpick_item (order_no,	order_ext, part_no,	lot_ser, to_bin, location, qty,	who, line_no)
			VALUES (@order_no, @order_ext, @part_no, '1', @cf_cancel_bin, @location, @qty,	@user_id, @line_no)
		END
		ELSE
		BEGIN	
			-- Unpick the items into the cancel bin
			INSERT INTO #tdc_unpick_item (order_no,	order_ext, part_no,	lot_ser, to_bin, location, qty,	who, line_no)
			VALUES (@order_no, @order_ext, @part_no, '1', @cancel_bin, @location, @qty,	@user_id, @line_no)
		END

	
		-- START v1.2
		/*
		-- Force the system to think its warehoue
		IF NOT EXISTS (SELECT * FROM dbo.tdc_config WHERE [function] = 'mod_ebo_inv')
				INSERT INTO tdc_config ([function],mod_owner, description, active) VALUES ('mod_ebo_inv','EBO','Allow modify inventory from eBO','Y')	
		*/
		-- END v1.2

		-- Call the warehouse unpick routine
		EXEC tdc_dist_unpick_item_sp 

		-- START v1.2
		/*
		-- Remove override
		DELETE FROM dbo.tdc_config WHERE [function] = 'mod_ebo_inv'
		*/

		IF (@@ERROR <> 0)
		BEGIN
			SET @ret = -1
			SET @message = 'Order cancellation Failed, could not unpick order.'
			-- v1.8 Start
			IF (@shipcomplete = 1)
			BEGIN
				RETURN @ret
			END
			ELSE
			BEGIN
				SELECT	@ret, @message, 0
				RETURN
			END
			-- v1.8 End
		END

		SET @last_line_no = @line_no

		SELECT	TOP 1 @line_no = line_no,
				@part_no = part_no,
				@qty = shipped
		FROM	ord_list (NOLOCK)
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		AND		shipped > 0
		AND		line_no > @last_line_no
		ORDER BY line_no ASC
	END


-- v1.6	IF (@status IN ('P','Q'))
	IF ((@status = 'P') OR (@status = 'Q' AND @no_stock = 1) OR @shipcomplete = 1) -- v1.6 v1.8
	BEGIN
		-- Unallocate any lines that are allocated 
		SET @last_line_no = 0

		SELECT	TOP 1 @line_no = line_no,
				@part_no = part_no
		FROM	tdc_soft_alloc_tbl (NOLOCK)
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		AND		order_type = 'S'
		AND		line_no > @last_line_no
		ORDER BY line_no ASC

		WHILE @@ROWCOUNT <> 0
		BEGIN

			-- Record any queue transactions that will be removed
			INSERT	cvo_order_queue_cancellation (order_no, order_ext, tran_id)
			SELECT	trans_type_no, trans_type_ext,tran_id
			FROM	tdc_pick_queue (NOLOCK)
			WHERE	trans_type_no = @order_no
			AND		trans_type_ext = @order_ext

			-- Call the unallocate line routine
			EXEC dbo.cvo_sa_plw_so_unallocate_sp @order_no, @order_ext, @line_no, @part_no, @message OUTPUT, @cons_no OUTPUT

			IF (@@ERROR <> 0)
			BEGIN
				SET @ret = -1
				SET @message = 'Order cancellation Failed, could not unallocate order.'
				-- v1.8 Start
				IF (@shipcomplete = 1)
				BEGIN
					RETURN @ret
				END
				ELSE
				BEGIN
					SELECT	@ret, @message, 0
					RETURN
				END
				-- v1.8 End
			END

			IF (@message <> '')
			BEGIN
				SET @ret = -1
				-- v1.8 Start
				IF (@shipcomplete = 1)
				BEGIN
					RETURN @ret
				END
				ELSE
				BEGIN
					SELECT	@ret, @message, 0
					RETURN
				END
				-- v1.8 End
			END

			SET @last_line_no = @line_no

			SELECT	TOP 1 @line_no = line_no,
					@part_no = part_no
			FROM	tdc_soft_alloc_tbl (NOLOCK)
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
			AND		order_type = 'S'
			AND		line_no > @last_line_no
			ORDER BY line_no ASC
		END	

		-- Remove any custom frame processing items that have not been processed
		SET @last_tran_id = 0

		SELECT	TOP 1 @tran_id = tran_id,
				@line_no = line_no,
				@part_no = part_no,
				@qty = qty_to_process,	
				@bin_no = bin_no
		FROM	tdc_pick_queue (NOLOCK)
		WHERE	trans_type_no = @order_no
		AND		trans_type_ext = @order_ext
		AND		next_op = @custom_bin
		AND		trans = 'MGTB2B'
		AND		tran_id	> @last_tran_id

		WHILE @@ROWCOUNT <> 0
		BEGIN

			-- update the quantity on the soft allocation record - these do not hold the order no
			UPDATE	tdc_soft_alloc_tbl
			SET		qty = qty - @qty
			WHERE	location = @location
			AND		part_no = @part_no
			AND		bin_no = @bin_no
			AND		order_no = 0
			AND		order_type = 'S'
			AND		target_bin = @custom_bin

			IF (@@ERROR <> 0)
			BEGIN
				SET @ret = -1
				SET @message = 'Order cancellation Failed, could not unallocate order.'
				-- v1.8 Start
				IF (@shipcomplete = 1)
				BEGIN
					RETURN @ret
				END
				ELSE
				BEGIN
					SELECT	@ret, @message, 0
					RETURN
				END
				-- v1.8 End
			END

			-- Remove the pick queue record
			DELETE	tdc_pick_queue
			WHERE	tran_id = @tran_id

			IF (@@ERROR <> 0)
			BEGIN
				SET @ret = -1
				SET @message = 'Order cancellation Failed, could not unallocate order.'
				-- v1.8 Start
				IF (@shipcomplete = 1)
				BEGIN
					RETURN @ret
				END
				ELSE
				BEGIN
					SELECT	@ret, @message, 0
					RETURN
				END
				-- v1.8 End
			END

			SET @last_tran_id = @tran_id

			SELECT	TOP 1 @tran_id = tran_id,
					@line_no = line_no,
					@part_no = part_no,
					@qty = qty_to_process,	
					@bin_no = bin_no
			FROM	tdc_pick_queue (NOLOCK)
			WHERE	trans_type_no = @order_no
			AND		trans_type_ext = @order_ext
			AND		next_op = @custom_bin
			AND		trans = 'MGTB2B'
			AND		tran_id	> @last_tran_id
		END
	END

	-- Check the status of the order - if it is just printed then we can reset it back to new
	-- if the status is Q (printed) then just reset the status
	-- START v1.3 - uncommenting code
	-- v1.1 Start
	IF (@status = 'Q' OR @shipcomplete = 1) -- v1.8
	BEGIN
		UPDATE	orders_all
		SET		status = 'N',
				printed = 'N'
		WHERE	order_no = @order_no
		AND		ext = @order_ext

		IF (@@ERROR <> 0)
		BEGIN
			SET @ret = -1
			SET @message = 'Error updating order status, update failed.'
			-- v1.8 Start
			IF (@shipcomplete = 1)
			BEGIN
				RETURN @ret
			END
			ELSE
			BEGIN
				SELECT	@ret, @message, 0
				RETURN
			END
			-- v1.8 End
		END

		-- Insert the audit record
		INSERT	dbo.cvo_order_cancellation_audit (order_no, order_ext, who_cancelled, when_cancelled, change_type)
		VALUES (@order_no, @order_ext, @user_id, GETDATE(), 'Status reset to New')

		-- v1.4 Start
		INSERT INTO tdc_log ( tran_date , userid , trans_source , module , trans , tran_no , tran_ext , part_no , lot_ser , bin_no , location , quantity , data ) 
		SELECT	GETDATE() , @user_id , 'BO' , 'ADM' , 'ORDER UPDATE' , a.order_no , a.ext , '' , '' , '' , a.location , '' ,
				'STATUS:N/STATUS RESET'
		FROM	orders_all a (NOLOCK)
		JOIN	cvo_orders_all b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.ext = b.ext
		WHERE	a.order_no = @order_no
		AND		a.ext = @order_ext
		-- v1.4 End


	END
	ELSE
	BEGIN -- otherwise a copy will be made and the original will be voided
	-- END v1.3
		EXEC @iret = dbo.cvo_soft_alloc_dup_orders_sp @order_no, @order_ext, @location, @customer_code, @new_order_no OUTPUT

		IF @iret <> 0
		BEGIN
			SET @ret = -1
			SET @message = 'Order cancellation Failed, could not create copy order.'
			SELECT	@ret, @message, 0
			RETURN
		END

		-- v1.9 Start
		DELETE	cvo_soft_alloc_hdr WHERE order_no = @order_no AND order_ext = @order_ext
		DELETE	cvo_soft_alloc_det WHERE order_no = @order_no AND order_ext = @order_ext
		-- v1.9 End

		-- v1.4 Start
		INSERT INTO tdc_log ( tran_date , userid , trans_source , module , trans , tran_no , tran_ext , part_no , lot_ser , bin_no , location , quantity , data ) 
		SELECT	GETDATE() , @user_id , 'BO' , 'ADM' , 'ORDER CREATION' , a.order_no , a.ext , '' , '' , '' , a.location , '' ,
				'STATUS:N'
		FROM	orders_all a (NOLOCK)
		JOIN	cvo_orders_all b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.ext = b.ext
		WHERE	a.order_no = @new_order_no
		AND		a.ext = 0
		-- v1.4 End

		-- START v1.7
		SET @is_drawdown = 0

		-- Get promo
		SELECT
			@promo_id = promo_id,
			@promo_level = promo_level
		FROM
			dbo.cvo_orders_all (NOLOCK)
		WHERE
			order_no = @order_no   
			AND ext = @order_ext   

		-- Check it's a drawdown promo
		IF EXISTS (SELECT 1 FROM dbo.cvo_promotions (NOLOCK) WHERE promo_id = @promo_id AND promo_level = @promo_level AND ISNULL(drawdown_promo,0) = 1)
		BEGIN
			SET @is_drawdown = 1 

			-- Copy drawdown detail records
			INSERT INTO dbo.CVO_debit_promo_customer_det(
				hdr_rec_id,
				order_no,
				ext,
				line_no,
				credit_amount,
				posted)
			SELECT
				hdr_rec_id,
				@new_order_no,
				0,
				line_no,
				credit_amount,
				0
			FROM
				dbo.CVO_debit_promo_customer_det (NOLOCK)
			WHERE
				order_no = @order_no   
				AND ext = @order_ext  
		END
		-- END v1.7


		-- Now void the order
		UPDATE	orders_all
		SET		status = 'V',
				void = 'V',
				void_who = LEFT(@user_id,20),
				void_date = GETDATE()
		WHERE	order_no = @order_no
		AND		ext = @order_ext

		IF (@@ERROR <> 0)
		BEGIN
			SET @ret = -1
			SET @message = 'Order cancellation Failed, could not void order.'
			SELECT	@ret, @message, 0
			RETURN
		END

		-- START v1.7
		IF @is_drawdown = 1
		BEGIN
			-- Apply drawdown amount to promo
			SELECT
				@hdr_rec_id = hdr_rec_id,
				@promo_amount = SUM(credit_amount)
			FROM
				dbo.CVO_debit_promo_customer_det (NOLOCK)
			WHERE
				order_no = @new_order_no 
				AND ext = 0
				AND posted = 0
			GROUP BY
				hdr_rec_id

			IF (ISNULL(@hdr_rec_id,0) <> 0) AND (ISNULL(@promo_amount,0) > 0)
			BEGIN
				-- Update header record
				UPDATE
					dbo.CVO_debit_promo_customer_hdr
				SET
					available = ISNULL(available,0) - @promo_amount,
					open_orders = ISNULL(open_orders,0) + @promo_amount
				WHERE
					hdr_rec_id = @hdr_rec_id
			END
		END
		-- END v1.7

		-- v1.4 Start
		INSERT INTO tdc_log ( tran_date , userid , trans_source , module , trans , tran_no , tran_ext , part_no , lot_ser , bin_no , location , quantity , data ) 
		SELECT	GETDATE() , @user_id , 'BO' , 'ADM' , 'ORDER UPDATE' , a.order_no , a.ext , '' , '' , '' , a.location , '' ,
				'STATUS:V/VOID - ORDER CANCELLED'
		FROM	orders_all a (NOLOCK)
		JOIN	cvo_orders_all b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.ext = b.ext
		WHERE	a.order_no = @order_no
		AND		a.ext = @order_ext
		-- v1.4 End

		SET @ret = 1

		-- Insert the audit record
		INSERT	dbo.cvo_order_cancellation_audit (order_no, order_ext, who_cancelled, when_cancelled, change_type)
		VALUES (@order_no, @order_ext, @user_id, GETDATE(), 'Order voided')
	
	-- START v1.3 - uncommenting code
	END --v1.1 End


	-- v1.8 Start
	IF (@shipcomplete = 1)
	BEGIN
		RETURN @ret
	END
	ELSE
	BEGIN
		SELECT	@ret, @message, @new_order_no
		RETURN
	END
	-- v1.8 End
 
END
GO
GRANT EXECUTE ON  [dbo].[cvo_cancel_order_sp] TO [public]
GO
