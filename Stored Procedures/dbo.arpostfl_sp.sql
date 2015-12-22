SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\PROCS\arpostfl.SPv - e7.2.2 : 1.5
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                



CREATE PROC [dbo].[arpostfl_sp]	@from_date_doc int,	@thru_date_doc int,
			@from_doc_num char(16),	@thru_doc_num char(16),
			@from_cust_code char(8),@thru_cust_code char(8),
			@trx_type smallint
AS

declare @printed smallint


IF @trx_type = 2021 OR @trx_type = 2051
	SELECT @printed = 0
ELSE
	SELECT @printed = 1
IF @trx_type = 2051
BEGIN
BEGIN TRAN
		
	UPDATE 	arinpchg 
	SET 	posted_flag = ( SELECT MAX(posted_flag + 10) FROM arinpchg ) 
	WHERE 	date_doc BETWEEN @from_date_doc AND @thru_date_doc
	AND 	trx_ctrl_num BETWEEN @from_doc_num AND @thru_doc_num
	AND 	customer_code BETWEEN @from_cust_code AND @thru_cust_code
	AND 	trx_type = @trx_type 
	AND 	printed_flag IN ( @printed, 1 )
	AND 	hold_flag = 0 
	
	
 IF @@ROWCOUNT > 0
		SELECT MAX(posted_flag)
		FROM arinpchg
	ELSE
		SELECT 0
	
COMMIT TRAN
END
ELSE
BEGIN
BEGIN TRAN
		
	UPDATE 	arinpchg 
	SET 	posted_flag = ( SELECT MAX(posted_flag + 10) FROM arinpchg ) 
	WHERE 	date_doc BETWEEN @from_date_doc AND @thru_date_doc
	AND 	doc_ctrl_num BETWEEN @from_doc_num AND @thru_doc_num
	AND 	customer_code BETWEEN @from_cust_code AND @thru_cust_code
	AND 	trx_type = @trx_type 
	AND 	printed_flag IN ( @printed, 1 )
	AND 	hold_flag = 0 
	
	
 IF @@ROWCOUNT > 0
		SELECT MAX(posted_flag)
		FROM arinpchg
	ELSE
		SELECT 0
	
COMMIT TRAN
END



/**/                                              
GO
GRANT EXECUTE ON  [dbo].[arpostfl_sp] TO [public]
GO
