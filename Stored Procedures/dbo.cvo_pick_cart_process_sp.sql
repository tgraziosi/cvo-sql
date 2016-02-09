
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_pick_cart_process_sp] (@cart_no INT, @order_no INT, @order_ext INT, @proc_option int)
AS

-- @proc_options - 0 = check-in a new order to a cart
--				   1 = CHECK-OUT a completed ORDER
--				  99 = CHECK-OUT a non-completed order

--2350742
--2335349

-- exec cvo_pick_cart_process_sp 1, 2350742, 0, 0
-- select * From cvo_cart_order_parts
-- select * from cvo_cart_scan_orders
-- exec cvo_pick_cart_process_sp 1, 2350742, 0, 99 -- void
-- exec cvo_pick_cart_process_sp 1, 2427544, 0, 0 -- check in
-- exec cvo_pick_cart_process_sp 1, 2663446, 0, 1 -- pick and check out

/*
 SELECT tx_lock, user_id, mfg_batch, * FROM tdc_pick_queue WHERE trans_type_no = 2663446
 select user_hold, * From tdc_soft_alloc_tbl where order_no = 2327724
*/
-- order check in to Cart

SET NOCOUNT ON;
SET ANSI_WARNINGS OFF;

DECLARE @qty DECIMAL(20,8), @qty_to_process DECIMAL(20,8)
, @line_no INT, @station_id INT, @user_id VARCHAR(50), @tran_id INT
, @cart_order_no varchar(20)
, @asofdate DATETIME

SELECT @station_id = 777, @user_id = '', @asofdate = GETDATE()

SELECT @cart_order_no = REPLACE(CONVERT(VARCHAR(10),@order_no) + '-' + CONVERT(VARCHAR(5),@order_ext),' ','')

CREATE TABLE #temp_who (
	who  varchar(50) not null,  
	login_id varchar(50) not null)  
    
INSERT	#temp_who (who, login_id)   VALUES	('manager', 'manager')

IF(OBJECT_ID('tempdb.dbo.#err') is not null)  drop table #err
create table #err ( tran_id INT, msg VARCHAR(255) )

IF @proc_option = 0 
	BEGIN
	-- Check in ... set WMS picks on hold
	UPDATE dbo.tdc_pick_queue with (ROWLOCK) SET tx_lock = 'H', user_id = 'Pick Cart ' + cast (@cart_no AS VARCHAR(1))  
		WHERE trans_type_no = @order_no AND trans_type_ext = @order_ext AND tx_lock = 'R'

	UPDATE dbo.tdc_soft_alloc_tbl WITH (ROWLOCK) SET user_hold = 'Y' 
		WHERE order_no = @order_no AND order_ext = @order_ext AND USER_HOLD <> 'Y'


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
			WHERE p.trans_type_no = @order_no AND p.trans_type_ext = @order_ext
	 end
	end

IF @proc_option = 1 
begin
-- order check out from cart when picks complete

	-- release holds
	UPDATE tdc_pick_queue WITH (ROWLOCK) SET tx_lock = 'R', mfg_batch = NULL 
		WHERE trans_type_no = @order_no AND trans_type_ext = @order_ext AND tx_lock <> 'R'

	UPDATE dbo.tdc_soft_alloc_tbl WITH (ROWLOCK) SET user_hold = 'N' 
		WHERE order_no = @order_no AND order_ext = @order_ext
		AND user_hold <> 'N'

	SELECT @tran_id = MIN(p.tran_id) FROM tdc_pick_queue p
		 WHERE trans_type_no = @order_no
		 AND trans_type_ext = @order_ext

	WHILE @tran_id IS NOT NULL
	BEGIN

		SELECT @line_no = line_no, @qty_to_process = qty_to_process -- change to qty_processed later  
			FROM tdc_pick_queue (NOLOCK) WHERE tran_id = @tran_id
		
		SELECT @qty = CASE WHEN scanned > @qty_to_process THEN @qty_To_process ELSE scanned END
        FROM dbo.cvo_cart_parts_processed WHERE @tran_id = tran_id

		IF ISNULL(@qty,0) > 0 
		begin
		    EXEC dbo.cvo_autopick_line_sp
			@tran_id , -- int
			@order_no , -- int
			@order_ext , -- int
			@line_no , -- int
			@qty, -- decimal
			@station_id , -- int
			@user_id = '' -- varchar(50)
		end
		UPDATE pp SET ISPICKED = 'Y', PP.pick_complete_dt = @asofdate
			    FROM CVO_CART_PARTS_PROCESSED PP
				WHERE TRAN_ID = @tran_id and ispicked <> 'y'
		
		SELECT @tran_id = MIN(p.tran_id) FROM tdc_pick_queue p
				WHERE trans_type_no = @order_no AND trans_type_ext = @order_ext
				AND p.tran_id > @tran_id

	END -- processing loop
	
	UPDATE dbo.cvo_cart_orders_processed SET processed_date = @asofdate WHERE @order_no = @cart_order_no

    END -- proc_option = 1
    
IF @proc_option = 99
-- void a checked in order
begin
		UPDATE tdc_pick_queue WITH (ROWLOCK) SET tx_lock = 'R', user_id = '' 
			WHERE trans_type_no = @order_no AND trans_type_ext = @order_ext 
			 AND tx_lock <> 'R'
		UPDATE dbo.tdc_soft_alloc_tbl WITH (ROWLOCK) SET user_hold = 'N' 
			WHERE order_no = @order_no AND order_ext = @order_ext AND user_hold <> 'N'

		DELETE FROM dbo.cvo_cart_order_parts WHERE order_no = @cart_order_no
		DELETE FROM dbo.cvo_cart_scan_orders WHERE order_no = @cart_order_no

END -- proc_option = 99

 


GO
