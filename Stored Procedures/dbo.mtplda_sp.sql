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











































































CREATE PROC [dbo].[mtplda_sp]   @match_ctrl_num varchar(16), 
			@vendor_code    varchar(12),
			@currency_code  varchar(8)
AS
DECLARE   
	@msg_no             smallint,
	@return_code        smallint,
	@tax_code           varchar(8),
	@receipt_ctrl_num varchar(16), 
	@po_ctrl_num varchar(16)

BEGIN TRANSACTION 
   	
	
	
	
	SELECT @tax_code = tax_code
	FROM	apvend
	WHERE	vendor_code = @vendor_code
	
	


	DELETE #epmchdtl

	DECLARE receipts CURSOR FOR
	SELECT h.receipt_ctrl_num,
	       h.po_ctrl_num              
	FROM   epinvhdr h
	WHERE  h.vendor_code = @vendor_code
	AND    h.hold_flag = 0
	AND    h.invoiced_full_flag = 0
	AND    h.nat_cur_code = @currency_code
	AND    h.validated_flag = 1

	OPEN receipts

	FETCH NEXT FROM receipts into @receipt_ctrl_num, @po_ctrl_num

	WHILE @@FETCH_STATUS = 0
	BEGIN

		
		
		
            	EXEC @return_code = mtlinpld_sp	        @match_ctrl_num,
            						@po_ctrl_num,
               					        @receipt_ctrl_num,
							@tax_code,
							@msg_no OUTPUT
	      IF @return_code != 0
              BEGIN
			ROLLBACK TRANSACTION 
			RETURN -1
              END

	FETCH NEXT FROM receipts into @receipt_ctrl_num, @po_ctrl_num

	END
  
	CLOSE receipts
	DEALLOCATE receipts

   
COMMIT TRANSACTION  
       


RETURN  0



GO
GRANT EXECUTE ON  [dbo].[mtplda_sp] TO [public]
GO
