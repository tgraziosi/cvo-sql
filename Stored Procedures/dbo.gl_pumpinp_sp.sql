SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*
              Confidential Information
   Limited Distribution of Authorized Persons Only
   Created 1996 and Protected as Unpublished Work
         Under the U.S. Copyright Act of 1976
Copyright (c) 1996 Platinum Software Corporation, 1996
                 All Rights Reserved 
 */
                                         CREATE PROC [dbo].[gl_pumpinp_sp] AS BEGIN DECLARE 
 @comp_ctry_code varchar(3),  @eucomp_flag smallint,  @country_code varchar(3),  @saved smallint, 
 @trx_ctrl_num varchar(16),  @order_ctrl_num varchar(16),  @customer_code varchar(8), 
 @ship_to_code varchar(8),  @date_applied int,  @nat_cur_code varchar(8),  @freight_code varchar(8), 
 @fob_code varchar(8),  @rate_type varchar(8),  @is_input_exist smallint DECLARE 
 @location_code varchar(8),  @item_code varchar(30),  @qty_item float,  @total_amt_nat float, 
 @amt_nat float,  @is_detail_freight smallint,  @amt_freight float,  @zone_code varchar(8), 
 @unit_code varchar(10) DECLARE  @ctrl_int int,  @ext_int int,  @ctrl_str varchar(16), 
 @ext_str varchar(20),  @alt_ctrl_str varchar(16) DECLARE  @po_ctrl_num varchar(16), 
 @vend_order_num varchar(20),  @vendor_code varchar(12),  @pay_to_code varchar(8) 
