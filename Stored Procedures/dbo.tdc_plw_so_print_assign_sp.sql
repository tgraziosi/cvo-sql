SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v10.1 CB 24/07/2012 - Custom Frame Processing - Include custom frame in pick ticket  
  
CREATE PROCEDURE [dbo].[tdc_plw_so_print_assign_sp] @user_id varchar(50)  
AS  
 -- Check if any STDPICKs have been selected  
 IF NOT EXISTS(SELECT * FROM #so_pick_ticket_details WHERE location IS NOT NULL)  
  RETURN  
  
 TRUNCATE TABLE #so_pick_ticket  
  
 INSERT INTO #so_pick_ticket  
  (cons_no, order_no, order_ext,  
                 location, line_no, part_no,  
   lot_ser, bin_no, dest_bin,  
                 ord_qty, pick_qty, part_type,  
                 [user_id], order_date, cust_po,  
          sch_ship_date, carrier_desc,  
          ship_to_add_1, ship_to_add_2,  
          ship_to_add_3, ship_to_city,  
          ship_to_country, ship_to_name,  
          ship_to_state, ship_to_zip,  
          special_instr, order_note, uom,   
   item_note, [description], customer_name,  
          addr1, addr2, addr3, addr4, addr5,  
          cust_code, kit_caption, cancel_date,  
          kit_id, group_code_id, seq_no,     
                trans_type, tran_id)  
 SELECT d.consolidation_no, a.trans_type_no, a.trans_type_ext,  
               a.location, a.line_no, a.part_no,   
        a.lot, a.bin_no, a.next_op,   
        b.ordered, a.qty_to_process, b.part_type,   
        @user_id, NULL, NULL,  
               NULL, NULL, NULL,  
               NULL, NULL, NULL,  
               NULL, NULL, NULL,  
               NULL, NULL, NULL,   
        b.uom, note, NULL,  
        NULL, NULL,  NULL,  
               NULL, NULL,  NULL,  
               NULL, NULL,  NULL,  
               NULL, NULL,  NULL,  
        a.trans, a.tran_id  
   FROM tdc_pick_queue a (NOLOCK), ord_list b (NOLOCK), #so_pick_ticket_details c, tdc_cons_ords d (NOLOCK), cvo_ord_list e (NOLOCK) -- v10.1  
  WHERE a.trans_type_no   = b.order_no   
    AND a.trans_type_ext  = b.order_ext   
    AND a.line_no         = b.line_no   
    AND a.trans_type_no   = c.order_no   
    AND a.trans_type_ext  = c.order_ext     
    AND a.location        = c.location   
    AND a.trans_type_no   = d.order_no   
    AND a.trans_type_ext  = d.order_ext    
	AND a.trans_type_no   = e.order_no  -- v10.1
    AND a.trans_type_ext  = e.order_ext -- v10.1
    AND a.line_no         = e.line_no -- v10.1
    AND c.sel_flg        != 0  
    AND c.location       IS NOT NULL  
    AND d.order_type      = 'S'  
    AND a.trans_source    = 'PLW'   
    AND a.trans           IN ('STDPICK', 'PKGBLD')  
    AND ((a.tx_lock         IN ('R', 'G', '3', 'P')) -- v10.1
	OR	(a.tx_lock = 'H' AND e.is_customized = 'S')) -- v10.1

 UPDATE #so_pick_ticket  
    SET order_date    = b.date_entered,  cust_po         = b.cust_po,  
        sch_ship_date = b.sch_ship_date, order_note      = b.note,  
        carrier_desc  = b.routing,       ship_to_add_1   = b.ship_to_add_1,  
        ship_to_add_2 = b.ship_to_add_2, ship_to_add_3   = b.ship_to_add_3,  
        ship_to_city  = b.ship_to_city,  ship_to_country = b.ship_to_country,  
        ship_to_name  = b.ship_to_name,  ship_to_state   = b.ship_to_state,  
        ship_to_zip   = b.ship_to_zip,   special_instr   = b.special_instr,          
        [description] = c.[description], customer_name   = d.customer_name,  
        addr1 = d.addr1,    addr2   = d.addr2,    
        addr3 = d.addr3,          addr4   = d.addr4,  addr5 = d.addr5  
   FROM #so_pick_ticket a, orders b (NOLOCK), inv_master c (NOLOCK), arcust d (NOLOCK)  
  WHERE a.order_no  = b.order_no   
    AND a.order_ext = b.ext   
    AND a.part_no   = c.part_no   
    AND b.cust_code = d.customer_code  
   
 INSERT INTO #so_pick_ticket_working_tbl  
  (order_no, order_ext, line_no, [description], part_no, part_type)  
 SELECT DISTINCT a.order_no, a.order_ext, a.line_no, b.[description], b.part_no, b.part_type   
   FROM #so_pick_ticket a (NOLOCK), ord_list b (NOLOCK)  
  WHERE b.part_type = 'C'  
    AND a.order_no  = b.order_no  
    AND a.order_ext = b.order_ext  
    AND a.line_no   = b.line_no  
   
 UPDATE #so_pick_ticket  
    SET kit_id = #so_pick_ticket_working_tbl.part_no, kit_caption = '** CUSTOM KIT **' + '    ' +   
   #so_pick_ticket_working_tbl.part_no + '    ' + #so_pick_ticket_working_tbl.[description]  
   FROM #so_pick_ticket_working_tbl, #so_pick_ticket a(NOLOCK)  
  WHERE #so_pick_ticket_working_tbl.order_no = a.order_no  
    AND #so_pick_ticket_working_tbl.order_ext = a.order_ext  
    AND #so_pick_ticket_working_tbl.line_no = a.line_no  
   
 UPDATE  #so_pick_ticket  
    SET cust_code   = b.cust_code,  
                cancel_date = b.cancel_date  
   FROM #so_pick_ticket a, orders b  
  WHERE a.order_no  = b.order_no  
    AND a.order_ext = b.ext  
   
 UPDATE tdc_print_history_tbl  
    SET print_date = GETDATE(),  
        printed_by = @user_id  
   FROM tdc_print_history_tbl a,   
        #so_pick_ticket       b  
  WHERE a.order_no  = b.order_no  
    AND a.order_ext = b.order_ext  
    AND a.location  = b.location  
    AND pick_ticket_type = 'S'  
  
RETURN  
GO
GRANT EXECUTE ON  [dbo].[tdc_plw_so_print_assign_sp] TO [public]
GO
