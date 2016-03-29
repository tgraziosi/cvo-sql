
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_pick_cart_process_sp] (@cart_no VARCHAR(50), @order_no INT, @order_ext INT, @proc_option int)
AS

-- @proc_options - 0 = check-in a new order to a cart
--				   1 = CHECK-OUT a completed ORDER
--				  99 = CHECK-OUT a non-completed order

-- Change History
-- 03/4/2016 - add error checks for existing order/cons to check in and check out
-- 3/10/16 - IGNORE VOIDS WHEN UPDATING ORDERS


-- exec cvo_pick_cart_process_sp 1, 2350742, 0, 0
-- select * From cvo_cart_order_parts
-- select * from cvo_cart_scan_orders
-- exec cvo_pick_cart_process_sp 1, 2350742, 0, 99 -- void
-- exec cvo_pick_cart_process_sp 1, 13416, 0, 0 -- check in
-- exec cvo_pick_cart_process_sp 1, 2663446, 0, 1 -- pick and check out

-- exec cvo_pick_cart_process_sp 'rlanka', 2404590, 0, 0


/*
 SELECT tx_lock, use r_id, mfg_batch, * FROM tdc_pick_queue WHERE trans_type_no = 2663446
 select user_hold, * From tdc_soft_alloc_tbl where order_no = 2327724
*/
-- order check in to Cart

SET NOCOUNT ON;
SET ANSI_WARNINGS OFF;

DECLARE @qty DECIMAL(20,8), @qty_to_process DECIMAL(20,8)
, @line_no INT, @station_id INT, @user_id VARCHAR(50), @tran_id INT
, @cart_order_no varchar(20)
, @asofdate DATETIME, @status VARCHAR(1), @who VARCHAR(50)

SELECT @station_id = 777, @user_id = @cart_no, @asofdate = GETDATE()

DECLARE @iscons INT

SELECT @ISCONS = CASE WHEN EXISTS (SELECT 1 FROM tdc_pick_queue WHERE mp_consolidation_no = @order_no) THEN 1 ELSE 0 END

-- validate order number passed in
IF not EXISTS ( SELECT 1 FROM dbo.tdc_pick_queue 
			WHERE ((@iscons = 0 AND trans_type_no = @order_no AND trans_type_ext = @order_ext)
				OR (@iscons = 1 AND mp_consolidation_no = @order_no)) )
			BEGIN
				SELECT 'Invalid order number or consolidation number', @order_no, @order_ext
				RETURN -1
			end

SELECT @cart_order_no = REPLACE(CONVERT(VARCHAR(10),@order_no) 
							+ CASE WHEN @iscons=0 THEN 
							'-' + CONVERT(VARCHAR(5),ISNULL(@order_ext,'')) ELSE '' end,' ','')

CREATE TABLE #temp_who (
	who  varchar(50) not null,  
	login_id varchar(50) not null)  
    
INSERT	#temp_who (who, login_id)   VALUES	('manager', 'manager')
SELECT @who = @cart_no

IF(OBJECT_ID('tempdb.dbo.#err') is not null)  drop table #err
create table #err ( tran_id INT, msg VARCHAR(255) )