DECLARE  @xfer_no int,  @from_loc varchar(8),  @to_loc varchar(8),  @apply_date datetime, 
 @routing varchar(20) DECLARE  @return_code smallint,  @src_trx_id varchar(4),  @src_ctrl_num varchar(16), 
 @src_line_id int,  @prev_key varchar(128),  @key varchar(128),  @prev_line_id int 
    SELECT @comp_ctry_code = country_code from glco  SELECT @eucomp_flag = 0  SELECT @eucomp_flag = 1 WHERE @comp_ctry_code IN (SELECT country_code FROM gl_glctry) 
 SET ROWCOUNT 1     BEGIN TRANSACTION  SELECT @prev_key = ""  SELECT @key = STR(h.trx_type, 4) + CONVERT(char(16), h.doc_ctrl_num), 
 @trx_ctrl_num = h.doc_ctrl_num,  @order_ctrl_num = h.order_ctrl_num,  @customer_code = h.customer_code, 
 @ship_to_code = h.ship_to_code,  @date_applied = h.date_applied,  @nat_cur_code = h.nat_cur_code, 
 @freight_code = h.freight_code,  @fob_code = h.fob_code,  @amt_freight = h.amt_freight, 
 @zone_code = h.dest_zone_code,  @country_code = c.country_code,  @rate_type = h.rate_type_home, 
 @total_amt_nat = h.amt_gross - h.amt_discount  FROM artrx h, armaster c  WHERE h.trx_type = 2031 
 AND h.doc_ctrl_num NOT IN  (SELECT src_doc_num FROM gl_glinphdr WHERE src_trx_id = "2031") 
 AND h.order_ctrl_num NOT IN  (SELECT src_doc_num FROM gl_glinphdr WHERE src_trx_id = "OEIV") 
 AND h.customer_code = c.customer_code  AND h.ship_to_code = c.ship_to_code  AND c.country_code IN 
 (SELECT country_code FROM gl_glctry)  ORDER BY h.trx_type, h.doc_ctrl_num  WHILE @@rowcount > 0 
 BEGIN     SELECT @src_trx_id = "", @src_ctrl_num = ""     EXEC @return_code =ar_setarhdr_sp 
 @trx_ctrl_num,  @order_ctrl_num,  1,  0, @customer_code,  0, @ship_to_code,  0, @date_applied, 
 0, @nat_cur_code,  0, @freight_code,  0, @fob_code,  0, @rate_type,  @src_trx_id OUTPUT, 
 @src_ctrl_num OUTPUT,  @is_input_exist OUTPUT  IF @return_code < 0 OR @return_code = 8100 OR @return_code = 8101 
 BEGIN  ROLLBACK TRANSACTION  RETURN @return_code  END     SELECT @saved = 0  SELECT @prev_line_id = 0 
 SELECT @src_line_id = d.sequence_id,  @qty_item = d.qty_shipped,  @amt_nat = d.extended_price, 
 @location_code = d.location_code,  @item_code = d.item_code,  @unit_code = d.unit_code 
 FROM artrxcdt d, locations l  WHERE d.trx_type = 2031  AND d.doc_ctrl_num = @trx_ctrl_num 
 AND ((d.location_code = ""  AND @eucomp_flag = 1  AND @comp_ctry_code <> @country_code) 
 OR (d.location_code = l.location  AND l.country_code <> @country_code  AND l.country_code IN 
 (SELECT country_code FROM gl_glctry)))  ORDER BY d.sequence_id  WHILE @@rowcount > 0 
 BEGIN  EXEC @return_code = gl_setarapdet_sp  @src_trx_id,  @src_ctrl_num,  @src_line_id, 
 @total_amt_nat,  0, @customer_code,  0, @ship_to_code,  0, @location_code,  0, @item_code, 
 0, @qty_item,  0, @amt_nat,  0,  0, @amt_freight,  0, @zone_code,  0, @unit_code 
 IF @return_code < 0 OR @return_code = 8100 OR @return_code = 8101  BEGIN  ROLLBACK TRANSACTION 
 RETURN @return_code  END  SELECT @saved = @saved + 1  SELECT @prev_line_id = @src_line_id 
 SELECT @src_line_id = d.sequence_id,  @qty_item = d.qty_shipped,  @amt_nat = d.extended_price, 
 @location_code = d.location_code,  @item_code = d.item_code,  @unit_code = d.unit_code 
 FROM artrxcdt d, locations l  WHERE d.trx_type = 2031  AND d.doc_ctrl_num = @trx_ctrl_num 
 AND @prev_line_id < d.sequence_id  AND ((d.location_code = ""  AND @eucomp_flag = 1 
 AND @comp_ctry_code <> @country_code)  OR (d.location_code = l.location  AND l.country_code <> @country_code 
 AND l.country_code IN  (SELECT country_code FROM gl_glctry)))  ORDER BY d.sequence_id 
 END     IF @saved > 0  BEGIN  SELECT @ctrl_int = 0, @ext_int = 0,  @ctrl_str = @trx_ctrl_num, @ext_str = @order_ctrl_num, @alt_ctrl_str = '' 
 EXEC @return_code = gl_saveinp_sp  @src_trx_id, @src_ctrl_num, @ctrl_int, @ext_int, @ctrl_str, @ext_str, @alt_ctrl_str 
 IF @return_code < 0 OR @return_code = 8100 OR @return_code = 8101  BEGIN  ROLLBACK TRANSACTION 
 RETURN @return_code  END  END  ELSE  BEGIN  DELETE FROM gl_glinphdr WHERE  (@trx_ctrl_num = src_doc_num AND src_trx_id = "2031") OR 
 (@order_ctrl_num = src_doc_num AND src_trx_id = "OEIV")  END     EXEC @return_code = gl_cleaninp_sp @src_trx_id, @src_ctrl_num 
 IF @return_code <> 0  BEGIN  ROLLBACK TRANSACTION  RETURN @return_code  END  SELECT @prev_key = @key 
 SELECT @key = STR(h.trx_type, 4) + CONVERT(char(16), h.doc_ctrl_num),  @trx_ctrl_num = h.doc_ctrl_num, 
 @order_ctrl_num = h.order_ctrl_num,  @customer_code = h.customer_code,  @ship_to_code = h.ship_to_code, 
 @date_applied = h.date_applied,  @nat_cur_code = h.nat_cur_code,  @freight_code = h.freight_code, 
 @fob_code = h.fob_code,  @amt_freight = h.amt_freight,  @zone_code = h.dest_zone_code, 
 @country_code = c.country_code,  @rate_type = h.rate_type_home,  @total_amt_nat = h.amt_gross - h.amt_discount 
 FROM artrx h, armaster c  WHERE h.trx_type = 2031  AND h.doc_ctrl_num NOT IN  (SELECT src_doc_num FROM gl_glinphdr WHERE src_trx_id = "2031") 
 AND h.order_ctrl_num NOT IN  (SELECT src_doc_num FROM gl_glinphdr WHERE src_trx_id = "OEIV") 
 AND h.customer_code = c.customer_code  AND h.ship_to_code = c.ship_to_code  AND c.country_code IN 
 (SELECT country_code FROM gl_glctry)  AND @prev_key < STR(h.trx_type, 4) + CONVERT(char(16), h.doc_ctrl_num) 
 ORDER BY h.trx_type, h.doc_ctrl_num  END  COMMIT TRANSACTION     BEGIN TRANSACTION 
 SELECT @prev_key = ""  SELECT @key = STR(h.trx_type, 4) + CONVERT(char(16), h.doc_ctrl_num), 
 @trx_ctrl_num = h.doc_ctrl_num,  @order_ctrl_num = h.order_ctrl_num,  @customer_code = h.customer_code, 
 @ship_to_code = h.ship_to_code,  @date_applied = h.date_applied,  @nat_cur_code = h.nat_cur_code, 
 @freight_code = h.freight_code,  @fob_code = h.fob_code,  @amt_freight = h.amt_freight, 
 @zone_code = h.dest_zone_code,  @country_code = c.country_code,  @rate_type = h.rate_type_home, 
 @total_amt_nat = h.amt_gross - h.amt_discount  FROM artrx h, armaster c  WHERE h.trx_type = 2032 
 AND h.doc_ctrl_num NOT IN  (SELECT src_doc_num FROM gl_glinphdr WHERE src_trx_id = "2032") 
 AND h.order_ctrl_num NOT IN  (SELECT src_doc_num FROM gl_glinphdr WHERE src_trx_id = "OECM") 
 AND h.customer_code = c.customer_code  AND h.ship_to_code = c.ship_to_code  AND c.country_code IN 
 (SELECT country_code FROM gl_glctry)  ORDER BY h.trx_type, h.doc_ctrl_num  WHILE @@rowcount > 0 
 BEGIN     SELECT @src_trx_id = "", @src_ctrl_num = ""     EXEC @return_code = ar_setarhdr_sp 
 @trx_ctrl_num,  @order_ctrl_num,  0,  0, @customer_code,  0, @ship_to_code,  0, @date_applied, 
 0, @nat_cur_code,  0, @freight_code,  0, @fob_code,  0, @rate_type,  @src_trx_id OUTPUT, 
 @src_ctrl_num OUTPUT,  @is_input_exist OUTPUT  IF @return_code < 0 OR @return_code = 8100 OR @return_code = 8101 
 BEGIN  ROLLBACK TRANSACTION  RETURN @return_code  END     SELECT @saved = 0  SELECT @prev_line_id = 0 
 SELECT @src_line_id = d.sequence_id,  @qty_item = d.qty_returned,  @amt_nat = d.extended_price, 
 @location_code = d.location_code,  @item_code = d.item_code,  @unit_code = d.unit_code 
 FROM artrxcdt d, locations l  WHERE d.trx_type = 2032  AND d.doc_ctrl_num = @trx_ctrl_num 
 AND ((d.location_code = ""  AND @eucomp_flag = 1  AND @comp_ctry_code <> @country_code) 
 OR (d.location_code = l.location  AND l.country_code <> @country_code  AND l.country_code IN 
 (SELECT country_code FROM gl_glctry)))  ORDER BY d.sequence_id  WHILE @@rowcount > 0 
 BEGIN  EXEC @return_code = gl_setarapdet_sp  @src_trx_id,  @src_ctrl_num,  @src_line_id, 
 @total_amt_nat,  0, @customer_code,  0, @ship_to_code,  0, @location_code,  0, @item_code, 
 0, @qty_item,  0, @amt_nat,  0,  0, @amt_freight,  0, @zone_code,  0, @unit_code 
 IF @return_code < 0 OR @return_code = 8100 OR @return_code = 8101  BEGIN  ROLLBACK TRANSACTION 
 RETURN @return_code  END  SELECT @saved = @saved + 1  SELECT @prev_line_id = @src_line_id 
 SELECT @src_line_id = d.sequence_id,  @qty_item = d.qty_returned,  @amt_nat = d.extended_price, 
 @location_code = d.location_code,  @item_code = d.item_code,  @unit_code = d.unit_code 
 FROM artrxcdt d, locations l  WHERE d.trx_type = 2032  AND d.doc_ctrl_num = @trx_ctrl_num 
 AND @prev_line_id < d.sequence_id  AND ((d.location_code = ""  AND @eucomp_flag = 1 
 AND @comp_ctry_code <> @country_code)  OR (d.location_code = l.location  AND l.country_code <> @country_code 
 AND l.country_code IN  (SELECT country_code FROM gl_glctry)))  ORDER BY d.sequence_id 
 END     IF @saved > 0  BEGIN  SELECT @ctrl_int = 0, @ext_int = 0,  @ctrl_str = @trx_ctrl_num, @ext_str = @order_ctrl_num, @alt_ctrl_str = '' 
 EXEC @return_code = gl_saveinp_sp  @src_trx_id, @src_ctrl_num, @ctrl_int, @ext_int, @ctrl_str, @ext_str, @alt_ctrl_str 
 IF @return_code < 0 OR @return_code = 8100 OR @return_code = 8101  BEGIN  ROLLBACK TRANSACTION 
 RETURN @return_code  END  END  ELSE  BEGIN  DELETE FROM gl_glinphdr WHERE  (@trx_ctrl_num = src_doc_num AND src_trx_id = "2032") OR 
 (@order_ctrl_num = src_doc_num AND src_trx_id = "OECM")  END     EXEC @return_code = gl_cleaninp_sp @src_trx_id, @src_ctrl_num 
 IF @return_code <> 0  BEGIN  ROLLBACK TRANSACTION  RETURN @return_code  END  SELECT @prev_key = @key 
 SELECT @key = STR(h.trx_type, 4) + CONVERT(char(16), h.doc_ctrl_num),  @trx_ctrl_num = h.doc_ctrl_num, 
 @order_ctrl_num = h.order_ctrl_num,  @customer_code = h.customer_code,  @ship_to_code = h.ship_to_code, 
 @date_applied = h.date_applied,  @nat_cur_code = h.nat_cur_code,  @freight_code = h.freight_code, 
 @fob_code = h.fob_code,  @amt_freight = h.amt_freight,  @zone_code = h.dest_zone_code, 
 @country_code = c.country_code,  @rate_type = h.rate_type_home,  @total_amt_nat = h.amt_gross - h.amt_discount 
 FROM artrx h, armaster c  WHERE h.trx_type = 2032  AND h.doc_ctrl_num NOT IN  (SELECT src_doc_num FROM gl_glinphdr WHERE src_trx_id = "2032") 
 AND h.order_ctrl_num NOT IN  (SELECT src_doc_num FROM gl_glinphdr WHERE src_trx_id = "OEIV") 
 AND h.customer_code = c.customer_code  AND h.ship_to_code = c.ship_to_code  AND c.country_code IN 
 (SELECT country_code FROM gl_glctry)  AND @prev_key < STR(h.trx_type, 4) + CONVERT(char(16), h.doc_ctrl_num) 
 ORDER BY h.trx_type, h.doc_ctrl_num  END  COMMIT TRANSACTION     BEGIN TRANSACTION 
 SELECT @prev_key = ""  SELECT @key = STR(4091, 4) + CONVERT(char(16), h.trx_ctrl_num), 
 @trx_ctrl_num = h.trx_ctrl_num,  @po_ctrl_num = h.po_ctrl_num,  @vend_order_num = h.vend_order_num, 
 @vendor_code = h.vendor_code,  @pay_to_code = h.pay_to_code,  @date_applied = h.date_applied, 
 @nat_cur_code = h.currency_code,  @fob_code = h.fob_code,  @country_code = v.country_code, 
 @rate_type = h.rate_type_home,  @total_amt_nat = h.amt_gross - h.amt_discount  FROM apvohdr h, apvend v 
 WHERE h.trx_ctrl_num NOT IN  (SELECT src_doc_num FROM gl_glinphdr WHERE src_trx_id = "4091") 
 AND CONVERT(char(16), h.po_ctrl_num) + CONVERT(char(20), h.vend_order_num) NOT IN 
 (SELECT src_doc_num FROM gl_glinphdr WHERE src_trx_id = "PMVO")  AND h.vendor_code = v.vendor_code 
 AND v.country_code IN  (SELECT country_code FROM gl_glctry)  ORDER BY h.trx_ctrl_num 
 WHILE @@rowcount > 0  BEGIN     SELECT @src_trx_id = "", @src_ctrl_num = ""     EXEC @return_code = ap_setaphdr_sp 
 @trx_ctrl_num,  @po_ctrl_num,  @vend_order_num,  1,  0, @vendor_code,  0, @pay_to_code, 
 0, @date_applied,  0, @nat_cur_code,  0, @fob_code,  0, @rate_type,  @src_trx_id OUTPUT, 
 @src_ctrl_num OUTPUT,  @is_input_exist OUTPUT  IF @return_code < 0 OR @return_code = 8100 OR @return_code = 8101 
 BEGIN  ROLLBACK TRANSACTION  RETURN @return_code  END     SELECT @saved = 0  SELECT @prev_line_id = 0 
 SELECT @src_line_id = d.sequence_id,  @qty_item = d.qty_received,  @amt_nat = d.amt_extended, 
 @location_code = d.location_code,  @item_code = d.item_code,  @amt_freight = d.amt_freight, 
 @unit_code = d.unit_code  FROM apvodet d, locations l  WHERE d.trx_ctrl_num = @trx_ctrl_num 
 AND ((d.location_code = ""  AND @eucomp_flag = 1  AND @comp_ctry_code <> @country_code) 
 OR (d.location_code = l.location  AND l.country_code <> @country_code  AND l.country_code IN 
 (SELECT country_code FROM gl_glctry)))  ORDER BY d.sequence_id  WHILE @@rowcount > 0 
 BEGIN  EXEC @return_code = gl_setarapdet_sp  @src_trx_id,  @src_ctrl_num,  @src_line_id, 
 @total_amt_nat,  0, @vendor_code,  0, @pay_to_code,  0, @location_code,  0, @item_code, 
 0, @qty_item,  0, @amt_nat,  1,  0, @amt_freight,  0, @zone_code,  0, @unit_code 
 IF @return_code < 0 OR @return_code = 8100 OR @return_code = 8101  BEGIN  ROLLBACK TRANSACTION 
 RETURN @return_code  END  SELECT @saved = @saved + 1  SELECT @prev_line_id = @src_line_id 
 SELECT @src_line_id = d.sequence_id,  @qty_item = d.qty_received,  @amt_nat = d.amt_extended, 
 @location_code = d.location_code,  @item_code = d.item_code,  @amt_freight = d.amt_freight, 
 @unit_code = d.unit_code  FROM apvodet d, locations l  WHERE d.trx_ctrl_num = @trx_ctrl_num 
 AND @prev_line_id < d.sequence_id  AND ((d.location_code = ""  AND @eucomp_flag = 1 
 AND @comp_ctry_code <> @country_code)  OR (d.location_code = l.location  AND l.country_code <> @country_code 
 AND l.country_code IN  (SELECT country_code FROM gl_glctry)))  ORDER BY d.sequence_id 
 END     IF @saved > 0  BEGIN  SELECT @ctrl_int = 0, @ext_int = 0,  @ctrl_str = @trx_ctrl_num, @ext_str = @vend_order_num, @alt_ctrl_str = @po_ctrl_num 
 EXEC @return_code = gl_saveinp_sp  @src_trx_id, @src_ctrl_num, @ctrl_int, @ext_int, @ctrl_str, @ext_str, @alt_ctrl_str 
 IF @return_code < 0 OR @return_code = 8100 OR @return_code = 8101  BEGIN  ROLLBACK TRANSACTION 
 RETURN @return_code  END  END  ELSE  BEGIN  DELETE FROM gl_glinphdr WHERE  (@trx_ctrl_num = src_doc_num AND src_trx_id = "4091") OR 
 (CONVERT(char(16), @po_ctrl_num) + CONVERT(char(20), @vend_order_num) = src_doc_num AND src_trx_id = "PMVO") 
 END     EXEC @return_code = gl_cleaninp_sp @src_trx_id, @src_ctrl_num  IF @return_code <> 0 
 BEGIN  ROLLBACK TRANSACTION  RETURN @return_code  END  SELECT @prev_key = @key  SELECT @key = STR(4091, 4) + CONVERT(char(16), h.trx_ctrl_num), 
 @trx_ctrl_num = h.trx_ctrl_num,  @po_ctrl_num = h.po_ctrl_num,  @vend_order_num = h.vend_order_num, 
 @vendor_code = h.vendor_code,  @pay_to_code = h.pay_to_code,  @date_applied = h.date_applied, 
 @nat_cur_code = h.currency_code,  @fob_code = h.fob_code,  @country_code = v.country_code, 
 @rate_type = h.rate_type_home,  @total_amt_nat = h.amt_gross - h.amt_discount  FROM apvohdr h, apvend v 
 WHERE h.trx_ctrl_num NOT IN  (SELECT src_doc_num FROM gl_glinphdr WHERE src_trx_id = "4091") 
 AND CONVERT(char(16), h.po_ctrl_num) + CONVERT(char(20), h.vend_order_num) NOT IN 
 (SELECT src_doc_num FROM gl_glinphdr WHERE src_trx_id = "PMVO")  AND h.vendor_code = v.vendor_code 
 AND v.country_code IN  (SELECT country_code FROM gl_glctry)  AND @prev_key < STR(4091, 4) + CONVERT(char(16), h.trx_ctrl_num) 
 ORDER BY h.trx_ctrl_num  END  COMMIT TRANSACTION     BEGIN TRANSACTION  SELECT @prev_key = "" 
 SELECT @key = STR(4092, 4) + CONVERT(char(16), h.trx_ctrl_num),  @trx_ctrl_num = h.trx_ctrl_num, 
 @po_ctrl_num = h.po_ctrl_num,  @vend_order_num = h.vend_order_num,  @vendor_code = h.vendor_code, 
 @pay_to_code = h.pay_to_code,  @date_applied = h.date_applied,  @nat_cur_code = h.currency_code, 
 @fob_code = h.fob_code,  @country_code = v.country_code,  @rate_type = h.rate_type_home, 
 @total_amt_nat = h.amt_gross - h.amt_discount  FROM apdmhdr h, apvend v  WHERE h.trx_ctrl_num NOT IN 
 (SELECT src_doc_num FROM gl_glinphdr WHERE src_trx_id = "4092")  AND CONVERT(char(16), h.po_ctrl_num) + CONVERT(char(20), h.vend_order_num) NOT IN 
 (SELECT src_doc_num FROM gl_glinphdr WHERE src_trx_id = "PMDM")  AND h.vendor_code = v.vendor_code 
 AND v.country_code IN  (SELECT country_code FROM gl_glctry)  ORDER BY h.trx_ctrl_num 
 WHILE @@rowcount > 0  BEGIN     SELECT @src_trx_id = "", @src_ctrl_num = ""     EXEC @return_code = ap_setaphdr_sp 
 @trx_ctrl_num,  @po_ctrl_num,  @vend_order_num,  0,  0, @vendor_code,  0, @pay_to_code, 
 0, @date_applied,  0, @nat_cur_code,  0, @fob_code,  0, @rate_type,  @src_trx_id OUTPUT, 
 @src_ctrl_num OUTPUT,  @is_input_exist OUTPUT  IF @return_code < 0 OR @return_code = 8100 OR @return_code = 8101 
 BEGIN  ROLLBACK TRANSACTION  RETURN @return_code  END     SELECT @saved = 0  SELECT @prev_line_id = 0 
 SELECT @src_line_id = d.sequence_id,  @qty_item = d.qty_returned,  @amt_nat = d.amt_extended, 
 @location_code = d.location_code,  @item_code = d.item_code,  @amt_freight = d.amt_freight, 
 @unit_code = d.unit_code  FROM apdmdet d, locations l  WHERE d.trx_ctrl_num = @trx_ctrl_num 
 AND ((d.location_code = ""  AND @eucomp_flag = 1  AND @comp_ctry_code <> @country_code) 
 OR (d.location_code = l.location  AND l.country_code <> @country_code  AND l.country_code IN 
 (SELECT country_code FROM gl_glctry)))  ORDER BY d.sequence_id  WHILE @@rowcount > 0 
 BEGIN  EXEC @return_code = gl_setarapdet_sp  @src_trx_id,  @src_ctrl_num,  @src_line_id, 
 @total_amt_nat,  0, @vendor_code,  0, @pay_to_code,  0, @location_code,  0, @item_code, 
 0, @qty_item,  0, @amt_nat,  1,  0, @amt_freight,  0, @zone_code,  0, @unit_code 
 IF @return_code < 0 OR @return_code = 8100 OR @return_code = 8101  BEGIN  ROLLBACK TRANSACTION 
 RETURN @return_code  END  SELECT @saved = @saved + 1  SELECT @prev_line_id = @src_line_id 
 SELECT @src_line_id = d.sequence_id,  @qty_item = d.qty_returned,  @amt_nat = d.amt_extended, 
 @location_code = d.location_code,  @item_code = d.item_code,  @amt_freight = d.amt_freight, 
 @unit_code = d.unit_code  FROM apdmdet d, locations l  WHERE d.trx_ctrl_num = @trx_ctrl_num 
 AND @prev_line_id < d.sequence_id  AND ((d.location_code = ""  AND @eucomp_flag = 1 
 AND @comp_ctry_code <> @country_code)  OR (d.location_code = l.location  AND l.country_code <> @country_code 
 AND l.country_code IN  (SELECT country_code FROM gl_glctry)))  ORDER BY d.sequence_id 
 END     IF @saved > 0  BEGIN  SELECT @ctrl_int = 0, @ext_int = 0,  @ctrl_str = @trx_ctrl_num, @ext_str = @vend_order_num, @alt_ctrl_str = @po_ctrl_num 
 EXEC @return_code = gl_saveinp_sp  @src_trx_id, @src_ctrl_num, @ctrl_int, @ext_int, @ctrl_str, @ext_str, @alt_ctrl_str 
 IF @return_code < 0 OR @return_code = 8100 OR @return_code = 8101  BEGIN  ROLLBACK TRANSACTION 
 RETURN @return_code  END  END  ELSE  BEGIN  DELETE FROM gl_glinphdr WHERE  (@trx_ctrl_num = src_doc_num AND src_trx_id = "4092") OR 
 (CONVERT(char(16), @po_ctrl_num) + CONVERT(char(20), @vend_order_num) = src_doc_num AND src_trx_id = "PMDM") 
 END     EXEC @return_code = gl_cleaninp_sp @src_trx_id, @src_ctrl_num  IF @return_code <> 0 
 BEGIN  ROLLBACK TRANSACTION  RETURN @return_code  END  SELECT @prev_key = @key  SELECT @key = STR(4092, 4) + CONVERT(char(16), h.trx_ctrl_num), 
 @trx_ctrl_num = h.trx_ctrl_num,  @po_ctrl_num = h.po_ctrl_num,  @vend_order_num = h.vend_order_num, 
 @vendor_code = h.vendor_code,  @pay_to_code = h.pay_to_code,  @date_applied = h.date_applied, 
 @nat_cur_code = h.currency_code,  @fob_code = h.fob_code,  @country_code = v.country_code, 
 @rate_type = h.rate_type_home,  @total_amt_nat = h.amt_gross - h.amt_discount  FROM apdmhdr h, apvend v 
 WHERE h.trx_ctrl_num NOT IN  (SELECT src_doc_num FROM gl_glinphdr WHERE src_trx_id = "4092") 
 AND CONVERT(char(16), h.po_ctrl_num) + CONVERT(char(20), h.vend_order_num) NOT IN 
 (SELECT src_doc_num FROM gl_glinphdr WHERE src_trx_id = "PMDM")  AND h.vendor_code = v.vendor_code 
 AND v.country_code IN  (SELECT country_code FROM gl_glctry)  AND @prev_key < STR(4092, 4) + CONVERT(char(16), h.trx_ctrl_num) 
 ORDER BY h.trx_ctrl_num  END  

