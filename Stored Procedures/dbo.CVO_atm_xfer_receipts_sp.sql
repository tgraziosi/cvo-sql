SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[CVO_atm_xfer_receipts_sp.sql]    Script Date: 08/18/2010  *****
SED009 -- Transfer Orders - Product Shipping to & From a Sales Rep   
Object:      Procedure  CVO_atm_xfer_receipts_sp  
Source file: CVO_atm_xfer_receipts_sp.sql
Author:		 Jesus Velazquez
Created:	 09/21/2010
Function:    
Modified:    
Calls:    
Called by:   WMS PC Client
Copyright:   Epicor Software 2010.  All rights reserved. 
-- v1.0 CB 23/02/2012 - Issue - Statement that retrieved the to location was in the wrong place so only held the first location when mutliple transfers processed 
-- v1.1 CT 20/11/2012 - When receiving transfer returns, receive to bin held in XFER_RETURN_REC_BIN config setting	
-- v1.2 CT 15/05/2013 - Issue #1268 - When loading #adm_rec_xfer table only enter 1 line per part_no/location
-- v1.3 CB 07/08/2013 - Isssue #1202 - Transfer email moved to transfer ship confirm
-- v1.4 CB 23/04/2015 - Performance Changes
*/
CREATE PROCEDURE [dbo].[CVO_atm_xfer_receipts_sp]
AS

