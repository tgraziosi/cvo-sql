SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\PROCS\arcrtran.SPv - e7.2.2 : 1.3
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                



CREATE PROC [dbo].[arcrtran_sp]	 @trx_ctrl_num char(16),
 @customer_code char(8), @cash_acct_code char(32)

AS
IF EXISTS( SELECT * from arcrtran WHERE trx_ctrl_num = @trx_ctrl_num )
 UPDATE arcrtran 
 SET customer_code = @customer_code,
 cash_acct_code = @cash_acct_code
 WHERE
 trx_ctrl_num = @trx_ctrl_num 
ELSE
 INSERT arcrtran
 VALUES ( NULL, @trx_ctrl_num, @customer_code, @cash_acct_code)


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[arcrtran_sp] TO [public]
GO
