SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*
              Confidential Information
   Limited Distribution of Authorized Persons Only
   Created 1996 and Protected as Unpublished Work
         Under the U.S. Copyright Act of 1976
Copyright (c) 1996 Platinum Software Corporation, 1996
                 All Rights Reserved 
 */
                                                           CREATE PROC [dbo].[mtpld_sp] @match_ctrl_num varchar(16), 
 @vendor_code varchar(12),  @po_num varchar(16),   
 @msg_no smallint OUTPUT, @receipt_ctrl_num varchar(16) AS DECLARE  @msg varchar(40),  @hold_flag smallint,  @invoiced_full_flag smallint , 
   @po_ctrl_num varchar(16),  @return_code smallint,  @unrecv_line_exists smallint, 
 @receipt_exists smallint,  @tax_code varchar(8),  @max_text varchar(10),  @min_text varchar(10) 
BEGIN TRANSACTION        SELECT @tax_code = tax_code  FROM apvend  WHERE vendor_code = @vendor_code 
SELECT @receipt_ctrl_num = h.receipt_ctrl_num,  @po_ctrl_num = h.po_ctrl_num 
 FROM epinvhdr h  WHERE h.vendor_code = @vendor_code  AND h.hold_flag = 0  AND h.invoiced_full_flag = 0 
 AND h.po_ctrl_num = @po_num  AND h.receipt_ctrl_num = @receipt_ctrl_num          
         EXEC @return_code = mtlinpld_sp @match_ctrl_num,  @po_num,  @receipt_ctrl_num, 
 @tax_code,  @msg_no OUTPUT  IF @return_code != 0  BEGIN  ROLLBACK TRANSACTION  RETURN -1 
 END                            COMMIT TRANSACTION  RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[mtpld_sp] TO [public]
GO