COMMIT TRANSACTION  


	IF EXISTS( SELECT name FROM sysobjects WHERE name = "xfers" )
	BEGIN
	/* Inventory transfer - shipping
	*/
	BEGIN TRANSACTION

		SELECT @prev_key = ""
		SELECT @key = STR(h.xfer_no, 16),
			@xfer_no = h.xfer_no,
			@apply_date = h.date_shipped,
			@from_loc = h.from_loc,
			@to_loc = h.to_loc,
			@routing = h.routing,
			@fob_code = h.fob,
			@amt_freight = h.freight
		FROM xfers h, locations f, locations t
		WHERE h.date_shipped IS NOT NULL
		AND CONVERT(char(16), h.xfer_no) NOT IN
			(SELECT src_doc_num FROM gl_glinphdr WHERE src_trx_id = "IVSH")
		AND h.from_loc = f.location
		AND h.to_loc = t.location
		AND f.country_code <> t.country_code
		AND f.country_code IN
			(SELECT country_code FROM gl_glctry)
		AND t.country_code IN
			(SELECT country_code FROM gl_glctry)
		ORDER BY h.xfer_no

		WHILE @@rowcount > 0
		BEGIN
			/* we need to clear values, because those used as INPUT-OUTPUT
			*/
			SELECT @src_trx_id = "", @src_ctrl_num = ""

			/* set header values
			*/
			EXEC adm_setivhdr_sp
				@xfer_no,
				1,
				0, @from_loc,
				0, @to_loc,
				0, @apply_date,
				0, @routing,
				0, @fob_code,
				@src_trx_id	OUTPUT,
				@src_ctrl_num	OUTPUT,
				@is_input_exist	OUTPUT,
				@return_code	OUTPUT

			IF @return_code < 0 OR @return_code = 8100 OR @return_code = 8101
			BEGIN
				ROLLBACK TRANSACTION
				RETURN @return_code
			END

			/* set detail values
			*/
			SELECT @prev_line_id = 0
			SELECT @src_line_id = d.line_no,
				@qty_item = d.shipped,
				@item_code = d.part_no,
				@qty_item = d.shipped,
				@amt_nat = d.cost,
				@unit_code = d.uom
			FROM xfer_list d
			WHERE d.xfer_no = @xfer_no
			ORDER BY d.line_no

			WHILE @@rowcount > 0
			BEGIN
				EXEC adm_setivdet_sp
					@src_trx_id,
					@src_ctrl_num,
					@src_line_id,
					1,
					0, @from_loc,
					0, @to_loc,
					0, @item_code,
					0, @qty_item,
					0, @amt_nat,
					0,
					0, @amt_freight,
					0, @unit_code,
					@return_code	OUTPUT

				IF @return_code < 0 OR @return_code = 8100 OR @return_code = 8101
				BEGIN
					ROLLBACK TRANSACTION
					RETURN @return_code
				END

				SELECT @prev_line_id = @src_line_id
				SELECT @src_line_id = d.line_no,
					@qty_item = d.shipped,
					@item_code = d.part_no,
					@qty_item = d.shipped,
					@amt_nat = d.cost,
					@unit_code = d.uom
				FROM xfer_list d
				WHERE d.xfer_no = @xfer_no
				AND @prev_line_id < d.line_no
				ORDER BY d.line_no
			END

			/* save with permanent numbers
			*/
			SELECT @ctrl_int = @xfer_no, @ext_int = 0,
				@ctrl_str = '',      @ext_str = '', @alt_ctrl_str = ''

			EXEC @return_code = gl_saveinp_sp
				@src_trx_id, @src_ctrl_num, @ctrl_int, @ext_int, @ctrl_str, @ext_str, @alt_ctrl_str,
				@return_code	OUTPUT

			IF @return_code < 0 OR @return_code = 8100 OR @return_code = 8101
			BEGIN
				ROLLBACK TRANSACTION
				RETURN @return_code
			END

			/* cleanup temporary numbers
			*/
			EXEC @return_code = gl_cleaninp_sp @src_trx_id, @src_ctrl_num

			IF @return_code <> 0
			BEGIN
				ROLLBACK TRANSACTION
				RETURN @return_code
			END

			SELECT @prev_key = @key
			SELECT @key = STR(h.xfer_no, 16),
				@xfer_no = h.xfer_no,
				@apply_date = h.date_shipped,
				@from_loc = h.from_loc,
				@to_loc = h.to_loc,
				@routing = h.routing,
				@fob_code = h.fob,
				@amt_freight = h.freight
			FROM xfers h, locations f, locations t
			WHERE h.date_shipped IS NOT NULL
			AND CONVERT(char(16), h.xfer_no) NOT IN
				(SELECT src_doc_num FROM gl_glinphdr WHERE src_trx_id = "IVSH")
			AND @prev_key < STR(h.xfer_no, 16)
			AND h.from_loc = f.location
			AND h.to_loc = t.location
			AND f.country_code <> t.country_code
			AND f.country_code IN
				(SELECT country_code FROM gl_glctry)
			AND t.country_code IN
				(SELECT country_code FROM gl_glctry)
			ORDER BY h.xfer_no
		END
	COMMIT TRANSACTION

	/* Inventory transfer - receiving
	*/
	BEGIN TRANSACTION

		SELECT @prev_key = ""
		SELECT @key = STR(h.xfer_no, 16),
			@xfer_no = h.xfer_no,
			@apply_date = h.date_recvd,
			@from_loc = h.from_loc,
			@to_loc = h.to_loc,
			@routing = h.routing,
			@fob_code = h.fob,
			@amt_freight = h.freight
		FROM xfers h, locations f, locations t
		WHERE h.date_recvd IS NOT NULL
		AND CONVERT(char(16), h.xfer_no) NOT IN
			(SELECT src_doc_num FROM gl_glinphdr WHERE src_trx_id = "IVRV")
		AND h.from_loc = f.location
		AND h.to_loc = f.location
		AND f.country_code <> t.country_code
		AND f.country_code IN
			(SELECT country_code FROM gl_glctry)
		AND t.country_code IN
			(SELECT country_code FROM gl_glctry)
		ORDER BY h.xfer_no

		WHILE @@rowcount > 0
		BEGIN
			/* we need to clear values, because those used as INPUT-OUTPUT
			*/
			SELECT @src_trx_id = "", @src_ctrl_num = ""

			/* set header values
			*/
			EXEC adm_setivhdr_sp
				@xfer_no,
				0,
				0, @from_loc,
				0, @to_loc,
				0, @apply_date,
				0, @routing,
				0, @fob_code,
				@src_trx_id	OUTPUT,
				@src_ctrl_num	OUTPUT,
				@is_input_exist	OUTPUT,
				@return_code	OUTPUT

			IF @return_code < 0 OR @return_code = 8100 OR @return_code = 8101
			BEGIN
				ROLLBACK TRANSACTION
				RETURN @return_code
			END

			/* set detail values
			*/
			SELECT @prev_line_id = 0
			SELECT @src_line_id = d.line_no,
				@item_code = d.part_no,
				@qty_item = d.shipped,
				@amt_nat = d.cost,
				@unit_code = d.uom
			FROM xfer_list d
			WHERE d.xfer_no = @xfer_no
			ORDER BY d.line_no

			WHILE @@rowcount > 0
			BEGIN
				EXEC adm_setivdet_sp
					@src_trx_id,
					@src_ctrl_num,
					@src_line_id,
					0,
					0, @from_loc,
					0, @to_loc,
					0, @item_code,
					0, @qty_item,
					0, @amt_nat,
					0,
					0, @amt_freight,
					0, @unit_code,
					@return_code	OUTPUT

				IF @return_code < 0 OR @return_code = 8100 OR @return_code = 8101
				BEGIN
					ROLLBACK TRANSACTION
					RETURN @return_code
				END

				SELECT @prev_line_id = @src_line_id
				SELECT @src_line_id = d.line_no,
					@item_code = d.part_no,
					@qty_item = d.shipped,
					@amt_nat = d.cost,
					@unit_code = d.uom
				FROM xfer_list d
				WHERE d.xfer_no = @xfer_no
				AND @prev_line_id < d.line_no
				ORDER BY d.line_no
			END

			/* save with permanent numbers
			*/
			SELECT @ctrl_int = @xfer_no, @ext_int = 0,
				@ctrl_str = '',      @ext_str = '', @alt_ctrl_str = ''

			EXEC @return_code = gl_saveinp_sp
				@src_trx_id, @src_ctrl_num, @ctrl_int, @ext_int, @ctrl_str, @ext_str, @alt_ctrl_str,
				@return_code	OUTPUT

			IF @return_code < 0 OR @return_code = 8100 OR @return_code = 8101
			BEGIN
				ROLLBACK TRANSACTION
				RETURN @return_code
			END

			/* cleanup temporary numbers
			*/
			EXEC @return_code = gl_cleaninp_sp @src_trx_id, @src_ctrl_num

			IF @return_code <> 0
			BEGIN
				ROLLBACK TRANSACTION
				RETURN @return_code
			END

			SELECT @prev_key = @key
			SELECT @key = STR(h.xfer_no, 16),
				@xfer_no = h.xfer_no,
				@apply_date = h.date_recvd,
				@from_loc = h.from_loc,
				@to_loc = h.to_loc,
				@routing = h.routing,
				@fob_code = h.fob,
				@amt_freight = h.freight
			FROM xfers h, locations f, locations t
			WHERE h.date_recvd IS NOT NULL
			AND CONVERT(char(16), h.xfer_no) NOT IN
				(SELECT src_doc_num FROM gl_glinphdr WHERE src_trx_id = "IVRV")
			AND @prev_key < STR(h.xfer_no, 16)
			AND h.from_loc = f.location
			AND h.to_loc = t.location
			AND f.country_code <> t.country_code
			AND f.country_code IN
				(SELECT country_code FROM gl_glctry)
			AND t.country_code IN
				(SELECT country_code FROM gl_glctry)
			ORDER BY h.xfer_no
		END
	COMMIT TRANSACTION
	END




SET ROWCOUNT 0  RETURN 0 END 
GO
GRANT EXECUTE ON  [dbo].[gl_pumpinp_sp] TO [public]
GO
