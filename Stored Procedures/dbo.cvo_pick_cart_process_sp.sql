SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_pick_cart_process_sp]
    (
        @cart_no VARCHAR(50) ,
        @order_no INT ,
        @order_ext INT ,
        @proc_option INT
    )
AS

    -- @proc_options - 0 = check-in a new order to a cart
    --				   1 = CHECK-OUT a completed ORDER
    --				  99 = CHECK-OUT a non-completed order

    -- Change History
    -- 03/4/2016 - add error checks for existing order/cons to check in and check out
    -- 3/10/16 - IGNORE VOIDS WHEN UPDATING ORDERS
    -- 6/26/2017 - WRITE TO TDC_LOG
    -- 10/2/2017 - add support for transfers


    -- exec cvo_pick_cart_process_sp 1, 134655, 0, 1
    -- select * From cvo_cart_order_parts where order_no like '3217575%'
    -- select * from cvo_cart_scan_orders where order_no like '3217575%'
    -- exec cvo_pick_cart_process_sp 1, 3217575, 0, 99 -- void
    -- exec cvo_pick_cart_process_sp 1, 25686, 0, 0 -- check in
    -- exec cvo_pick_cart_process_sp 1, 25686, 0, 1 -- pick and check out

    /*
      select * From dbo.cvo_cart_parts_processed AS cpp -- order by tran_id desc
	  wHERE cpp.order_no LIKE '25686%'

      UPDATE cpp SET cpp.isPicked = 'N', cpp.pick_complete_dt = NULL
      -- SELECT * 
      FROM dbo.cvo_cart_parts_processed AS cpp -- order by tran_id desc
	  wHERE cpp.order_no LIKE '25686'
            UPDATE cpp SET cpp.isPicked = 'Y', cpp.pick_complete_dt = getdate()
      -- SELECT * 
      FROM dbo.cvo_cart_parts_processed AS cpp -- order by tran_id desc
	  wHERE cpp.order_no LIKE '25686'

    */
    -- exec cvo_pick_cart_process_sp 'rlanka', 2404590, 0, 0

    --SELECT * FROM dbo.tdc_pick_queue AS tpq WHERE tpq.trans_type_no = 134655

    /*
 SELECT tx_lock, user_id, mfg_batch, * FROM tdc_pick_queue WHERE trans_type_no = 2931138
 select user_hold, * From tdc_soft_alloc_tbl where order_no = 2327724
*/
    -- order check in to Cart

    SET NOCOUNT ON;
    SET ANSI_WARNINGS OFF;

    DECLARE @qty DECIMAL(20, 8) ,
            @qty_to_process DECIMAL(20, 8) ,
            @ROWS INT ,
            @line_no INT ,
            @station_id INT ,
            @user_id VARCHAR(50) ,
            @tran_id INT ,
            @cart_order_no VARCHAR(20) ,
            @asofdate DATETIME ,
            @status VARCHAR(1) ,
            @who VARCHAR(50) ,
            @order_type VARCHAR(10);

    SELECT @station_id = 777 ,
           @user_id = @cart_no ,
           @asofdate = GETDATE();

    DECLARE @iscons INT ,
            @isxfer INT ,
            @isorder INT;
	
	SELECT @iscons = 0, @isxfer = 0, @isorder = 0;

    SELECT @isorder = CASE WHEN EXISTS (   SELECT 1
                                           FROM   dbo.orders AS o
                                           WHERE  order_no = @order_no
                                                  AND ext = @order_ext ) THEN
                               1
                           ELSE 0
                      END;
    IF @isorder = 0
        SELECT @iscons = CASE WHEN EXISTS (   SELECT 1
                                              FROM   dbo.cvo_masterpack_consolidation_hdr
                                              WHERE  consolidation_no = @order_no ) THEN
                                  1
                              ELSE 0
                         END;
    IF @isorder = 0
       AND @iscons = 0
        SELECT @isxfer = CASE WHEN EXISTS (   SELECT 1
                                              FROM   dbo.xfers_all AS xa
                                              WHERE  xa.xfer_no = @order_no ) THEN
                                  1
                              ELSE 0
                         END;

    IF @isorder + @iscons + @isxfer = 0
        BEGIN
            SELECT 'Document number not found' ,
                   @order_no ,
                   @order_ext;
            RETURN -1;
        END;

    IF @isxfer = 1
        SELECT @order_ext = 0;

    -- validate order number passed in
    IF NOT EXISTS (   SELECT 1
                      FROM   dbo.tdc_pick_queue
                      WHERE  (   ( @iscons = 0 )
                                 AND trans_type_no = @order_no
                                 AND trans_type_ext = @order_ext )
                             OR (   @iscons = 1
                                    AND mp_consolidation_no = @order_no ))
        BEGIN
            SELECT CASE WHEN o.status = 'V' THEN 'Order is Void'
                        WHEN o.status > 'Q' THEN 'Order is Complete'
                        WHEN o.status < 'N' THEN 'Order is On Hold'
                        ELSE 'Invalid order or no open picks'
                   END ,
                   @order_no ,
                   @order_ext
            FROM   orders o ( NOLOCK )
            WHERE  order_no = @order_no
                   AND ext = @order_ext
                   AND @isorder = 1;

            SELECT CASE WHEN o.status = 'V' THEN 'Xfer is Void'
                        WHEN o.status > 'Q' THEN 'Xfer is Complete'
                        WHEN o.status < 'N' THEN 'Xfer is On Hold'
                        ELSE 'Invalid Xfer or no open picks'
                   END ,
                   @order_no ,
                   @order_ext
            FROM   dbo.xfers_all AS o ( NOLOCK )
            WHERE  o.xfer_no = @order_no
                   AND @isxfer = 1;

            SELECT CASE WHEN h.shipped = 1 THEN 'Cons is Shipped'
                        WHEN h.closed = 1 THEN 'Cons is Closed'
                        ELSE 'Invalid Consolidation or no open picks'
                   END ,
                   @order_no
            FROM   dbo.cvo_masterpack_consolidation_hdr AS h
            WHERE  h.consolidation_no = @order_no
                   AND @iscons = 1;

            RETURN -1;
        END;

    SELECT @cart_order_no = REPLACE(
                                CONVERT(VARCHAR(10), @order_no)
                                + CASE WHEN @iscons = 0 THEN
                                           '-'
                                           + CONVERT(
                                                 VARCHAR(5) ,
                                                 ISNULL(@order_ext, ''))
                                       ELSE ''
                                  END ,
                                ' ' ,
                                '');

    CREATE TABLE #temp_who
        (
            who VARCHAR(50) NOT NULL ,
            login_id VARCHAR(50) NOT NULL
        );

    INSERT #temp_who ( who ,
                       login_id )
    VALUES ( 'manager', 'manager' );
    SELECT @who = @cart_no;

    IF ( OBJECT_ID('tempdb.dbo.#err') IS NOT NULL )
        DROP TABLE #err;
    CREATE TABLE #err
        (
            tran_id INT ,
            msg VARCHAR(255)
        );

    SELECT @ROWS = 0;

    IF @proc_option = 0 -- check in
        BEGIN

            IF NOT EXISTS (   SELECT 1
                              FROM   dbo.tdc_pick_queue AS tpq (nolock)
                              WHERE  (   (   @iscons = 0
                                             AND trans_type_no = @order_no
                                             AND trans_type_ext = @order_ext )
                                         OR (   @iscons = 1
                                                AND mp_consolidation_no = @order_no ))
                                     AND tx_lock = 'R' )
                BEGIN
                    SELECT 'Invalid order/xfer or consolidation number' ,
                           @order_no ,
                           @order_ext;
                    RETURN -1;
                END;

            IF @isorder = 1
               AND NOT EXISTS (   SELECT 1
                                  FROM   dbo.orders AS o (nolock)
                                  WHERE  (   (   order_no = @order_no
                                                 AND o.ext = @order_ext )
                                             AND status IN ( 'n', 'p', 'q' )))
                BEGIN
                    SELECT 'Invalid order status' ,
                           @order_no ,
                           @order_ext;
                    RETURN -1;
                END;

            IF @isxfer = 1
               AND NOT EXISTS (   SELECT 1
                                  FROM   dbo.xfers_all AS xa (nolock)
                                  WHERE  (   ( xa.xfer_no = @order_no )
                                             AND status IN ( 'n', 'p', 'q' )))
                BEGIN
                    SELECT 'Invalid xfer status' ,
                           @order_no ,
                           @order_ext;
                    RETURN -1;
                END;

            -- Check in ... set WMS picks on hold
            IF EXISTS (   SELECT 1
                          FROM   dbo.tdc_pick_queue AS tpq (nolock)
                          WHERE  (   (   @iscons = 0
                                         AND trans_type_no = @order_no
                                         AND trans_type_ext = @order_ext )
                                     OR (   @iscons = 1
                                            AND mp_consolidation_no = @order_no ))
                                 AND tx_lock = 'R' )
                UPDATE dbo.tdc_pick_queue WITH ( ROWLOCK )
                SET    tx_lock = 'H' ,
                       user_id = 'Pick Cart ' + CAST(@cart_no AS VARCHAR(20))
                WHERE  (   (   @iscons = 0
                               AND trans_type_no = @order_no
                               AND trans_type_ext = @order_ext )
                           OR (   @iscons = 1
                                  AND mp_consolidation_no = @order_no ))
                       AND tx_lock = 'R';

            SELECT @ROWS = @@ROWCOUNT;

            IF @iscons = 0
                BEGIN
                    IF EXISTS (   SELECT 1
                                  FROM   tdc_soft_alloc_tbl (nolock)
                                  WHERE  order_no = @order_no
                                         AND order_ext = @order_ext
                                         AND user_hold <> 'Y' )
                        UPDATE dbo.tdc_soft_alloc_tbl WITH ( ROWLOCK )
                        SET    user_hold = 'Y'
                        WHERE  order_no = @order_no
                               AND order_ext = @order_ext
                               AND user_hold <> 'Y';
                END;
            IF @iscons = 1
                BEGIN
                    IF EXISTS (   SELECT 1
                                  FROM   tdc_soft_alloc_tbl SA (nolock)
                                         JOIN dbo.cvo_masterpack_consolidation_det AS cmcd ON cmcd.order_no = SA.order_no
                                                                                              AND cmcd.order_ext = SA.order_ext
                                  WHERE  cmcd.consolidation_no = @order_no
                                         AND SA.user_hold <> 'Y' )
                        UPDATE SA WITH ( ROWLOCK )
                        SET    user_hold = 'Y'
                        FROM   dbo.tdc_soft_alloc_tbl SA WITH ( ROWLOCK )
                               JOIN dbo.cvo_masterpack_consolidation_det AS cmcd ON cmcd.order_no = SA.order_no
                                                                                    AND cmcd.order_ext = SA.order_ext
                        WHERE  cmcd.consolidation_no = @order_no
                               AND SA.user_hold <> 'Y';
                END;


            -- write to cart pick table ?
            IF NOT EXISTS (   SELECT 1
                              FROM   dbo.cvo_cart_scan_orders (NOLOCK)
                              WHERE  order_no = @cart_order_no )
               AND NOT EXISTS (   SELECT 1
                                  FROM   dbo.cvo_cart_order_parts (nolock)
                                  WHERE  order_no = @cart_order_no )
                BEGIN
                    SELECT @order_type = CASE WHEN @isxfer = 1 THEN 'XF'
                                              ELSE user_category
                                         END
                    FROM   orders
                    WHERE  order_no = @order_no
                           AND ext = @order_ext;
                    --INSERT cvo_cart_scan_orders (order_no, scan_date, scan_user, order_status, user_category)
                    INSERT cvo_cart_scan_orders ( order_no ,
                                                  scan_date ,
                                                  cart_no ,
                                                  order_status ,
                                                  user_category )
                    VALUES ( @cart_order_no ,
                             GETDATE(),
                             @cart_no ,
                             'I' ,
                             ISNULL(@order_type, 'ST'));
                    INSERT cvo_cart_order_parts
                    -- (tran_id, order_no, part_no, user_login, bin_no, upc_code, qty_to_process, scanned, isskipped, bin_group_code, TYPE_CODE)
                    (   tran_id ,
                        order_no ,
                        part_no ,
                        cart_no ,
                        bin_no ,
                        upc_code ,
                        qty_to_process ,
                        scanned ,
                        isSkipped ,
                        bin_group_code ,
                        type_code )
                           SELECT DISTINCT p.tran_id ,
                                  @cart_order_no ,
                                  p.part_no ,
                                  @cart_no ,
                                  p.bin_no ,
                                  i.upc_code ,
                                  p.qty_to_process ,
                                  0 ,
                                  0 ,
                                  bin.group_code ,
                                  i.type_code
                           FROM   dbo.tdc_pick_queue p ( NOLOCK )
                                  JOIN dbo.inv_master i ( NOLOCK ) ON i.part_no = p.part_no
                                  JOIN tdc_bin_master bin ( NOLOCK ) ON bin.bin_no = p.bin_no
                                                                        AND bin.location = p.location
                           WHERE  (   @iscons = 0
                                      AND p.trans_type_no = @order_no
                                      AND p.trans_type_ext = @order_ext )
                                  OR (   @iscons = 1
                                         AND p.mp_consolidation_no = @order_no );
                END;

            -- put the order in Open/Pick status
            SELECT @status = 'P';

            IF @isorder = 1
                BEGIN
                    UPDATE orders WITH ( ROWLOCK )
                    SET    status = @status ,
                           printed = @status ,
                           who_picked = @who ,
                           date_shipped = NULL ,
                           freight = tot_ord_freight
                    WHERE  order_no = @order_no
                           AND ext = @order_ext
                           AND status <> @status;

                    IF @ROWS <> 0
                        INSERT INTO tdc_log WITH ( ROWLOCK ) ( tran_date ,
                                                               UserID ,
                                                               trans_source ,
                                                               module ,
                                                               trans ,
                                                               tran_no ,
                                                               tran_ext ,
                                                               part_no ,
                                                               lot_ser ,
                                                               bin_no ,
                                                               location ,
                                                               quantity ,
                                                               data )
                                    SELECT GETDATE() ,
                                           'PICK CART' ,
                                           'VB' ,
                                           'PLW' ,
                                           'CHECK IN' ,
                                           a.order_no ,
                                           a.ext ,
                                           '' ,
                                           '' ,
                                           '' ,
                                           a.location ,
                                           '' ,
                                           'CHECK IN ORDER TO CART '
                                           + @cart_no
                                    FROM   orders_all a ( NOLOCK )
                                    WHERE  a.order_no = @order_no
                                           AND a.ext = @order_ext;
                END;


            IF @iscons = 1
                BEGIN
                    UPDATE o WITH ( ROWLOCK )
                    SET    o.status = @status ,
                           printed = @status ,
                           who_picked = @who ,
                           date_shipped = NULL ,
                           freight = tot_ord_freight
                    FROM   orders o WITH ( ROWLOCK )
                           JOIN dbo.cvo_masterpack_consolidation_det AS cmcd ON cmcd.order_no = o.order_no
                                                                                AND cmcd.order_ext = o.ext
                    WHERE  cmcd.consolidation_no = @order_no
                           AND o.status <> @status
                           AND o.status < 'T'; -- 3/10/16 - IGNORE VOIDS AND COMPLETED ORDERS

                    IF @ROWS <> 0
                        INSERT INTO tdc_log WITH ( ROWLOCK ) ( tran_date ,
                                                               UserID ,
                                                               trans_source ,
                                                               module ,
                                                               trans ,
                                                               tran_no ,
                                                               tran_ext ,
                                                               part_no ,
                                                               lot_ser ,
                                                               bin_no ,
                                                               location ,
                                                               quantity ,
                                                               data )
                                    SELECT GETDATE() ,
                                           'PICK CART' ,
                                           'VB' ,
                                           'PLW' ,
                                           'CHECK IN' ,
                                           o.order_no ,
                                           o.ext ,
                                           '' ,
                                           '' ,
                                           '' ,
                                           o.location ,
                                           '' ,
                                           'CHECK IN CONS '
                                           + CAST(@order_no AS VARCHAR(6))
                                           + ' TO CART ' + @cart_no
                                    FROM   orders o WITH ( ROWLOCK )
                                           JOIN dbo.cvo_masterpack_consolidation_det AS cmcd (NOLOCK) ON cmcd.order_no = o.order_no
                                                                                                AND cmcd.order_ext = o.ext
                                    WHERE  cmcd.consolidation_no = @order_no
                                           AND o.status <> @status
                                           AND o.status < 'T'; -- 3/10/16 - IGNORE VOIDS AND COMPLETED ORDERS
                END;

            IF @isxfer = 1
                BEGIN
					
                    UPDATE xfers_all WITH ( ROWLOCK )
                    SET    status = 'Q' ,
                           printed = 'Q' ,
                           who_picked = @who ,
                           date_shipped = NULL
                    WHERE  xfer_no = @order_no
                           AND status <> @status;

                    IF @ROWS <> 0
                        INSERT INTO tdc_log WITH ( ROWLOCK ) ( tran_date ,
                                                               UserID ,
                                                               trans_source ,
                                                               module ,
                                                               trans ,
                                                               tran_no ,
                                                               tran_ext ,
                                                               part_no ,
                                                               lot_ser ,
                                                               bin_no ,
                                                               location ,
                                                               quantity ,
                                                               data )
                                    SELECT GETDATE() ,
                                           'PICK CART' ,
                                           'VB' ,
                                           'PLW' ,
                                           'CHECK IN' ,
                                           a.xfer_no ,
                                           0 ,
                                           '' ,
                                           '' ,
                                           '' ,
                                           a.from_loc ,
                                           '' ,
                                           'CHECK IN XFER TO CART '
                                           + @cart_no
                                    FROM   dbo.xfers_all AS a ( NOLOCK )
                                    WHERE  a.xfer_no = @order_no;
                END;

        END;


    IF @proc_option = 1
        BEGIN
            -- order check out from cart when picks complete

            -- release holds
            IF EXISTS (   SELECT 1
                          FROM   dbo.tdc_pick_queue (NOLOCK)
                          WHERE  (   (   @iscons = 0
                                         AND trans_type_no = @order_no
                                         AND trans_type_ext = @order_ext )
                                     OR (   @iscons = 1
                                            AND mp_consolidation_no = @order_no ))
                                 AND tx_lock <> 'R' )
                UPDATE tdc_pick_queue WITH ( ROWLOCK )
                SET    tx_lock = 'R' ,
                       mfg_batch = NULL
                WHERE  (   (   @iscons = 0
                               AND trans_type_no = @order_no
                               AND trans_type_ext = @order_ext )
                           OR (   @iscons = 1
                                  AND mp_consolidation_no = @order_no ))
                       AND tx_lock <> 'R';
            SELECT @ROWS = @@ROWCOUNT;

            IF ( @iscons = 0 )
                BEGIN
                    IF EXISTS (   SELECT 1
                                  FROM   dbo.tdc_soft_alloc_tbl AS tsat (NOLOCK)
                                  WHERE  order_no = @order_no
                                         AND order_ext = @order_ext
                                         AND user_hold <> 'N' )
                        UPDATE dbo.tdc_soft_alloc_tbl WITH ( ROWLOCK )
                        SET    user_hold = 'N'
                        WHERE  order_no = @order_no
                               AND order_ext = @order_ext
                               AND user_hold <> 'N';
                    IF @ROWS <> 0
                       AND @isorder = 1
                        INSERT INTO tdc_log WITH ( ROWLOCK ) ( tran_date ,
                                                               UserID ,
                                                               trans_source ,
                                                               module ,
                                                               trans ,
                                                               tran_no ,
                                                               tran_ext ,
                                                               part_no ,
                                                               lot_ser ,
                                                               bin_no ,
                                                               location ,
                                                               quantity ,
                                                               data )
                                    SELECT GETDATE() ,
                                           'PICK CART' ,
                                           'VB' ,
                                           'PLW' ,
                                           'CHECK OUT' ,
                                           a.order_no ,
                                           a.ext ,
                                           '' ,
                                           '' ,
                                           '' ,
                                           a.location ,
                                           '' ,
                                           'CHECK OUT ORDER'
                                    FROM   orders_all a ( NOLOCK )
                                    WHERE  a.order_no = @order_no
                                           AND a.ext = @order_ext;

                    IF @ROWS <> 0
                       AND @isxfer = 1
                        INSERT INTO tdc_log WITH ( ROWLOCK ) ( tran_date ,
                                                               UserID ,
                                                               trans_source ,
                                                               module ,
                                                               trans ,
                                                               tran_no ,
                                                               tran_ext ,
                                                               part_no ,
                                                               lot_ser ,
                                                               bin_no ,
                                                               location ,
                                                               quantity ,
                                                               data )
                                    SELECT GETDATE() ,
                                           'PICK CART' ,
                                           'VB' ,
                                           'PLW' ,
                                           'CHECK OUT' ,
                                           a.xfer_no ,
                                           0 ,
                                           '' ,
                                           '' ,
                                           '' ,
                                           a.from_loc ,
                                           '' ,
                                           'CHECK OUT ORDER'
                                    FROM   dbo.xfers_all a ( NOLOCK )
                                    WHERE  a.xfer_no = @order_no;

                END;

            IF ( @iscons = 1 )
                BEGIN

                    IF EXISTS (   SELECT 1
                                  FROM   dbo.tdc_soft_alloc_tbl SA WITH ( ROWLOCK )
                                         JOIN dbo.cvo_masterpack_consolidation_det AS cmcd ON cmcd.order_no = SA.order_no
                                                                                              AND cmcd.order_ext = SA.order_ext
                                  WHERE  cmcd.consolidation_no = @order_no
                                         AND SA.user_hold <> 'N' )
                        UPDATE SA WITH ( ROWLOCK )
                        SET    user_hold = 'N'
                        FROM   dbo.tdc_soft_alloc_tbl SA WITH ( ROWLOCK )
                               JOIN dbo.cvo_masterpack_consolidation_det AS cmcd ON cmcd.order_no = SA.order_no
                                                                                    AND cmcd.order_ext = SA.order_ext
                        WHERE  cmcd.consolidation_no = @order_no
                               AND SA.user_hold <> 'N';
                    SELECT @ROWS = @@ROWCOUNT;

                    IF @ROWS <> 0
                        INSERT INTO tdc_log WITH ( ROWLOCK ) ( tran_date ,
                                                               UserID ,
                                                               trans_source ,
                                                               module ,
                                                               trans ,
                                                               tran_no ,
                                                               tran_ext ,
                                                               part_no ,
                                                               lot_ser ,
                                                               bin_no ,
                                                               location ,
                                                               quantity ,
                                                               data )
                                    SELECT GETDATE() ,
                                           'PICK CART' ,
                                           'VB' ,
                                           'PLW' ,
                                           'CHECK OUT' ,
                                           o.order_no ,
                                           o.ext ,
                                           '' ,
                                           '' ,
                                           '' ,
                                           o.location ,
                                           '' ,
                                           'CHECK OUT CONS '
                                           + CAST(@order_no AS VARCHAR(6))
                                    FROM   orders o WITH ( ROWLOCK )
                                           JOIN dbo.cvo_masterpack_consolidation_det AS cmcd ON cmcd.order_no = o.order_no
                                                                                                AND cmcd.order_ext = o.ext
                                    WHERE  cmcd.consolidation_no = @order_no
                                           AND o.status <> @status
                                           AND o.status < 'T'; -- 3/10/16 - IGNORE VOIDS AND COMPLETED ORDERS
                END;


            SELECT @tran_id = MIN(p.tran_id)
            FROM   tdc_pick_queue p (NOLOCK)
            WHERE  (   @iscons = 0
                       AND trans_type_no = @order_no
                       AND trans_type_ext = @order_ext )
                   OR (   @iscons = 1
                          AND p.mp_consolidation_no = @order_no );

            WHILE @tran_id IS NOT NULL
                BEGIN

                    SELECT @line_no = line_no ,
                           @qty_to_process = qty_to_process -- change to qty_processed later  
                    FROM   tdc_pick_queue ( NOLOCK )
                    WHERE  tran_id = @tran_id;

                    SELECT @qty = CASE WHEN scanned > @qty_to_process THEN
                                           @qty_to_process
                                       ELSE scanned
                                  END
                    FROM   dbo.cvo_cart_parts_processed (NOLOCK)
                    WHERE  @tran_id = tran_id;

                    -- make sure there are still allocations on the consolidation

                    IF @iscons = 1
                       AND NOT EXISTS (   SELECT 1
                                          FROM   dbo.tdc_soft_alloc_tbl SA WITH ( ROWLOCK )
                                                 JOIN dbo.cvo_masterpack_consolidation_det AS cmcd (NOLOCK) ON cmcd.order_no = SA.order_no
                                                                                                      AND cmcd.order_ext = SA.order_ext
                                          WHERE  cmcd.consolidation_no = @order_no )
                        SELECT @qty = 0;

                    IF ISNULL(@qty, 0) > 0
                        BEGIN
                            IF @isorder = 1
                                EXEC dbo.cvo_autopick_line_sp @tran_id ,     -- int
                                                              @order_no ,    -- int
                                                              @order_ext ,   -- int
                                                              @line_no ,     -- int
                                                              @qty ,         -- decimal
                                                              @station_id ,  -- int
                                                              @user_id = ''; -- varchar(50)

                            IF @iscons = 1
                                EXEC dbo.cvo_masterpack_pick_consolidated_transaction_sp @tran_id ,
                                                                                         @qty ,
                                                                                         0 ,
                                                                                         ''; -- user_id

                            IF @isxfer = 1
                                EXEC dbo.cvo_autopick_xfer_line_sp @tran_id ,
                                                                   @order_no ,
                                                                   @qty;


                            UPDATE PP WITH ( ROWLOCK )
                            SET    isPicked = 'Y' ,
                                   PP.pick_complete_dt = @asofdate
                            FROM   cvo_cart_parts_processed PP
                            WHERE  tran_id = @tran_id
                                   AND isPicked <> 'y';

                        END;

                    UPDATE dbo.cvo_cart_orders_processed WITH ( ROWLOCK )
                    SET    order_status = 'C' ,
                           processed_date = @asofdate
                    WHERE  order_no = @cart_order_no;


                    SELECT @tran_id = MIN(p.tran_id)
                    FROM   tdc_pick_queue p (NOLOCK)
                    WHERE  (   (   @iscons = 0
                                   AND trans_type_no = @order_no
                                   AND trans_type_ext = @order_ext )
                               OR (   @iscons = 1
                                      AND p.mp_consolidation_no = @order_no ))
                           AND p.tran_id > @tran_id;

                END; -- processing loop
        END; -- proc_option = 1

    IF @proc_option = 99
        -- void a checked in order
        BEGIN

            -- release holds
            UPDATE tdc_pick_queue WITH ( ROWLOCK )
            SET    tx_lock = 'R' ,
                   mfg_batch = NULL ,
                   user_id = ''
            WHERE  (   (   @iscons = 0
                           AND trans_type_no = @order_no
                           AND trans_type_ext = @order_ext )
                       OR (   @iscons = 1
                              AND mp_consolidation_no = @order_no ))
                   AND tx_lock <> 'R';
            SELECT @ROWS = @@ROWCOUNT;

            IF ( @iscons = 0 )
                BEGIN
                    UPDATE dbo.tdc_soft_alloc_tbl WITH ( ROWLOCK )
                    SET    user_hold = 'N'
                    WHERE  order_no = @order_no
                           AND order_ext = @order_ext
                           AND user_hold <> 'N';

                    IF @ROWS <> 0
                       AND @isorder = 1
                        INSERT INTO tdc_log WITH ( ROWLOCK ) ( tran_date ,
                                                               UserID ,
                                                               trans_source ,
                                                               module ,
                                                               trans ,
                                                               tran_no ,
                                                               tran_ext ,
                                                               part_no ,
                                                               lot_ser ,
                                                               bin_no ,
                                                               location ,
                                                               quantity ,
                                                               data )
                                    SELECT GETDATE() ,
                                           'PICK CART' ,
                                           'VB' ,
                                           'PLW' ,
                                           'CHECK IN VOID' ,
                                           a.order_no ,
                                           a.ext ,
                                           '' ,
                                           '' ,
                                           '' ,
                                           a.location ,
                                           '' ,
                                           'VOID CHECK IN ORDER TO CART '
                                           + @cart_no
                                    FROM   orders_all a ( NOLOCK )
                                    WHERE  a.order_no = @order_no
                                           AND a.ext = @order_ext;

                    IF @ROWS <> 0
                       AND @isxfer = 1
                        INSERT INTO tdc_log WITH ( ROWLOCK ) ( tran_date ,
                                                               UserID ,
                                                               trans_source ,
                                                               module ,
                                                               trans ,
                                                               tran_no ,
                                                               tran_ext ,
                                                               part_no ,
                                                               lot_ser ,
                                                               bin_no ,
                                                               location ,
                                                               quantity ,
                                                               data )
                                    SELECT GETDATE() ,
                                           'PICK CART' ,
                                           'VB' ,
                                           'PLW' ,
                                           'CHECK IN VOID' ,
                                           a.xfer_no ,
                                           0 ,
                                           '' ,
                                           '' ,
                                           '' ,
                                           a.from_loc ,
                                           '' ,
                                           'VOID CHECK IN XFER TO CART '
                                           + @cart_no
                                    FROM   xfers_all a ( NOLOCK )
                                    WHERE  a.xfer_no = @order_no;

                END;

            IF ( @iscons = 1 )
                BEGIN
                    UPDATE SA
                    SET    user_hold = 'N'
                    FROM   dbo.tdc_soft_alloc_tbl SA WITH ( ROWLOCK )
                           JOIN dbo.cvo_masterpack_consolidation_det AS cmcd ON cmcd.order_no = SA.order_no
                                                                                AND cmcd.order_ext = SA.order_ext
                    WHERE  cmcd.consolidation_no = @order_no
                           AND SA.user_hold <> 'N';

                    INSERT INTO tdc_log WITH ( ROWLOCK ) ( tran_date ,
                                                           UserID ,
                                                           trans_source ,
                                                           module ,
                                                           trans ,
                                                           tran_no ,
                                                           tran_ext ,
                                                           part_no ,
                                                           lot_ser ,
                                                           bin_no ,
                                                           location ,
                                                           quantity ,
                                                           data )
                                SELECT GETDATE() ,
                                       'PICK CART' ,
                                       'VB' ,
                                       'PLW' ,
                                       'CHECK IN VOID' ,
                                       o.order_no ,
                                       o.ext ,
                                       '' ,
                                       '' ,
                                       '' ,
                                       o.location ,
                                       '' ,
                                       'VOID CHECK IN CONS '
                                       + CAST(@order_no AS VARCHAR(6))
                                       + ' TO CART ' + @cart_no
                                FROM   orders o WITH ( ROWLOCK )
                                       JOIN dbo.cvo_masterpack_consolidation_det AS cmcd ON cmcd.order_no = o.order_no
                                                                                            AND cmcd.order_ext = o.ext
                                WHERE  cmcd.consolidation_no = @order_no
                                       AND o.status <> @status
                                       AND o.status < 'T'; -- 3/10/16 - IGNORE VOIDS AND COMPLETED ORDERS
                END;

            DELETE FROM dbo.cvo_cart_order_parts
            WHERE order_no = @cart_order_no;
            DELETE FROM dbo.cvo_cart_scan_orders
            WHERE order_no = @cart_order_no;


            -- put the order back in Open/Print status
            SELECT @status = 'Q';

            IF @isorder = 1
                UPDATE orders WITH ( ROWLOCK )
                SET    status = @status ,
                       printed = @status ,
                       who_picked = @who ,
                       date_shipped = NULL ,
                       freight = tot_ord_freight
                WHERE  order_no = @order_no
                       AND ext = @order_ext
                       AND status <> @status
                       AND (   SELECT SUM(shipped)
                               FROM   ord_list OL
                               WHERE  OL.order_no = @order_no
                                      AND OL.order_ext = @order_ext ) = 0;

            IF @isxfer = 1
                UPDATE dbo.xfers_all WITH ( ROWLOCK )
                SET    status = @status ,
                       printed = @status ,
                       who_picked = @who ,
                       date_shipped = NULL
                WHERE  xfer_no = @order_no
                       AND status <> @status
                       AND (   SELECT SUM(shipped)
                               FROM   dbo.xfer_list oL
                               WHERE  oL.xfer_no = @order_no ) = 0;

            IF @iscons = 1
                UPDATE o WITH ( ROWLOCK )
                SET    o.status = @status ,
                       printed = @status ,
                       who_picked = @who ,
                       date_shipped = NULL ,
                       freight = tot_ord_freight
                FROM   orders o WITH ( ROWLOCK )
                       JOIN dbo.cvo_masterpack_consolidation_det AS cmcd ON cmcd.order_no = o.order_no
                                                                            AND cmcd.order_ext = o.ext
                WHERE  cmcd.consolidation_no = @order_no
                       AND o.status <> @status
                       AND o.status < 'T'
                       AND (   SELECT SUM(shipped)
                               FROM   ord_list OL
                               WHERE  OL.order_no = o.order_no
                                      AND OL.order_ext = o.ext ) = 0;

        END; -- proc_option = 99























GO
