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
































CREATE PROC	[dbo].[arexistdup_sp]	
			@cust_code	varchar(8),
			@doc_ctrl_num	varchar(16),
			@trx_ctrl_num	varchar(16)
AS

DECLARE	@exist	Int

SELECT	@exist = 0

    IF EXISTS(SELECT doc_ctrl_num FROM arcpcust_vw WHERE doc_ctrl_num = @doc_ctrl_num AND customer_code = @cust_code)
	BEGIN
	    SELECT @exist = 1 
	END

   IF @exist=0
   BEGIN
	IF EXISTS(SELECT doc_ctrl_num FROM arinppyt WHERE doc_ctrl_num = @doc_ctrl_num AND customer_code = @cust_code AND trx_ctrl_num <> @trx_ctrl_num )
	SELECT @exist = 1 
   END
   
   IF @exist=0
   BEGIN
	IF EXISTS(SELECT doc_ctrl_num FROM arinptmp WHERE doc_ctrl_num = @doc_ctrl_num AND customer_code = @cust_code  )
	SELECT @exist = 1 
   END	

   IF @exist=0
   BEGIN
	IF EXISTS(SELECT doc_ctrl_num FROM artrx_all WHERE trx_type = 2111 AND void_flag = 0 
                                                        AND	(artrx_all.payment_type = 1 OR artrx_all.payment_type = 3 AND amt_on_acct < amt_net)
                                                        AND doc_ctrl_num = @doc_ctrl_num AND customer_code = @cust_code)
	SELECT @exist = 1 
   END

   IF @exist=0
   BEGIN
	IF EXISTS(SELECT doc_ctrl_num FROM arinppyt_all WHERE doc_ctrl_num = @doc_ctrl_num AND customer_code = @cust_code AND trx_ctrl_num <> @trx_ctrl_num)
	SELECT @exist = 1 
   END

   IF @exist=0
   BEGIN
	IF EXISTS(SELECT 1 FROM sminstap_vw WHERE app_id = 18000 and company_id = (select company_id from glco))
	BEGIN
		IF EXISTS(	SELECT doc_ctrl_num 
				FROM orders a, ord_payment b 
				WHERE b.doc_ctrl_num = @doc_ctrl_num 
				AND a.cust_code = @cust_code 
				AND a.order_no = b.order_no 
				AND a.status <> 'V')
		BEGIN
			SELECT @exist = 1 
		END
	END
   END


SELECT	@exist



GO
GRANT EXECUTE ON  [dbo].[arexistdup_sp] TO [public]
GO
