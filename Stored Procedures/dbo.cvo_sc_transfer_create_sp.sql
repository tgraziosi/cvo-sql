SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_sc_transfer_create_sp]
(@routing VARCHAR(12) = NULL)
AS
BEGIN

    -- exec cvo_sc_transfer_create_sp 'UPS1D_SA' -- for last batch of xfers so they can be freighted.  leave out for default on slp master
	-- 7/9/18 - check inventory before creating xfers

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
            @transfer_id INT;

    DECLARE @line_no INT,
            @part_no VARCHAR(40),
            @description VARCHAR(255),
            @allow_fractions SMALLINT,
            @cubic_feet DECIMAL(20, 8),
            @weight_ea DECIMAL(20, 8),
            @serial_flag INT;

    --SELECT * FROM   dbo.cvo_sc_transfers;
    --SELECT * FROM   dbo.cvo_sc_transfers_allocation AS sta;
    --SELECT * FROM   cvo_sc_transfers_templates AS stt;

    -- SELECT * FROM xfers WHERE date_entered > '05/25/2018'

    --SELECT * 
    --FROM cvo_sc_transfers t
    --JOIN dbo.cvo_sc_transfers_templates AS stt ON stt.template_group = t.template_group
    --WHERE isactive = 1;

    -- SELECT * FROM cvo_transfer_vw WHERE date_entered > '10/18/2017'
    --INSERT dbo.cvo_sc_transfers_allocation (transfer_id, template_id, SKU, alloc_date, TEMPLATE_GROUP)
    --SELECT transfer_id, template_id, 'CVZBOPTTRAY', sta.alloc_date, TEMPLATE_GROUP
    --FROM dbo.cvo_sc_transfers_allocation AS sta 
    --WHERE transfer_id = 12 AND TEMPLATE_GROUP = 2 AND MODEL = 'P ZOOM'
    -- UPDATE dbo.cvo_sc_transfers SET isactive = 1 WHERE id > 6

    SELECT @today = GETDATE();

	-- DECLARE @routing VARCHAR(12);
    -- IF @routing IS NULL SELECT @routing = 'SAL';

    IF NOT EXISTS
    (
    SELECT 1
    FROM dbo.CVO_carriers AS c
    WHERE c.Carrier = ISNULL(@routing, c.Carrier)
    )
        SELECT @routing = 'SAL';


    IF (OBJECT_ID('tempdb.dbo.#xfer') IS NOT NULL)
        DROP TABLE #xfer;

    SELECT sta.transfer_id,
           sta.template_id,
           stt.location,
           sta.sku,
           sta.alloc_date,
           ISNULL(st.release_date, sta.alloc_date) sch_ship_date,
           ia.part_no,
           il.location il_loc,
           sav.location slp_loc_valid
    INTO #xfer
    FROM dbo.cvo_sc_transfers_allocation AS sta
        JOIN dbo.cvo_sc_transfers AS st
            ON st.id = sta.transfer_id
               AND st.template_group = sta.template_group
        JOIN cvo_sc_transfers_templates stt
            ON stt.template = sta.template_id
               AND stt.template_group = sta.template_group
        JOIN dbo.cvo_sc_addr_vw AS sav
            ON sav.location = stt.location -- must be active rep
        LEFT OUTER JOIN inv_master_add ia
            ON ia.part_no = sta.sku -- part must exist
        LEFT OUTER JOIN inv_list il
            ON il.part_no = sta.sku -- part/location must exist
               AND il.location = stt.location
    WHERE st.isActive = 1
          AND NOT stt.territory_code IN ( '50534', '70770' ) -- 534-broo
    ORDER BY stt.location,
             sta.sku;

    -- check inventory availability for sku's

    SELECT sku.sku,
           sku.num_skus,
           iav.qty_avl,
		   iav.in_stock
    FROM
    (SELECT COUNT(x.sku) num_skus, sku FROM #xfer AS x GROUP BY x.sku) sku
        JOIN dbo.cvo_item_avail_vw AS iav
            ON iav.part_no = sku.sku
               AND iav.location = '001'
    WHERE sku.num_skus > iav.qty_avl;

    IF @@ROWCOUNT <> 0
    BEGIN
        SELECT DISTINCT
               'Error:  Not enough inventory for one or more skus';
        RETURN;
    END;

    --SELECT * FROM   #xfer AS x;
    IF EXISTS (SELECT 1 FROM #xfer WHERE part_no IS NULL OR il_loc IS NULL)
    BEGIN
        SELECT DISTINCT
               'Error: Missing Inventory master data found' err_msg,
               transfer_id,
               template_id,
               location,
               sku,
               alloc_date,
               sch_ship_date,
               part_no,
               il_loc,
               slp_loc_valid
        FROM #xfer
        WHERE part_no IS NULL
              OR il_loc IS NULL
              OR slp_loc_valid IS NULL;
        RETURN;
    END;

    SELECT @location = MIN(x.location)
    FROM #xfer AS x
    WHERE part_no IS NOT NULL
          AND il_loc IS NOT NULL
          AND slp_loc_valid IS NOT NULL;


    WHILE @location IS NOT NULL
    BEGIN

        SELECT @from_loc = '001',
               @to_loc = @location;

        SELECT TOP 1
               @ship_date = x.sch_ship_date
        FROM #xfer x
        WHERE x.location = @location;

        BEGIN TRAN;

        UPDATE dbo.next_xfer_no
        SET last_no = last_no + 1;

        SELECT @xfer_no = last_no
        FROM dbo.next_xfer_no;


        SELECT @to_loc_name = sav.salesperson_name,
               @to_loc_addr1 = sav.addr1,
               @to_loc_addr2 = sav.addr2,
               @to_loc_addr3 = sav.addr3,
               @to_loc_addr4 = sav.addr4,
               @to_loc_addr5 = sav.addr5,
               @routing = CASE WHEN ISNULL(@routing, '') = '' THEN sav.ship_via_code ELSE @routing END
        FROM locations_all l
            JOIN cvo_sc_addr_vw sav
                ON sav.location = l.location
        WHERE l.location = @to_loc;

        SELECT @locations_name = l.name,
               @locations_addr1 = addr1,
               @locations_addr2 = addr2,
               @locations_addr3 = addr3,
               @locations_addr4 = addr4,
               @locations_addr5 = addr5
        FROM dbo.locations_all AS l
        WHERE l.location = @from_loc;

        -- create xfer header record
        EXEC dbo.scm_pb_set_dw_transfer_sp @typ = 'I',
                                           @no = @xfer_no,
                                           @from_loc = @from_loc,
                                           @to_loc = @to_loc,
                                           @req_ship_date = @ship_date,
                                           @sch_ship_date = @ship_date,
                                           @date_shipped = NULL,
                                           @date_entered = @today,
                                           @req_no = NULL,
                                           @who_entered = 'AutoXferGen',
                                           @status = 'N',
                                           @attention = @location,
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
                                           @back_ord_flag = 0,
                                           @orig_xfer_no = NULL,
                                           @orig_xfer_ext = NULL,
                                           @timestamp = NULL,
                                           @autopack = 0,
                                           @autoship = 0;

        SELECT @part_no = MIN(sku),
               @line_no = 1
        FROM #xfer AS x
            JOIN inv_master i
                ON i.part_no = x.sku
        WHERE x.location = @location;

        WHILE @part_no IS NOT NULL
        BEGIN

            SELECT @description = description,
                   @allow_fractions = allow_fractions,
                   @weight_ea = weight_ea,
                   @cubic_feet = cubic_feet,
                   @serial_flag = serial_flag
            FROM inv_master
                (NOLOCK)
            WHERE part_no = @part_no;

            IF @part_no IS NOT NULL
                EXEC dbo.scm_pb_set_dw_xfer_list_sp @typ = 'I',
                                                    @xfer_no = @xfer_no,
                                                    @line_no = @line_no,
                                                    @from_loc = @from_loc,
                                                    @to_loc = @to_loc,
                                                    @part_no = @part_no,
                                                    @description = @description,
                                                    @time_entered = @today,
                                                    @ordered = 1.00000000,
                                                    @shipped = 0.00000000,
                                                    @note = NULL,
                                                    @status = 'N',
                                                    @cost = 0.00000000,
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
                                                    @ovhd_dolrs = 0.00000000,
                                                    @util_dolrs = 0.00000000,
                                                    @inv_master_allow_fractions = @allow_fractions,
                                                    @display_line = @line_no,
                                                    @inv_master_cubic_feet = @cubic_feet,
                                                    @inv_master_weight_ea = @weight_ea,
                                                    @inv_master_serial_flag = @serial_flag,
                                                    @c_tdc_status = NULL,
                                                    @back_ord_flag = 0,
                                                    @timestamp = NULL;

            SELECT @part_no = MIN(sku),
                   @line_no = @line_no + 1
            FROM #xfer AS x
                JOIN inv_master i
                    ON i.part_no = x.sku
            WHERE x.location = @location
                  AND x.sku > @part_no;

        END;

        COMMIT TRAN;

        EXEC cvo_xfer_after_save_sp @xfer_no = @xfer_no;

        SELECT @location = MIN(x.location)
        FROM #xfer AS x
        WHERE x.location > @location
              AND part_no IS NOT NULL
              AND il_loc IS NOT NULL
              AND slp_loc_valid IS NOT NULL;;

    END;

    UPDATE t -- mark it as processed
    SET t.isActive = 2
    FROM dbo.cvo_sc_transfers t
        JOIN
        (SELECT DISTINCT transfer_id FROM #xfer) x
            ON x.transfer_id = t.id;

--SELECT   tv.xfer_no ,
--         tv.status ,
--         tv.status_desc ,
--         tv.from_loc ,
--         tv.to_loc ,
--         tv.date_shipped ,
--         tv.date_entered ,
--         tv.date_printed ,
--         tv.date_recvd ,
--         tv.who_picked ,
--         tv.who_recvd ,
--         tv.qty_ordered ,
--         tv.extcost_ordered ,
--         tv.qty_shipped ,
--         tv.extcost_shipped ,
--         tv.qty_recv ,
--         tv.extcost_recvd
--FROM     dbo.cvo_transfer_vw AS tv
--WHERE    1 = 1
--         -- AND tv.attention IN ('a','b','c','d','e','f')
--         AND status = 'N'
--ORDER BY xfer_no DESC;

--SELECT *
--FROM   dbo.next_xfer_no AS nxn;


--SELECT * FROM dbo.cvo_sc_transfers_allocation AS sta 
--LEFT OUTER JOIN inv_master i ON sta.sku = i.part_no

-- SELECT * FROM xfer_list WHERE xfer_no IN (134974, 134973, 135064,135063)

END;

GRANT EXECUTE ON dbo.cvo_sc_transfer_create_sp TO PUBLIC;













GO
GRANT EXECUTE ON  [dbo].[cvo_sc_transfer_create_sp] TO [public]
GO
