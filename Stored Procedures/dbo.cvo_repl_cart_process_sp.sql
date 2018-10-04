SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_repl_cart_process_sp]
(
    @tran_id INT
)
AS
BEGIN

    -- @proc_options - 
    --				   1 = CHECK-OUT a completed replenishment

	-- EXEC cvo_repl_cart_process_sp 32136823

    -- Change History
    -- 7/6/2018 - support for Ipod replenishment process


    SET NOCOUNT ON;
    SET ANSI_WARNINGS OFF;

    DECLARE @qty DECIMAL(20, 8),
            @ROWS INT,
            @station_id INT,
            @user_id VARCHAR(50),
            @tdc_string VARCHAR(255);

    SELECT @station_id = 777;


    IF NOT EXISTS (SELECT 1 FROM dbo.tdc_pick_queue AS tpq WHERE tpq.tran_id = @tran_id AND trans = 'MGTB2B')
    BEGIN
        SELECT 'QTran_id not found',
               @tran_id;
        RETURN -1;
    END;


    CREATE TABLE #temp_who
    (
        who VARCHAR(50) NOT NULL,
        login_id VARCHAR(50) NOT NULL
    );

    INSERT #temp_who
    (
        who,
        login_id
    )
    VALUES
    ('manager', 'manager');

    IF (OBJECT_ID('tempdb.dbo.#err') IS NOT NULL)
        DROP TABLE #err;
    CREATE TABLE #err
    (
        tran_id INT,
        msg VARCHAR(255)
    );

    IF
    (
    SELECT OBJECT_ID('tempdb..#adm_bin_xfer')
    ) IS NOT NULL
    BEGIN
        DROP TABLE #adm_bin_xfer;
    END;

    CREATE TABLE #adm_bin_xfer
    (
        issue_no INT NULL,
        location VARCHAR(10) NOT NULL,
        part_no VARCHAR(30) NOT NULL,
        lot_ser VARCHAR(25) NOT NULL,
        bin_from VARCHAR(12) NOT NULL,
        bin_to VARCHAR(12) NOT NULL,
        date_expires DATETIME NOT NULL,
        qty DECIMAL(20, 8) NOT NULL,
        who_entered VARCHAR(50) NOT NULL,
        reason_code VARCHAR(10) NULL,
        err_msg VARCHAR(255) NULL,
        row_id INT IDENTITY NOT NULL
    );

        -- order check out from cart when picks complete

        IF NOT EXISTS
        (
        SELECT 1
        FROM dbo.cvo_cart_replenish_queue AS crq
        JOIN dbo.tdc_pick_queue AS tpq
                ON tpq.tran_id = crq.tran_id
        WHERE crq.tran_id = @tran_id
              ANd
              (isPicked = 1
              OR isPut = 1
              OR isSkipped = 0)
        )
        BEGIN
            SELECT 'QTran_id not fully picked and putaway or not found',
                   @tran_id;
            RETURN -1;
        END;

        UPDATE dbo.tdc_pick_queue WITH
            (ROWLOCK)
        SET tx_lock = 'R'
        WHERE tran_id = @tran_id
              AND tx_lock <> 'R';


        -- do the bin to bin transfer

        INSERT INTO #adm_bin_xfer
        (
            issue_no,
            location,
            part_no,
            lot_ser,
            bin_from,
            bin_to,
            date_expires,
            qty,
            who_entered,
            reason_code,
            err_msg
        )
        SELECT NULL,
               tpq.location,
               crq.part_no,
               lb.lot_ser,
               crq.source_bin,
               crq.target_bin,
               CONVERT(VARCHAR(12), lb.date_expires, 109),
               crq.target_put,
               put_user,
               NULL,
               NULL
        FROM dbo.cvo_cart_replenish_queue AS crq
            JOIN dbo.tdc_pick_queue AS tpq
                ON tpq.tran_id = crq.tran_id
            JOIN lot_bin_stock AS lb
                ON lb.part_no = tpq.part_no
                   AND lb.location = tpq.location
                   AND lb.bin_no = tpq.bin_no
        WHERE crq.tran_id = @tran_id;

        EXEC tdc_bin_xfer;

        IF
        (
        SELECT OBJECT_ID('tempdb..#adm_bin_xfer')
        ) IS NOT NULL
        BEGIN
            DROP TABLE #adm_bin_xfer;
        END;


        -- write to the t-log

        INSERT INTO tdc_log
        (
            tran_date,
            UserID,
            trans_source,
            module,
            trans,
            tran_no,
            tran_ext,
            part_no,
            lot_ser,
            bin_no,
            location,
            quantity,
            data
        )
        SELECT crq.put_time,
               cu.user_login,
               'CO',
               'QTX',
               'QBN2BN',
               crq.tran_id,
               '',
               crq.part_no,
               '1',
               crq.target_bin,
               tpq.location,
               crq.target_put,
               dbo.f_create_tdc_log_bin2bin_data_string(crq.put_user, crq.target_put, crq.target_bin)
        FROM dbo.cvo_cart_replenish_queue AS crq
            JOIN tdc_pick_queue tpq
                ON tpq.tran_id = crq.tran_id
                LEFT OUTER JOIN cvo_cmi_users cu ON crq.put_user = cu.fname + ' ' + cu.lname 
        WHERE crq.tran_id = @tran_id
        UNION ALL
        SELECT crq.pick_time,
               cu.user_login,
               'CO',
               'QTX',
               'QBN2BN',
               crq.tran_id,
               '',
               crq.part_no,
               '1',
               crq.source_bin,
               tpq.location,
               crq.source_pick,
               dbo.f_create_tdc_log_bin2bin_data_string(crq.pick_user, crq.pick_qty, crq.source_bin)
        FROM dbo.cvo_cart_replenish_queue AS crq
            JOIN tdc_pick_queue tpq
                ON tpq.tran_id = crq.tran_id
                LEFT OUTER JOIN cvo_cmi_users cu ON crq.pick_user = cu.fname + ' ' + cu.lname 
        WHERE crq.tran_id = @tran_id;

        -- remove the pick from the queue

        SELECT @qty = target_put
        FROM dbo.cvo_cart_replenish_queue AS crq
        WHERE crq.tran_id = @tran_id;
        EXEC tdc_update_queue_sp @tran_id, @qty, 0;


END; -- procedure




GO
GRANT EXECUTE ON  [dbo].[cvo_repl_cart_process_sp] TO [public]
GO