IF @proc_option = 0 
	BEGIN

		IF NOT EXISTS (SELECT 1 FROM dbo.tdc_pick_queue AS tpq 
			WHERE ((@ISCONS = 0 AND trans_type_no = @order_no AND trans_type_ext = @order_ext)
		       OR (@ISCONS = 1 AND mp_consolidation_no = @ORDER_NO)) AND tx_lock = 'R')
			BEGIN
				SELECT 'Invalid order number or consolidation number', @order_no, @order_ext
				RETURN -1
			END
            
		IF @iscons = 0 AND NOT EXISTS (SELECT 1 FROM dbo.orders AS o
			WHERE ((order_no = @order_no AND o.ext = @order_ext) AND status IN ('p','q')))
			BEGIN
				SELECT 'Invalid order status', @order_no, @order_ext
				RETURN -1
			end

		-- Check in ... set WMS picks on hold
	IF EXISTS (SELECT 1 FROM dbo.tdc_pick_queue AS tpq 
			WHERE ((@ISCONS = 0 AND trans_type_no = @order_no AND trans_type_ext = @order_ext)
		       OR (@ISCONS = 1 AND mp_consolidation_no = @ORDER_NO)) AND tx_lock = 'R')
	UPDATE dbo.tdc_pick_queue with (ROWLOCK) SET tx_lock = 'H', user_id = 'Pick Cart ' + cast (@cart_no AS VARCHAR(20))  
		WHERE ((@ISCONS = 0 AND trans_type_no = @order_no AND trans_type_ext = @order_ext)
		       OR (@ISCONS = 1 AND mp_consolidation_no = @ORDER_NO)) AND tx_lock = 'R'

	IF @iscons = 0 
	begin
	IF EXISTS (SELECT 1 FROM tdc_soft_alloc_tbl WHERE order_no = @order_no AND order_ext = @order_ext AND USER_HOLD <> 'Y' )	
		UPDATE dbo.tdc_soft_alloc_tbl WITH (ROWLOCK) SET user_hold = 'Y' 
		WHERE order_no = @order_no AND order_ext = @order_ext AND USER_HOLD <> 'Y'
    END
    IF @iscons = 1
	BEGIN
		IF EXISTS (SELECT 1 FROM tdc_soft_alloc_tbl SA JOIN dbo.cvo_masterpack_consolidation_det AS cmcd
	   ON cmcd.order_no = SA.order_no AND cmcd.order_ext = SA.order_ext
	    WHERE cmcd.consolidation_no = @order_no AND sa.USER_HOLD <> 'Y')	
		UPDATE sa WITH (ROWLOCK) SET  user_hold = 'Y' 
	   FROM dbo.tdc_soft_alloc_tbl SA WITH (ROWLOCK) 
	   JOIN dbo.cvo_masterpack_consolidation_det AS cmcd
	   ON cmcd.order_no = SA.order_no AND cmcd.order_ext = SA.order_ext
	   WHERE cmcd.consolidation_no = @order_no AND sa.USER_HOLD <> 'Y'
	end


	-- write to cart pick table ?
	IF NOT EXISTS (SELECT 1 FROM dbo.cvo_cart_scan_orders WHERE order_no = @cart_order_no)
	 AND NOT EXISTS (SELECT 1 FROM dbo.cvo_cart_order_parts WHERE order_no = @cart_order_no)
	BEGIN
		INSERT cvo_cart_scan_orders (order_no, scan_date, scan_user, order_status)
			VALUES (@cart_order_no, GETDATE(), @cart_no, 'I')
		INSERT cvo_cart_order_parts 
		 (tran_id, order_no, part_no, user_login, bin_no, upc_code, qty_to_process, scanned, isskipped, bin_group_code)
		 SELECT DISTINCT p.tran_id, @cart_order_no, p.part_no, @cart_no, p.bin_no, i.upc_code, p.qty_to_process, 0, 0, bin.group_code
			FROM dbo.tdc_pick_queue p (NOLOCK)
			JOIN dbo.inv_master i (NOLOCK) ON i.part_no = p.part_no 
			JOIN tdc_bin_master bin (NOLOCK) ON bin.bin_no = p.bin_no AND bin.location = p.location
			WHERE (@iscons = 0 AND p.trans_type_no = @order_no AND p.trans_type_ext = @order_ext)
				   OR (@iscons = 1 AND p.mp_consolidation_no = @order_no)	
	 END

	 	-- put the order in Open/Pick status
	SELECT @status = 'P'   

	IF @iscons = 0
  	UPDATE orders   WITH (ROWLOCK)
		SET status = @status, printed = @status, who_picked = @who, date_shipped = NULL, freight = tot_ord_freight  
		WHERE order_no = @order_no AND ext = @order_ext AND status <> @status  

	IF @iscons = 1
	UPDATE o WITH (rowlock) SET o.status = @status, printed = @status, who_picked = @who,
								date_shipped = NULL, freight = tot_ord_freight  
	   FROM orders o WITH (ROWLOCK) JOIN dbo.cvo_masterpack_consolidation_det AS cmcd
	   ON cmcd.order_no = o.order_no AND cmcd.order_ext = o.ext
	   WHERE cmcd.consolidation_no = @order_no AND o.status <> @status AND o.status < 'T' -- 3/10/16 - IGNORE VOIDS AND COMPLETED ORDERS
	
	end

