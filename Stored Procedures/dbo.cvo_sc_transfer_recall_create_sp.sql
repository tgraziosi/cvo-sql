SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[cvo_sc_transfer_recall_create_sp]
(
    @sdate DATETIME = NULL,
    @edate DATETIME = NULL
)
AS
BEGIN

    -- exec cvo_sc_transfer_recall_create_sp @sdate = '12/12/2017' 
    -- SELECT TOP 100 * FROM xfers_all ORDER BY xfer_no DESC


    SET NOCOUNT ON;

    DECLARE @xfer_no INT,
            @location VARCHAR(12),
            @from_loc VARCHAR(12),
            @to_loc VARCHAR(12),
            @ship_date DATETIME,
            @to_loc_name VARCHAR(40),
            @to_loc_addr1 VARCHAR(40),
            @to_loc_addr2 VARCHAR(40),
            @to_loc_addr3 VARCHAR(40),
            @to_loc_addr4 VARCHAR(40),
            @to_loc_addr5 VARCHAR(40),
            @locations_name VARCHAR(40),
            @locations_addr1 VARCHAR(40),
            @locations_addr2 VARCHAR(40),
            @locations_addr3 VARCHAR(40),
            @locations_addr4 VARCHAR(40),
            @locations_addr5 VARCHAR(40),
            @today DATETIME,
            @transfer_id INT,
            @routing VARCHAR(12),
            @attention VARCHAR(15);

    DECLARE @line_no INT,
            @part_no VARCHAR(40),
            @description VARCHAR(255),
            @allow_fractions SMALLINT,
            @cubic_feet DECIMAL(20, 8),
            @weight_ea DECIMAL(20, 8),
            @serial_flag INT,
            @cost DECIMAL(20, 8),
            @ovhd_dolrs DECIMAL(20, 8),
            @util_dolrs DECIMAL(20, 8),
            @qty DECIMAL(20, 8);

    SELECT @today = GETDATE();


    IF @sdate IS NULL
        SELECT @sdate = DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0);

    IF @edate IS NULL
        SELECT @edate = @sdate;

    SELECT @ship_date = @edate;

    SELECT @routing = 'SAL',
           @attention = 'Recall ' + CONVERT(VARCHAR(8), @edate, 1);

    IF (OBJECT_ID('tempdb.dbo.#xfer') IS NOT NULL)
        DROP TABLE #xfer;

    SELECT DISTINCT
        sav.location,
        ia.part_no
    INTO #xfer
    FROM dbo.cvo_sc_addr_vw AS sav -- must be active rep
        JOIN lot_bin_stock lb (NOLOCK)
            ON lb.location = sav.location
        LEFT OUTER JOIN inv_master_add ia
            ON ia.part_no = lb.part_no -- part must exist


    WHERE NOT sav.territory_code IN ( '50534', 'i-sales' ) -- 534-broo
		--and sav.territory_code ='50504'
		          AND ISNULL(ia.field_28, DATEADD(day,1,@edate)) BETWEEN @sdate AND @edate
    ;

    SELECT @location = MIN(x.location)
    FROM #xfer AS x;


    WHILE @location IS NOT NULL
    BEGIN

        SELECT @from_loc = @location,
               @to_loc = '001';

        -- BEGIN TRAN;

        UPDATE dbo.next_xfer_no
        SET last_no = last_no + 1;

        SELECT @xfer_no = last_no
        FROM dbo.next_xfer_no;


        SELECT @to_loc_name = l.name,
               @to_loc_addr1 = addr1,
               @to_loc_addr2 = addr2,
               @to_loc_addr3 = addr3,
               @to_loc_addr4 = addr4,
               @to_loc_addr5 = addr5
        FROM locations_all l
        WHERE l.location = @to_loc;

        SELECT @locations_name = sav.salesperson_name,
               @locations_addr1 = sav.addr1,
               @locations_addr2 = sav.addr2,
               @locations_addr3 = sav.addr3,
               @locations_addr4 = '',
               @locations_addr5 = ''
        FROM dbo.locations_all AS l
            JOIN cvo_sc_addr_vw sav
                ON sav.location = l.location
        WHERE l.location = @from_loc;

        -- create xfer header record
        EXEC dbo.scm_pb_set_dw_transfer_sp @typ = 'I',
                                           @no = @xfer_no,
                                           @from_loc = @from_loc,
                                           @to_loc = @to_loc,
                                           @req_ship_date = @edate,
                                           @sch_ship_date = @edate,
                                           @date_shipped = NULL,
                                           @date_entered = @today,
                                           @req_no = NULL,
                                           @who_entered = 'AutoXferGen',
                                           @status = 'N',
                                           @attention = @attention,
                                           @phone = NULL,
                                           @c_routing = @routing,
                                           @si = NULL,
                                           @fob = NULL,
                                           @freight = 0.00000000,
                                           @printed = 'N',
                                           @label_no = 0,
                                           @no_cartons = 0,
                                           @who_shipped = NULL,
                                           @date_printed = NULL,
                                           @who_picked = NULL,
                                           @to_loc_name = @to_loc_name,
                                           @to_loc_addr1 = @to_loc_addr1,
                                           @to_loc_addr2 = @to_loc_addr2,
                                           @locations_name = @locations_name,
                                           @locations_addr1 = @locations_addr1,
                                           @locations_addr2 = @locations_addr2,
                                           @note = NULL,
                                           @rec_no = 0,
                                           @freight_type = NULL,
                                           @xfers_no_pallets = 0,
                                           @freight_type_description = NULL,
                                           @arshipv_ship_via_name = NULL,
                                           @locations_addr3 = @locations_addr3,
                                           @locations_addr4 = @locations_addr4,
                                           @locations_addr5 = @locations_addr5,
                                           @to_loc_addr3 = @to_loc_addr3,
                                           @to_loc_addr4 = @to_loc_addr4,
                                           @to_loc_addr5 = @to_loc_addr5,
                                           @who_recvd = NULL,
                                           @date_recvd = NULL,
                                           @c_status = NULL,
                                           @c_tdc_status = NULL,
                                           @from_organization_id = 'CVO',
                                           @to_organization_id = 'CVO',
                                           @proc_po_no = NULL,
                                           @i_eprocurement_interface = 0,
                                           @back_ord_flag = 2, -- no backorders
                                           @orig_xfer_no = NULL,
                                           @orig_xfer_ext = NULL,
                                           @timestamp = NULL,
                                           @autopack = 0,
                                           @autoship = 0;

        SELECT @part_no = MIN(i.part_no),
               @line_no = 1
        FROM #xfer AS x
            JOIN inv_master i
                ON i.part_no = x.part_no
        WHERE x.location = @location;

        WHILE @part_no IS NOT NULL
        BEGIN

            SELECT @description = description,
                   @allow_fractions = allow_fractions,
                   @weight_ea = weight_ea,
                   @cubic_feet = cubic_feet,
                   @serial_flag = serial_flag,
                   @cost = il.std_cost,
                   @ovhd_dolrs = il.std_ovhd_dolrs,
                   @util_dolrs = il.std_util_dolrs,
                   @qty = lb.qty

            FROM inv_master i (NOLOCK)
                JOIN
                (
                    SELECT lb.part_no,
                           lb.location,
                           SUM(qty) qty
                    FROM lot_bin_stock lb (NOLOCK)
                    GROUP BY lb.part_no,
                             lb.location
                ) lb
                    ON lb.part_no = i.part_no
                       AND lb.location = @location
                JOIN inv_list il (NOLOCK)
                    ON il.part_no = i.part_no
                       AND il.location = @location
            WHERE i.part_no = @part_no;

            IF @part_no IS NOT NULL
                EXEC dbo.scm_pb_set_dw_xfer_list_sp @typ = 'I',
                                                    @xfer_no = @xfer_no,
                                                    @line_no = @line_no,
                                                    @from_loc = @from_loc,
                                                    @to_loc = @to_loc,
                                                    @part_no = @part_no,
                                                    @description = @description,
                                                    @time_entered = @today,
                                                    @ordered = @qty,
                                                    @shipped = 0.00000000,
                                                    @note = NULL,
                                                    @status = 'N',
                                                    @cost = @cost,
                                                    @com_flag = NULL,
                                                    @who_entered = 'AutoXferGen',
                                                    @temp_cost = 0.00000000,
                                                    @uom = 'EA',
                                                    @conv_factor = 1.00000000,
                                                    @std_cost = 0.00000000,
                                                    @from_bin = NULL,
                                                    @to_bin = 'IN TRANSIT',
                                                    @lot_ser = 'N/A',
                                                    @date_expires = @ship_date,
                                                    @lb_tracking = 'Y',
                                                    @labor = 0.00000000,
                                                    @direct_dolrs = 0.00000000,
                                                    @ovhd_dolrs = @ovhd_dolrs,
                                                    @util_dolrs = @util_dolrs,
                                                    @inv_master_allow_fractions = @allow_fractions,
                                                    @display_line = @line_no,
                                                    @inv_master_cubic_feet = @cubic_feet,
                                                    @inv_master_weight_ea = @weight_ea,
                                                    @inv_master_serial_flag = @serial_flag,
                                                    @c_tdc_status = NULL,
                                                    @back_ord_flag = 2,
                                                    @timestamp = NULL;

            SELECT @part_no = MIN(i.part_no),
                   @line_no = @line_no + 1
            FROM #xfer AS x
                JOIN inv_master i
                    ON i.part_no = x.part_no
            WHERE x.location = @location
                  AND x.part_no > @part_no;

        END;

        -- COMMIT TRAN;

        EXEC cvo_xfer_after_save_sp @xfer_no = @xfer_no;

        SELECT @location = MIN(x.location)
        FROM #xfer AS x
        WHERE x.location > @location;

    END;

--SELECT *
--FROM   dbo.next_xfer_no AS nxn;

END;

GRANT EXECUTE ON dbo.cvo_sc_transfer_recall_create_sp TO PUBLIC;

GO
GRANT EXECUTE ON  [dbo].[cvo_sc_transfer_recall_create_sp] TO [public]
GO
