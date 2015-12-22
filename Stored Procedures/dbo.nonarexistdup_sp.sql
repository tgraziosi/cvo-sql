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

CREATE PROC	[dbo].[nonarexistdup_sp]	
			@cust_code	varchar(8),
			@doc_ctrl_num	varchar(16)
			
AS

DECLARE	
		@exist	Int

SELECT	@exist = 0

    IF EXISTS(SELECT doc_ctrl_num FROM arcpcust_vw WHERE doc_ctrl_num = @doc_ctrl_num AND customer_code = @cust_code)
    SELECT @exist = 1 
    ELSE 
    SELECT @exist = 0

   IF @exist=0
   BEGIN
	IF EXISTS(SELECT doc_ctrl_num FROM arinppyt WHERE doc_ctrl_num = @doc_ctrl_num AND customer_code = @cust_code )
	SELECT @exist = 1 
	ELSE 
	SELECT @exist = 0
   END
   
   IF @exist=0
   BEGIN
	IF EXISTS(SELECT doc_ctrl_num FROM arinptmp WHERE doc_ctrl_num = @doc_ctrl_num AND customer_code = @cust_code  )
	SELECT @exist = 1 
	ELSE 
	SELECT @exist = 0
   END	

   IF @exist=0
   BEGIN
	IF EXISTS(SELECT doc_ctrl_num FROM artrx_all WHERE trx_type = 2111 AND void_flag = 0 
                                                        AND	(artrx_all.payment_type = 1 OR artrx_all.payment_type = 3 AND amt_on_acct < amt_net)
                                                        AND doc_ctrl_num = @doc_ctrl_num AND customer_code = @cust_code)
	SELECT @exist = 1 
	ELSE 
	SELECT @exist = 0
   END

   IF @exist=0
   BEGIN
	IF EXISTS(SELECT doc_ctrl_num FROM arinppyt_all WHERE doc_ctrl_num = @doc_ctrl_num AND customer_code = @cust_code )
	SELECT @exist = 1 
	ELSE 
	SELECT @exist = 0
   END

SELECT	@exist



/**/                                              
GO
GRANT EXECUTE ON  [dbo].[nonarexistdup_sp] TO [public]
GO