IF @proc_option = 1 
begin
-- order check out from cart when picks complete

	-- release holds
	IF EXISTS ( SELECT 1 FROM dbo.tdc_pick_queue 
			WHERE ((@iscons = 0 AND trans_type_no = @order_no AND trans_type_ext = @order_ext)
				OR (@iscons = 1 AND mp_consolidation_no = @order_no)) AND tx_lock <> 'R')
	UPDATE tdc_pick_queue WITH (ROWLOCK) SET tx_lock = 'R', mfg_batch = NULL 
		WHERE ((@iscons = 0 AND trans_type_no = @order_no AND trans_type_ext = @order_ext)
				OR (@iscons = 1 AND mp_consolidation_no = @order_no)) AND tx_lock <> 'R'

	IF(@iscons = 0)
	IF EXISTS (SELECT 1 FROM dbo.tdc_soft_alloc_tbl AS tsat WHERE ORDER_NO = @ORDER_NO AND ORDER_EXT = @order_ext	
			AND USER_HOLD <> 'N')
	UPDATE dbo.tdc_soft_alloc_tbl WITH (ROWLOCK) SET user_hold = 'N' 
		WHERE order_no = @order_no AND order_ext = @order_ext
		AND user_hold <> 'N'

	IF (@iscons = 1)
	IF EXISTS (SELECT 1 
			   FROM dbo.tdc_soft_alloc_tbl SA WITH (ROWLOCK) JOIN dbo.cvo_masterpack_consolidation_det AS cmcd
	   ON cmcd.order_no = SA.order_no AND cmcd.order_ext = SA.order_ext
	   WHERE cmcd.consolidation_no = @order_no AND sa.USER_HOLD <> 'N')
	UPDATE sa WITH (ROWLOCK) SET  user_hold = 'N' 
	   FROM dbo.tdc_soft_alloc_tbl SA WITH (ROWLOCK) 
	   JOIN dbo.cvo_masterpack_consolidation_det AS cmcd
	   ON cmcd.order_no = SA.order_no AND cmcd.order_ext = SA.order_ext
	   WHERE cmcd.consolidation_no = @order_no AND sa.USER_HOLD <> 'N'


	SELECT @tran_id = MIN(p.tran_id) FROM tdc_pick_queue p
		 WHERE (@iscons = 0 AND trans_type_no = @order_no
				AND trans_type_ext = @order_ext)
			OR (@iscons = 1 AND p.mp_consolidation_no = @order_no)

	WHILE @tran_id IS NOT NULL
	BEGIN

		SELECT @line_no = line_no, @qty_to_process = qty_to_process -- change to qty_processed later  
			FROM tdc_pick_queue (NOLOCK) WHERE tran_id = @tran_id
		
		SELECT @qty = CASE WHEN scanned > @qty_to_process THEN @qty_To_process ELSE scanned END
        FROM dbo.cvo_cart_parts_processed WHERE @tran_id = tran_id

		IF ISNULL(@qty,0) > 0 
		BEGIN
			IF @ISCONS = 0
				EXEC dbo.cvo_autopick_line_sp
				@tran_id , -- int
				@order_no , -- int
				@order_ext , -- int
				@line_no , -- int
				@qty, -- decimal
				@station_id , -- int
				@user_id = '' -- varchar(50)
			IF @ISCONS = 1
				EXEC dbo.cvo_masterpack_pick_consolidated_transaction_sp 
				@tran_id,
				@QTY,
				0,
				''
			UPDATE pp SET ISPICKED = 'Y', PP.pick_complete_dt = @asofdate
			    FROM CVO_CART_PARTS_PROCESSED PP
				WHERE TRAN_ID = @tran_id and ispicked <> 'y'

		END
 		
		UPDATE dbo.cvo_cart_orders_processed SET order_status = 'C', processed_date = @asofdate 
			WHERE order_no = @cart_order_no


		SELECT @tran_id = MIN(p.tran_id) FROM tdc_pick_queue p
				 WHERE ((@iscons = 0 AND trans_type_no = @order_no
						AND trans_type_ext = @order_ext)
					OR (@iscons = 1 AND p.mp_consolidation_no = @order_no))
				AND p.tran_id > @tran_id

	END -- processing loop
    END -- proc_option = 1
    
IF @proc_option = 99
-- void a checked in order
begin

	-- release holds
	UPDATE tdc_pick_queue WITH (ROWLOCK) SET tx_lock = 'R', mfg_batch = NULL, user_id = ''
		WHERE ((@iscons = 0 AND trans_type_no = @order_no AND trans_type_ext = @order_ext)
				OR (@iscons = 1 AND mp_consolidation_no = @order_no)) AND tx_lock <> 'R'

	IF(@iscons = 0)
	UPDATE dbo.tdc_soft_alloc_tbl WITH (ROWLOCK) SET user_hold = 'N' 
		WHERE order_no = @order_no AND order_ext = @order_ext
		AND user_hold <> 'N'

	IF (@iscons = 1)
	UPDATE sa SET  user_hold = 'N' 
	   FROM dbo.tdc_soft_alloc_tbl SA WITH (ROWLOCK) JOIN dbo.cvo_masterpack_consolidation_det AS cmcd
	   ON cmcd.order_no = SA.order_no AND cmcd.order_ext = SA.order_ext
	   WHERE cmcd.consolidation_no = @order_no AND sa.USER_HOLD <> 'N'

	DELETE FROM dbo.cvo_cart_order_parts WHERE order_no = @cart_order_no
	DELETE FROM dbo.cvo_cart_scan_orders WHERE order_no = @cart_order_no

	
		-- put the order back in Open/Print status
	SELECT @status = 'Q'   

	IF @iscons = 0
  	UPDATE orders   WITH (ROWLOCK)
		SET status = @status, printed = @status, who_picked = @who, date_shipped = NULL, freight = tot_ord_freight  
		WHERE order_no = @order_no AND ext = @order_ext AND status <> @status  

	IF @iscons = 1
	UPDATE o WITH (rowlock) SET o.status = @status, printed = @status, who_picked = @who,
								date_shipped = NULL, freight = tot_ord_freight  
	   FROM orders o WITH (ROWLOCK) JOIN dbo.cvo_masterpack_consolidation_det AS cmcd
	   ON cmcd.order_no = o.order_no AND cmcd.order_ext = o.ext
	   WHERE cmcd.consolidation_no = @order_no AND o.status <> @status AND O.STATUS < 'T'

END -- proc_option = 99

 







GO
