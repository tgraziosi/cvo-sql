SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_cyc_count_update_wrap_sp]
AS
BEGIN

    -- SELECT * FROM dbo.tdc_cyc_count_user_filter_set AS tccufs
    -- UPDATE dbo.tdc_cyc_count_user_filter_set SET userid = 'CC', UPDATE_METHOD = 1 WHERE USERID IN ('CC','MANAGER')

    SET NOCOUNT ON;
    SET ANSI_WARNINGS OFF;


    IF (OBJECT_ID('tempdb..#tdc_cyc_master') IS NOT NULL)
        DROP TABLE #tdc_cyc_master;

    IF (OBJECT_ID('tempdb..#tmp_phy_cyc_count') IS NOT NULL)
        DROP TABLE #tmp_phy_cyc_count;

    IF (OBJECT_ID('tempdb..#tdc_cyc_SN') IS NOT NULL)
        DROP TABLE #tdc_cyc_SN;

    IF (OBJECT_ID('tempdb..#adm_inv_adj') IS NOT NULL)
        DROP TABLE #adm_inv_adj;

    IF (OBJECT_ID('tempdb..#cyc_count_allocated_parts') IS NOT NULL)
        DROP TABLE #cyc_count_allocated_parts;

    CREATE TABLE #tdc_cyc_master
    (
        location VARCHAR(10) NOT NULL,
        part_no VARCHAR(30) NOT NULL,
        lb_tracking VARCHAR(2) NOT NULL,
        lot_ser VARCHAR(25) NULL,
        bin_no VARCHAR(12) NULL,
        erp_current_qty DECIMAL(20, 8) NULL,
        erp_qty_at_count DECIMAL(20, 8) NULL,
        post_qty DECIMAL(20, 8) NULL,
        post_ver INT NULL,
        changed_flag INT NOT NULL
            DEFAULT 0,
        cost VARCHAR(30) NULL,
        curr_key VARCHAR(4) NULL,
        difference DECIMAL(20, 0) NOT NULL
            DEFAULT 0
    );

    CREATE TABLE #tmp_phy_cyc_count
    (
        team_id VARCHAR(30) NOT NULL,
        userid VARCHAR(50) NULL,
        cyc_code VARCHAR(10) NOT NULL,
        location VARCHAR(10) NOT NULL,
        part_no VARCHAR(30) NOT NULL,
        lot_ser VARCHAR(25) NULL,
        bin_no VARCHAR(12) NULL,
        adm_actual_qty DECIMAL(20, 8) NULL,
        count_date DATETIME NULL,
        count_qty DECIMAL(20, 8) NULL,
        post_qty DECIMAL(20, 8) NULL,
        post_ver INT NULL
    );

    CREATE INDEX tmp_phy_cyc_count_idx1 ON dbo.#tmp_phy_cyc_count (post_ver);

    CREATE INDEX tmp_phy_cyc_count_idx2
    ON dbo.#tmp_phy_cyc_count (
                              location,
                              part_no,
                              lot_ser,
                              bin_no
                              );

    CREATE INDEX tmp_phy_cyc_count_idx3
    ON dbo.#tmp_phy_cyc_count (
                              location,
                              part_no,
                              lot_ser,
                              bin_no,
                              userid
                              );

    CREATE INDEX tmp_phy_cyc_count_idx4
    ON dbo.#tmp_phy_cyc_count (
                              location,
                              part_no,
                              lot_ser,
                              bin_no,
                              post_ver
                              );

    CREATE TABLE #tdc_cyc_SN
    (
        location VARCHAR(10) NOT NULL,
        part_no VARCHAR(30) NOT NULL,
        lot_ser VARCHAR(25) NOT NULL,
        serial_no VARCHAR(40) NOT NULL,
        serial_no_raw VARCHAR(40) NOT NULL,
        direction INT NOT NULL
    );

    CREATE INDEX tdc_cyc_SN_idx1
    ON dbo.#tdc_cyc_SN (
                       part_no,
                       lot_ser,
                       direction
                       );

    CREATE INDEX tdc_cyc_SN_idx2
    ON dbo.#tdc_cyc_SN (
                       part_no,
                       lot_ser,
                       serial_no
                       );

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
        row_id INT IDENTITY NOT NULL
    );

    CREATE TABLE #cyc_count_allocated_parts
    (
        order_no INT NOT NULL,
        order_ext INT NOT NULL,
        order_type CHAR(1) NOT NULL,
        location VARCHAR(10) NOT NULL,
        part_no VARCHAR(30) NOT NULL,
        lot_ser VARCHAR(25) NULL,
        bin_no VARCHAR(12) NULL
    );

    EXEC dbo.tdc_cyc_count_temp_tables @user_id = 'CC'; -- varchar(50)

    SELECT *
    FROM #tdc_cyc_master AS tcm;
    SELECT *
    FROM #adm_inv_adj AS aia;
    SELECT *
    FROM #cyc_count_allocated_parts AS ccap;
    SELECT *
    FROM #tdc_cyc_SN AS tcs;
    SELECT *
    FROM #tmp_phy_cyc_count AS tpcc;

    UPDATE t
    SET post_qty = a.post_qty,
        post_ver = -a.post_ver,
        adm_actual_qty = erp_qty_at_count
    -- SELECT * 
    FROM #tdc_cyc_master a,
         tdc_phy_cyc_count t
    WHERE t.location = a.location
          AND t.part_no = a.part_no
          AND a.changed_flag <> 0
          AND ISNULL(t.lot_ser, '') = ISNULL(a.lot_ser, '')
          AND ISNULL(t.bin_no, '') = ISNULL(a.bin_no, '');

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
    SELECT 'manager',
           'manager';

    SET IMPLICIT_TRANSACTIONS ON;

    EXEC tdc_cyc_count_update_sp 'CC';

    IF @@TRANCOUNT > 0
        COMMIT TRAN;

    SET IMPLICIT_TRANSACTIONS OFF;

END;


GRANT EXECUTE ON cvo_cyc_count_update_wrap_sp TO PUBLIC;

GO
