SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\CM\PROCS\cmpostfl.SPv - e7.2.2 : 1.3
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                



CREATE PROC [dbo].[cmpostfl_sp]	
		@ctrl_from char(16),	
		@ctrl_to char(16),
		@accnt_from char(32),
		@accnt_to char(32),
		@date_from int, 
		@date_to int
AS

DECLARE
	@tran_started	tinyint

	IF( @@trancount = 0 )
	BEGIN
		BEGIN TRAN
		SELECT @tran_started = 1
	END

	UPDATE	cmmanhdr 
	SET	posted_flag = ( SELECT max(posted_flag) + 2
 FROM cmmanhdr )
 WHERE 	date_applied >= @date_from AND date_applied <= @date_to	 
	 AND 	trx_ctrl_num >= @ctrl_from AND trx_ctrl_num <= @ctrl_to		 
	 AND	cash_acct_code >= @accnt_from AND cash_acct_code <= @accnt_to 
	 AND	hold_flag = 0 
	 AND	posted_flag = 0 
	
	
	IF @@ROWCOUNT > 0
		SELECT	MAX(posted_flag)
		FROM	cmmanhdr
	ELSE
		SELECT 0

	IF( @tran_started = 1 )
	BEGIN
		COMMIT TRAN
		SELECT @tran_started = 0
	END
GO
GRANT EXECUTE ON  [dbo].[cmpostfl_sp] TO [public]
GO
