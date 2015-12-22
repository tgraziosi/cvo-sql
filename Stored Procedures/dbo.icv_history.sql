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

CREATE PROCEDURE [dbo].[icv_history] @type smallint, 
			     @response char(255) = '',  
			     @trx_ctrl_num char(16) = '',  
			     @uname char(30) = '',
			     @account char(30) = '',  
			     @ccmonth int = 0,  
			     @ccyear int = 0,  
			     @amount float = 0.0,  
			     @trx_type char(2) = '',  
			     @authorization_code char(30) = ''
AS
INSERT INTO icv_cchistory
	(entry_date,
	 entry_type,
	 response,
	 trx_ctrl_num,
	 uname,
	 account,
	 ccmonth,
	 ccyear,
	 amount,
	 trx_type,
	 authorization_code)
 VALUES 
	(GETDATE(), 
	 @type, 
	 @response,
	 @trx_ctrl_num,
	 @uname,
	 dbo.CCAMask_fn(@account),
	 @ccmonth,
	 @ccyear,
	 @amount,
	 @trx_type,
	 @authorization_code)
IF @@ROWCOUNT = 1
BEGIN
	RETURN 0
END
ELSE
BEGIN
	RETURN -1001
END

GO
GRANT EXECUTE ON  [dbo].[icv_history] TO [public]
GO