BEGIN
	DECLARE @order_no	INT,
			@from_loc	VARCHAR(10),
			@to_loc		VARCHAR(10),
			@main_loc	VARCHAR(10),
			@tran_no	INT, 
			@part_no	VARCHAR(30), 
			@line_no	INT, 
			@from_bin	VARCHAR(12), 
			@lot_ser	VARCHAR(25), 
			@to_bin		VARCHAR(12), 
			@location	VARCHAR(10), 
			@qty		DECIMAL(20,8), 
			@who		VARCHAR(50), 
			@err_msg	INT, 
			@custom_frame_bin	varchar(40),								-- T Mcgrady	NOV.29.2010 
			@xfer_ret_bin	VARCHAR(12)	-- v1.1

	-- v1.4 Start
	DECLARE	@row_id			int,
			@last_row_id	int,
			@row2_id		int,
			@last_row2_id	int
	-- v1.4 End

	SET @main_loc = 'CVO'--'Vancouver'

	/*IF (SELECT OBJECT_ID('tempdb..#temp_who')) IS NOT NULL 
		DROP TABLE #temp_who
		
	CREATE TABLE #temp_who
	(who		VARCHAR(50) NOT NULL,
	 login_id	VARCHAR(50) NOT NULL)
	 
	INSERT INTO #temp_who (      who,  login_id) 
	VALUES                ('manager', 'manager')*/

	-- START v1.1
	SELECT @xfer_ret_bin = value_str FROM dbo.tdc_config (NOLOCK) WHERE [function] = 'TRANSFER_RETURN_RECEIPT_BIN'
	-- END v1.1

	SELECT @custom_frame_bin = isnull(value_str,'CUSTOM') FROM tdc_config WHERE [function] = 'CVO_CUSTOM_BIN'		-- T McGrady

	IF (SELECT OBJECT_ID('tempdb..#xfer_serials')) IS NOT NULL
		DROP TABLE #xfer_serials
		
	CREATE TABLE #xfer_serials 
	(part_no    VARCHAR (30) NOT NULL,
	 lot_ser    VARCHAR (25) NOT NULL,
	 serial_no  VARCHAR (40)     NULL,
	 serial_raw VARCHAR (40)     NULL)


	IF (SELECT OBJECT_ID('tempdb..#adm_rec_xfer')) IS NOT NULL
		DROP TABLE #adm_rec_xfer
		            

	CREATE TABLE #adm_rec_xfer 
	(xfer_no	INT				NOT NULL, 
	 part_no	VARCHAR (30)	NOT NULL, 
	 line_no	INT				NOT NULL, 
	 from_bin	VARCHAR (12)		NULL, 
	 lot_ser	VARCHAR (25)		NULL, 
	 to_bin		VARCHAR (12)		NULL, 
	 location	VARCHAR(10)		NOT NULL, 
	 qty		DECIMAL(20,8)	NOT NULL, 
	 who		VARCHAR(50)			NULL, 
	 err_msg	VARCHAR(255)		NULL, 
	 row_id		INT	   IDENTITY NOT NULL)

	-- v1.4 Start
	CREATE TABLE #cvo_atm_orders_cur (
		row_id		int IDENTITY(1,1),
		order_no	int)

	CREATE TABLE #cvo_atm_det_cur (
		row_id		int IDENTITY(1,1),
		tran_no		int,
		part_no		varchar(30) NULL,
		line_no		int,
		lot_ser		varchar(25) NULL,
		bin_no		varchar(12) NULL,
		location	varchar(10) NULL,
		qty			decimal(20,8),
		who			varchar(50) NULL)

	INSERT	#cvo_atm_orders_cur (order_no)
	-- v1.4 DECLARE orders_cur CURSOR FOR 
	SELECT DISTINCT order_no
	FROM   #xfersToShip
	WHERE  commit_ok = 1
	ORDER BY order_no ASC
	
	-- v1.4 OPEN orders_cur
	-- v1.4 FETCH NEXT FROM orders_cur INTO @order_no
	-- v1.4 WHILE @@FETCH_STATUS = 0

	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@order_no = order_no
	FROM	#cvo_atm_orders_cur
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

	WHILE @@ROWCOUNT <> 0
	BEGIN

		-- v1.0 Moved from before the while loop
		SELECT	@from_loc = from_organization_id,--from_loc,
				@to_loc   = to_loc
		FROM	xfers
		WHERE   xfer_no = @order_no

		-- v1.4 Start
		TRUNCATE TABLE #cvo_atm_det_cur

		INSERT	#cvo_atm_det_cur (tran_no, part_no, line_no, lot_ser, bin_no, location, qty, who)
		-- START v1.2
		-- v1.4 DECLARE detail_cur CURSOR FOR 
		SELECT tran_no, part_no, line_no, lot_ser, MIN(bin_no), location, SUM(qty), MIN(who) 
		--SELECT tran_no, part_no, line_no, lot_ser, bin_no, location, qty, who
		FROM   lot_bin_xfer (nolock) 
		WHERE  tran_no = @order_no AND tran_ext = 0
		GROUP BY 	tran_no, part_no, line_no, lot_ser,  location
		-- END v1.2

		-- v1.4 OPEN detail_cur
		-- v1.4 FETCH NEXT FROM detail_cur INTO @tran_no, @part_no, @line_no, @lot_ser, @to_bin, @location, @qty, @who
		-- v1.4 WHILE @@FETCH_STATUS = 0
	
		SET @last_row2_id = 0

		SELECT	TOP 1 @row2_id = row_id,
				@tran_no = tran_no,
				@part_no = part_no,
				@line_no = line_no,
				@lot_ser = lot_ser,
				@to_bin = bin_no,
				@location = location,
				@qty = qty,
				@who = who
		FROM	#cvo_atm_det_cur
		WHERE	row_id > @last_row2_id
		ORDER BY row_id ASC
	
		WHILE @@ROWCOUNT <> 0
		BEGIN
			INSERT INTO #adm_rec_xfer ( xfer_no,  part_no,  line_no, from_bin,  lot_ser,  to_bin,  location,  qty,  who, err_msg) 									
			VALUES                    (@tran_no, @part_no, @line_no,       '', @lot_ser, @to_bin, @location, @qty, @who,    NULL)
		   
			SET @last_row2_id = @row2_id

			SELECT	TOP 1 @row2_id = row_id,
					@tran_no = tran_no,
					@part_no = part_no,
					@line_no = line_no,
					@lot_ser = lot_ser,
					@to_bin = bin_no,
					@location = location,
					@qty = qty,
					@who = who
			FROM	#cvo_atm_det_cur
			WHERE	row_id > @last_row2_id
			ORDER BY row_id ASC

		  -- v1.4 FETCH NEXT FROM detail_cur INTO @tran_no, @part_no, @line_no, @lot_ser, @to_bin, @location, @qty, @who
		END

		-- v1.4 CLOSE detail_cur
		-- v1.4 DEALLOCATE detail_cur			

		--Scenario transfer request from 'CVO' to 'other'
		IF @from_loc = @main_loc AND EXISTS (SELECT * FROM #adm_rec_xfer)
		BEGIN
			-- START v1.1
			SET @to_bin = NULL
			
			IF EXISTS (SELECT 1 FROM dbo.CVO_transfer_return_autoship (NOLOCK) WHERE xfer_no = @order_no)
			BEGIN
				-- Check bin exists at location
				IF EXISTS (SELECT 1 FROM dbo.tdc_bin_master (NOLOCK) WHERE location = @to_loc AND bin_no = @xfer_ret_bin)
				BEGIN
					SET	@to_bin = @xfer_ret_bin
				END
			END
			
			IF @to_bin IS NULL
			BEGIN
				--receiving automatically into Open bin
				SELECT	TOP 1 @to_bin = bin_no
				FROM	tdc_bin_master (nolock) 								 
				WHERE	location		= @to_loc 	AND 
						usage_type_code = 'OPEN' 	AND 
						status			= 'A' AND	
						bin_no			<> @custom_frame_bin					-- T McGrady	NOV.29.2010
			END
			-- END v1.1

			IF @to_bin IS NOT NULL
				UPDATE #adm_rec_xfer
				SET    to_bin = @to_bin


					
			--xfer receiving
			EXECUTE @err_msg = [tdc_rec_xfer]					
			
			IF @err_msg = 0
			BEGIN
				INSERT INTO tdc_log (tran_date,    userID, trans_source, module,         trans,   tran_no,  data)
				VALUES              (getdate(), 'manager',         'VB',  'PPS', 'ShipConfirm', @order_no,  'Atm xfer receiving from location: ' + @from_loc + ' to location: ' + @to_loc )
				
				-- v1.3EXEC CVO_send_xfer_notification_sp @order_no, 1
			END				
			ELSE
			BEGIN
				INSERT INTO tdc_log (tran_date,    userID, trans_source, module,         trans,   tran_no,  data)
				VALUES              (getdate(), 'manager',         'VB',  'PPS', 'ShipConfirm', @order_no,  'Error no: ' + CAST(@err_msg AS VARCHAR(10)) + ' in atm xfer receiving from location:' + @from_loc + ' to location:' + @to_loc )
			END		
						
		END		
				

		TRUNCATE TABLE #adm_rec_xfer
		
		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@order_no = order_no
		FROM	#cvo_atm_orders_cur
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC
   
		-- v1.4 FETCH NEXT FROM orders_cur INTO @order_no
	END
	
	-- v1.4 CLOSE orders_cur
	-- v1.4 DEALLOCATE orders_cur
	
END
-- Permissions
GO
GRANT EXECUTE ON  [dbo].[CVO_atm_xfer_receipts_sp] TO [public]
GO
