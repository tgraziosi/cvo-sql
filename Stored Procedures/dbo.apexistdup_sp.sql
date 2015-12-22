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

CREATE PROC	[dbo].[apexistdup_sp]	
			@vendor_code	varchar(12),
			@doc_ctrl_num	varchar(16),
			@trx_ctrl_num	varchar(16)
AS

DECLARE	
		@exist	Int

SELECT	@exist = 0

IF @trx_ctrl_num  IS NULL 
   BEGIN	
	    IF EXISTS(SELECT doc_ctrl_num FROM apvohdr WHERE doc_ctrl_num = @doc_ctrl_num AND vendor_code = @vendor_code)
	    SELECT @exist = 1 
	    ELSE 
	    SELECT @exist = 0
	
	   IF @exist=0
	   BEGIN
		IF EXISTS(SELECT doc_ctrl_num FROM apinpchg_vw WHERE doc_ctrl_num = @doc_ctrl_num AND vendor_code = @vendor_code  )
		SELECT @exist = 1 
		ELSE 
		SELECT @exist = 0
	   END
	   
	   	
	   IF @exist=0
	   BEGIN
		IF EXISTS(SELECT doc_ctrl_num FROM apvohdr_all WHERE  doc_ctrl_num = @doc_ctrl_num AND vendor_code = @vendor_code)
		SELECT @exist = 1 
		ELSE 
		SELECT @exist = 0
	   END
	
	   IF @exist=0
	   BEGIN
		IF EXISTS(SELECT doc_ctrl_num FROM apinpchg_all WHERE trx_type = 4091 AND doc_ctrl_num = @doc_ctrl_num AND vendor_code = @vendor_code )
		SELECT @exist = 1 
		ELSE 
		SELECT @exist = 0
	   END
  END
ELSE
 BEGIN
 	IF EXISTS(SELECT doc_ctrl_num FROM apvohdr WHERE doc_ctrl_num = @doc_ctrl_num AND vendor_code = @vendor_code)
	    SELECT @exist = 1 
	    ELSE 
	    SELECT @exist = 0
	
	   IF @exist=0
	   BEGIN
		IF EXISTS(SELECT doc_ctrl_num FROM apinpchg_vw WHERE doc_ctrl_num = @doc_ctrl_num AND vendor_code = @vendor_code AND trx_ctrl_num <> @trx_ctrl_num )
		SELECT @exist = 1 
		ELSE 
		SELECT @exist = 0
	   END
	   
	   	
	   IF @exist=0
	   BEGIN
		IF EXISTS(SELECT doc_ctrl_num FROM apvohdr_all WHERE  doc_ctrl_num = @doc_ctrl_num AND vendor_code = @vendor_code)
		SELECT @exist = 1 
		ELSE 
		SELECT @exist = 0
	   END
	
	   IF @exist=0
	   BEGIN
		IF EXISTS(SELECT doc_ctrl_num FROM apinpchg_all WHERE trx_type = 4091 AND doc_ctrl_num = @doc_ctrl_num AND vendor_code = @vendor_code AND trx_ctrl_num <> @trx_ctrl_num )
		SELECT @exist = 1 
		ELSE 
		SELECT @exist = 0
	   END
	
 END   


SELECT	@exist

/**/                                              
GO
GRANT EXECUTE ON  [dbo].[apexistdup_sp] TO [public]
GO
