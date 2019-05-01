SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[CVO_adhoc_cases_credit_returns_sp]
AS

-- 04/24/2019 - based on CVO_ADHOC_revo_packaging_sp
-- select * From lot_bin_stock where bin_no = 'f01a-os-os'

BEGIN
    SET NOCOUNT ON;

    DECLARE @BIN VARCHAR(10),
            @LOC VARCHAR(10);
    DECLARE @QTY_TO_ADJUST INT,
            @last_upd DATETIME;

    -- first do the adjustments in 001

    SET @BIN = 'F01A-OS-OS';
    SET @LOC = '001';

    IF NOT EXISTS (SELECT * FROM config WHERE flag = 'CVO_CASE_CR_UPD')
        INSERT dbo.config
        (
            flag,
            description,
            value_str,
            flag_class
        )
        VALUES
        (   'CVO_CASE_CR_UPD',                 -- flag - varchar(20)
            'Last update of Cases on Credits', -- description - varchar(40)
            '1/1/1900',                           -- value_str - varchar(40)
            'misc'                             -- flag_class - varchar(10)
            );

    -- SELECT  *   FROM config WHERE flag = 'CVO_CASE_CR_UPD';
    -- SELECT * FROM orders WHERE order_no = 3473407

    SELECT @last_upd = ISNULL(CAST(value_str AS DATETIME), '1/1/1900')
    FROM config
    WHERE flag = 'CVO_CASE_CR_UPD';

    UPDATE config
    SET value_str = CONVERT(VARCHAR(20), GETDATE(), 109)
    WHERE flag = 'CVO_CASE_CR_UPD';


    -- 8700T212D40242c

    /*  Set up adhoc - in TO BIN = Transfer*/

    IF
    (
        SELECT OBJECT_ID('tempdb..#temp_part_list')
    ) IS NOT NULL
    BEGIN
        DROP TABLE #temp_part_list;
    END;

    CREATE TABLE #temp_part_list
    (
        id INT IDENTITY,
        location VARCHAR(12),
        bin_no VARCHAR(12),
        part_no VARCHAR(30) NOT NULL,
        qty DECIMAL(20, 8) NOT NULL,
        direction INT NOT NULL
    );


    INSERT INTO #temp_part_list
    SELECT @LOC,
           @BIN,
           ol.part_no,
           SUM(ol.cr_shipped) shipped,
           1
    FROM inv_master i (NOLOCK)
        JOIN ord_list ol (NOLOCK)
            ON ol.part_no = i.part_no
        JOIN orders o (NOLOCK)
            ON o.order_no = ol.order_no
               AND o.ext = ol.order_ext
    WHERE i.type_code = 'case'
          AND o.type = 'c'
          AND o.status = 't'
          AND o.date_shipped > @last_upd
          AND ol.return_code = '01-01'
    GROUP BY ol.part_no;

    IF @@ROWCOUNT > 0
    BEGIN
        --re
        IF
        (
            SELECT OBJECT_ID('tempdb..#adm_inv_adj')
        ) IS NOT NULL
        BEGIN
            DROP TABLE #adm_inv_adj;
        END;

        CREATE TABLE #adm_inv_adj
        (
            adj_no INT NULL,
            loc VARCHAR(10) NOT NULL,
            part_no VARCHAR(30) NOT NULL,
            bin_no VARCHAR(12) NULL,
            lot_ser VARCHAR(25) NULL,
            date_exp DATETIME NULL,
            qty DECIMAL(20, 8) NOT NULL,
            direction INT NOT NULL,
            who_entered VARCHAR(50) NOT NULL,
            reason_code VARCHAR(10) NULL,
            code VARCHAR(8) NOT NULL,
            cost_flag CHAR(1) NULL,
            avg_cost DECIMAL(20, 8) NULL,
            direct_dolrs DECIMAL(20, 8) NULL,
            ovhd_dolrs DECIMAL(20, 8) NULL,
            util_dolrs DECIMAL(20, 8) NULL,
            err_msg VARCHAR(255) NULL,
            row_id INT IDENTITY NOT NULL
        );

        -- SELECT * FROM #ADM_INV_ADJ

        IF
        (
            SELECT OBJECT_ID('tempdb..#temp_who')
        ) IS NOT NULL
        BEGIN
            DROP TABLE #temp_who;
        END;
        CREATE TABLE #temp_who
        (
            who VARCHAR(50),
            login_id VARCHAR(50)
        );
        INSERT #temp_who
        SELECT 'tdcsql',
               'tdcsql';

        -- SELECT * FROM #TEMP_PART_LIST

        ---  do the processing

        DECLARE @LOCATION VARCHAR(12),
                @BIN_NO VARCHAR(12),
                @PART_NO VARCHAR(30),
                @ERR INT,
                @ID INT,
                @direction INT,
                @adhoc_tolerance VARCHAR(10);

        SELECT @adhoc_tolerance = value_str
        FROM tdc_config
        WHERE [function] = 'ADHOC_ADJUST_TOLERANCE';

        --	LOOP HERE UNTIL TEMP_PART_LIST IS EMPTY
        SELECT @ID = MIN(id)
        FROM #temp_part_list;
        WHILE @ID IS NOT NULL
        BEGIN
            SELECT TOP 1
                   @LOCATION = location,
                   @BIN_NO = bin_no,
                   @PART_NO = part_no,
                   @QTY_TO_ADJUST = qty,
                   @direction = direction
            FROM #temp_part_list
            WHERE id = @ID;

            -- SELECT @ID

            TRUNCATE TABLE #adm_inv_adj;

            IF @direction = 1
            BEGIN
                INSERT INTO #adm_inv_adj
                (
                    loc,
                    part_no,
                    bin_no,
                    lot_ser,
                    date_exp,
                    qty,
                    direction,
                    who_entered,
                    reason_code,
                    code
                )
                SELECT @LOCATION,
                       @PART_NO,
                       @BIN_NO,
                       '1',
                       CONVERT(VARCHAR(12), DATEADD(yy, 1, GETDATE()), 109),
                       @QTY_TO_ADJUST,
                       @direction,
                       'tdcsql',
                       'ADJ-ADHOC',
                       'ADHOC';
            END;

            IF @QTY_TO_ADJUST > @adhoc_tolerance
            BEGIN
                UPDATE tdc_config
                SET value_str = @QTY_TO_ADJUST + 1
                WHERE [function] = 'ADHOC_ADJUST_TOLERANCE';
                EXEC @ERR = tdc_adm_inv_adj;
                UPDATE tdc_config
                SET value_str = @adhoc_tolerance
                WHERE [function] = 'ADHOC_ADJUST_TOLERANCE';
            END;
            ELSE
                EXEC @ERR = tdc_adm_inv_adj;

            -- SELECT @err

            IF (@ERR < 0)
            BEGIN
                IF (@@trancount > 0)
                    ROLLBACK TRAN;
            END;

            SELECT @ID = MIN(id)
            FROM #temp_part_list
            WHERE id > @ID;
        END;

    END;
END;





GO
GRANT EXECUTE ON  [dbo].[CVO_adhoc_cases_credit_returns_sp] TO [public]
GO
