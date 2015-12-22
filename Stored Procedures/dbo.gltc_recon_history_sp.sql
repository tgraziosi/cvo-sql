SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2006 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2006 Epicor Software Corporation, 2006    
                  All Rights Reserved                    
*/                                  


CREATE PROCEDURE [dbo].[gltc_recon_history_sp]
AS
BEGIN

declare @tot int
	
set rowcount 1
	select @tot = count(trx_ctrl_num)  from gltcrecon
	where (posted_flag = 1 and remote_state = 3)
		OR (posted_flag = 2 and remote_state = 0) 
		OR (posted_flag = 2 and remote_state = 4)
set rowcount 0

if @tot > 0 begin
		insert gltcrecon_history 
		select null, trx_ctrl_num, trx_type, doc_ctrl_num,
		app_id, posted_flag, remote_doc_id, remote_state,
		reconciled_flag, amt_gross, amt_tax, remote_amt_gross, remote_amt_tax,
		customervendor_code, date_doc, reconciliated_date
		from gltcrecon
		where (posted_flag = 1 and remote_state = 3)
			OR (posted_flag = 2 and remote_state = 0) 
			OR (posted_flag = 2 and remote_state = 4)
	
		delete from gltcrecon
		where (posted_flag = 1 and remote_state = 3)
			OR (posted_flag = 2 and remote_state = 0) 
			OR (posted_flag = 2 and remote_state = 4)
	end		
		
END
/**/                                              

GO
GRANT EXECUTE ON  [dbo].[gltc_recon_history_sp] TO [public]
GO
