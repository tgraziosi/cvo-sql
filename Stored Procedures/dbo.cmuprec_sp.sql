SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\CM\PROCS\cmuprec.SPv - e7.2.2 : 1.5
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                




CREATE PROC [dbo].[cmuprec_sp] @cash_acct_code varchar(32)
AS
	DECLARE @rec_id int

	SELECT @rec_id = rec_id
	FROM cmrechst
	WHERE cash_acct_code = @cash_acct_code
	AND closed_flag = 0

 BEGIN TRAN

	UPDATE cminpdtl
	SET closed_flag = 1,
		rec_id = @rec_id
	FROM cminpdtl
	WHERE cminpdtl.cash_acct_code = @cash_acct_code
	AND cminpdtl.reconciled_flag = 1
	AND cminpdtl.closed_flag = 0

	UPDATE cmrechst
	SET closed_flag = 1
	WHERE cash_acct_code = @cash_acct_code
	AND closed_flag = 0


 COMMIT TRAN
GO
GRANT EXECUTE ON  [dbo].[cmuprec_sp] TO [public]
GO
