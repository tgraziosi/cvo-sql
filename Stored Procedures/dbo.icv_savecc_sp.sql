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

create procedure [dbo].[icv_savecc_sp] 	@payment_code char(8), 
				@customer_code char(8), 
				@prompt1 varchar(255),
				@prompt2 varchar(255),
				@prompt3 varchar(255),
				@prompt4 varchar(255),
				@trx_ctrl_num varchar(16),
				@trx_type   smallint,
				@order_no   int,
				@order_ext  int
AS

	UPDATE icv_ccinfo
	   SET prompt1 = @prompt1,
		prompt2 = @prompt2,
		prompt3 = @prompt3,
		prompt4 = @prompt4,
		trx_ctrl_num = @trx_ctrl_num,
		trx_type = @trx_type,
		order_no = @order_no,
		order_ext = @order_ext
	 WHERE payment_code = @payment_code
	   AND customer_code = @customer_code

	return 0


GO
GRANT EXECUTE ON  [dbo].[icv_savecc_sp] TO [public]
GO
