SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO





CREATE  PROCEDURE [dbo].[cminpsav_sp]  
				
AS

BEGIN

	DECLARE @tran_started 		smallint,
		@result           	smallint

	SELECT  @tran_started = 0
	
	




	IF ( @@trancount = 0 )
	BEGIN
		BEGIN TRANSACTION
		SELECT  @tran_started = 1
	END
	
	INSERT  cminpdtl (      
		timestamp,
		rec_id,
		trx_type,		
		trx_ctrl_num,		
		doc_ctrl_num,		
		date_document,
		date_cleared,		
		description,
		document1,
		document2,		
		cash_acct_code,		
		amount_book,		
		reconciled_flag,	
		closed_flag,	
		void_flag,		
		date_applied,
		cleared_type,
		org_id	)
	SELECT      
		NULL,
		0,
		trx_type,		
		trx_ctrl_num,		
		doc_ctrl_num,		
		date_document,
		0,		
		description,
		document1,
		document2,		
		cash_acct_code,		
		amount_book,		
		reconciled_flag,	
		closed_flag,	
		void_flag,		
		date_applied,
		cleared_type,
		org_id
	FROM    #cminpdtl

	

	


	UPDATE 	cminpdtl 
	SET 	void_flag = 1,
			reconciled_flag = 1
	FROM	cminpdtl, #cminpdtl t
	WHERE 	cminpdtl.trx_ctrl_num 	= t.apply_to_trx_num 
	  AND 	cminpdtl.doc_ctrl_num 	= t.apply_to_doc_num 
	  AND 	cminpdtl.cash_acct_code 	= t.cash_acct_code
	  AND   cminpdtl.trx_type  	= t.apply_to_trx_type
	  AND	cminpdtl.void_flag 	= 0 
	  AND   t.void_flag	= 1




	






	EXEC    @result = cminpusv_sp
	IF ( @result != 0 )
		RETURN  @result

	delete #cminpdtl
		
	IF ( @tran_started = 1 )
	BEGIN
		COMMIT TRANSACTION
		SELECT  @tran_started = 0
	END
	




END
GO
GRANT EXECUTE ON  [dbo].[cminpsav_sp] TO [public]
GO
