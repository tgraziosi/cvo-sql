SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\PROCS\aprndpyt.SPv - e7.2.2 : 1.4
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                








CREATE PROCEDURE [dbo].[aprndpyt_sp]

	@r_trx_type smallint,	@r_trx_num varchar(32)

AS

DECLARE	@max_pos smallint


SELECT	@max_pos = 6


UPDATE	apinppyt
SET	amt_payment = (SIGN(amt_payment) * ROUND(ABS(amt_payment) + 0.0000001, @max_pos)),
	amt_on_acct = (SIGN(amt_on_acct) * ROUND(ABS(amt_on_acct) + 0.0000001, @max_pos))
WHERE	trx_ctrl_num = @r_trx_num
 AND	trx_type = @r_trx_type



UPDATE	apinppdt
SET	amt_applied	= (SIGN(amt_applied) * ROUND(ABS(amt_applied) + 0.0000001, @max_pos)),	
	amt_disc_taken	= (SIGN(amt_disc_taken) * ROUND(ABS(amt_disc_taken) + 0.0000001, @max_pos))
WHERE	trx_ctrl_num = @r_trx_num
 AND	trx_type = @r_trx_type



GO
GRANT EXECUTE ON  [dbo].[aprndpyt_sp] TO [public]
GO
