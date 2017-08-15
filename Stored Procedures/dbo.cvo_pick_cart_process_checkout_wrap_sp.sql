SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_pick_cart_process_checkout_wrap_sp]
AS
SET NOCOUNT ON
;
SET ANSI_WARNINGS OFF
;

-- exec cvo_pick_cart_process_checkout_wrap_sp

DECLARE
    @station_id INT,
    @user_id VARCHAR(50),
    @tran_id INT,
    @cart_order_no VARCHAR(20),
    @order INT,
    @ext INT,
    @asofdate DATETIME,
    @status VARCHAR(1),
    @who VARCHAR(20)
;

SELECT
    @station_id = 777, @user_id = '', @asofdate = GETDATE()
;

SELECT @cart_order_no = MIN(ccop.order_no)
FROM dbo.cvo_cart_orders_processed AS ccop
WHERE
    (
        ccop.order_status = 'O'
        AND ccop.processed_date IS NULL
    )
    -- 8/5/2016 - LOOK FOR STRAY PICKS TO PROCESS
    OR EXISTS
(
    SELECT 1
    FROM dbo.cvo_cart_parts_processed AS cpp
    WHERE
        cpp.order_no = ccop.order_no
        AND cpp.scanned = 1
        AND isPicked <> 'Y'
)
;

WHILE ISNULL(@cart_order_no, '') > ''
BEGIN

    IF CHARINDEX('-', @cart_order_no, 0) > 0
    BEGIN
        SELECT @order = CAST(LEFT(@cart_order_no, CHARINDEX('-', @cart_order_no, 0) - 1) AS INT)
        ;
        SELECT @ext = SUBSTRING(@cart_order_no, CHARINDEX('-', @cart_order_no, 0) + 1, LEN(@cart_order_no))
        ;
    END
    ;
    ELSE
    BEGIN
        SELECT @order = @cart_order_no
        ;
        SELECT @ext = 0
        ;
    END
    ;

    -- SELECT @cart_order_no, @order, @ext

    IF EXISTS
    (
        SELECT 1
        FROM
            dbo.tdc_soft_alloc_tbl a
            JOIN tdc_pick_queue p
                ON a.order_no = p.trans_type_no
                   AND a.order_ext = p.trans_type_ext
                   AND p.location = a.location
                   AND p.line_no = a.line_no
                   AND p.bin_no = a.bin_no
                   AND p.part_no = a.part_no
        WHERE
            a.order_no = @order
            AND a.order_ext = @ext
    )
        EXEC dbo.cvo_pick_cart_process_sp
            @cart_no = 0, @order_no = @order, @order_ext = @ext, @proc_option = 1
        ;

    -- SELECT ' Done picking ' , @cart_order_no

    SELECT @cart_order_no = MIN(ccop.order_no)
    FROM dbo.cvo_cart_orders_processed AS ccop
    WHERE
        ccop.order_status = 'O'
        AND ccop.processed_date IS NULL
        AND ccop.order_no > @cart_order_no
    ;

END
;

-- SELECT * FROM dbo.cvo_cart_parts_processed AS ccpp WHERE ORDER_no = '13452'


GO
GRANT EXECUTE ON  [dbo].[cvo_pick_cart_process_checkout_wrap_sp] TO [public]
GO
