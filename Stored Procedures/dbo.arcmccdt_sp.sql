SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*
              Confidential Information
   Limited Distribution of Authorized Persons Only
   Created 2001 and Protected as Unpublished Work
         Under the U.S. Copyright Act of 1976
Copyright (c) 2001 Epicor Software Corporation, 2001
                 All Rights Reserved 
 */
                       CREATE PROC [dbo].[arcmccdt_sp]  @b_sys_date int, @b_trx_type smallint, @b_trx_num char(32), 
 @b_doc_num char(32), @b_gl_jcc char(32), @b_date_applied int,  @b_posted_flag smallint, @b_proc_key int, @b_user_id int 
AS    DECLARE @error_occured int, @E_ARCMCCDT_FAILED int SELECT @error_occured = 0 
      INSERT artrxcdt(  doc_ctrl_num, trx_ctrl_num, sequence_id, trx_type,  location_code, item_code, bulk_flag, date_entered, 
 date_posted, date_applied, line_desc, qty_ordered,  qty_shipped, unit_code, unit_price, weight, 
 amt_cost, serial_id, tax_code, gl_rev_acct,  discount_prc,  discount_amt, rma_num, return_code, 
 qty_returned, new_gl_rev_acct, disc_prc_flag, cust_po ) SELECT  doc_ctrl_num, trx_ctrl_num, sequence_id, trx_type, 
 location_code, item_code, bulk_flag, date_entered,  @b_sys_date, @b_date_applied,line_desc, qty_ordered, 
 qty_shipped, unit_code, unit_price, weight,  0, serial_id, tax_code, gl_rev_acct, 
 ( discount_amt / ( qty_shipped * unit_price ) ) * 100,  discount_amt, rma_num, return_code, 
 qty_returned, new_gl_rev_acct,  disc_prc_flag, ISNULL(cust_po, '') FROM arinpcdt 
WHERE trx_type = @b_trx_type  AND trx_ctrl_num = @b_trx_num  AND qty_shipped != 0.0 
 AND unit_price != 0.0  AND disc_prc_flag = 0 IF @@error != 0  SELECT @error_occured = 1 
   INSERT artrxcdt(  doc_ctrl_num, trx_ctrl_num, sequence_id, trx_type,  location_code, item_code, bulk_flag, date_entered, 
 date_posted, date_applied, line_desc, qty_ordered,  qty_shipped, unit_code, unit_price, weight, 
 amt_cost, serial_id, tax_code, gl_rev_acct,  discount_prc,  discount_amt,  rma_num, return_code, 
 qty_returned, new_gl_rev_acct, disc_prc_flag ) SELECT  doc_ctrl_num, trx_ctrl_num, sequence_id, trx_type, 
 location_code, item_code, bulk_flag, date_entered,  @b_sys_date, @b_date_applied,line_desc, qty_ordered, 
 qty_shipped, unit_code, unit_price, weight,  0, serial_id, tax_code, gl_rev_acct, 
 discount_amt,  ( discount_amt * qty_shipped * unit_price ) / 100,  rma_num, return_code, 
 qty_returned, new_gl_rev_acct,  disc_prc_flag FROM arinpcdt WHERE trx_type = @b_trx_type 
 AND trx_ctrl_num = @b_trx_num  AND qty_shipped != 0.0  AND unit_price != 0.0  AND disc_prc_flag = 1 
IF @@error != 0  SELECT @error_occured = 1    INSERT artrxcdt(  doc_ctrl_num, trx_ctrl_num, sequence_id, trx_type, 
 location_code, item_code, bulk_flag, date_entered,  date_posted, date_applied, line_desc, qty_ordered, 
 qty_shipped, unit_code, unit_price, weight,  amt_cost, serial_id, tax_code, gl_rev_acct, 
 discount_prc,  discount_amt,  rma_num, return_code,  qty_returned, new_gl_rev_acct, disc_prc_flag, cust_po ) 
SELECT  doc_ctrl_num, trx_ctrl_num, sequence_id, trx_type,  location_code, item_code, bulk_flag, date_entered, 
 @b_sys_date, @b_date_applied,line_desc, qty_ordered,  qty_shipped, unit_code, unit_price, weight, 
 0, serial_id, tax_code, gl_rev_acct,  0,  discount_amt,  rma_num, return_code,  qty_returned, new_gl_rev_acct, 
 disc_prc_flag, ISNULL(cust_po, '') FROM arinpcdt WHERE trx_type = @b_trx_type  AND trx_ctrl_num = @b_trx_num 
 AND (( qty_shipped = 0.0 ) OR ( unit_price = 0.0 ))  AND disc_prc_flag = 0 IF @@error != 0 
 SELECT @error_occured = 1    INSERT artrxcdt(  doc_ctrl_num, trx_ctrl_num, sequence_id, trx_type, 
 location_code, item_code, bulk_flag, date_entered,  date_posted, date_applied, line_desc, qty_ordered, 
 qty_shipped, unit_code, unit_price, weight,  amt_cost, serial_id, tax_code, gl_rev_acct, 
 discount_prc,  discount_amt,  rma_num, return_code,  qty_returned, new_gl_rev_acct, disc_prc_flag, cust_po ) 
SELECT  doc_ctrl_num, trx_ctrl_num, sequence_id, trx_type,  location_code, item_code, bulk_flag, date_entered, 
 @b_sys_date, @b_date_applied,line_desc, qty_ordered,  qty_shipped, unit_code, unit_price, weight, 
 0, serial_id, tax_code, gl_rev_acct,  discount_amt,  0,  rma_num, return_code,  qty_returned, new_gl_rev_acct, 
 disc_prc_flag, ISNULL(cust_po, '') FROM arinpcdt WHERE trx_type = @b_trx_type  AND trx_ctrl_num = @b_trx_num 
 AND (( qty_shipped = 0.0 ) OR ( unit_price = 0.0 ))  AND disc_prc_flag = 1 IF @@error != 0 
 SELECT @error_occured = 1 IF @error_occured = 1 BEGIN  SELECT @E_ARCMCCDT_FAILED = e_code 
 FROM arerrdef  WHERE e_sdesc = "E_ARCMCCDT_FAILED"  AND client_id = "POSTCM"  RETURN @E_ARCMCCDT_FAILED 
END ELSE  RETURN 0 

 /**/
GO
GRANT EXECUTE ON  [dbo].[arcmccdt_sp] TO [public]
GO
