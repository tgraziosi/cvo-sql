SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                



















































































































































































































































  



					  

























































 














































































































































































































































































































                       

































































CREATE PROCEDURE	[dbo].[glpsrcvrib_sp] 
			@process_ctrl_num	varchar(16),
			@batch_code		varchar(16),
			@company_code		varchar(8)
AS

			SELECT journal_ctrl_num, trx_type
			INTO	
				#gltrx_io
			FROM  gltrx
			WHERE	batch_code = @batch_code
				AND	company_code = @company_code
				AND	process_group_num = @process_ctrl_num
				AND 	interbranch_flag =1
				AND 	posted_flag IN (0,-1)


			SELECT DISTINCT  h.id,h.trx_ctrl_num 
				INTO #ibhdr
				FROM gltrxdet d	
					INNER JOIN #gltrx_io g
						ON g.journal_ctrl_num = d.journal_ctrl_num
					INNER JOIN ibhdr h
						ON h.trx_ctrl_num = d.document_1
				WHERE d.seq_ref_id = -1 and d.posted_flag IN (0,-1)

			
			DELETE gltrxdet
			FROM gltrxdet  d
				INNER JOIN #gltrx_io h
					ON d.journal_ctrl_num = h.journal_ctrl_num
			WHERE  d.seq_ref_id = -1
		
			DELETE ibhdr 
			FROM ibhdr h
				INNER JOIN #ibhdr t
					ON	h.id=t.id

			DELETE ibdet
			FROM ibdet d
				INNER JOIN #ibhdr t
					ON	d.id=t.id 
		
			DELETE ibtax 
			FROM ibtax x
			INNER JOIN #ibhdr t
					ON	x.id=t.id 

			DELETE iblink 
			FROM iblink b
				INNER JOIN #ibhdr t
					ON	b.id=t.id 

			DELETE ibifc 
			FROM ibifc f
				INNER JOIN #gltrx_io t
					ON	f.link1=t.journal_ctrl_num 
			
			


			INSERT INTO ibifc  
			            (timestamp,                   id,                                 date_entered,                date_applied,
			            trx_type,                      controlling_org_id,          detail_org_id,     amount,                        
			            currency_code,  tax_code,                      recipient_code,  originator_code,             
			            tax_payable_code,         tax_expense_code,        state_flag,         process_ctrl_num,
			            link1,                link2,                link3,    username,         reference_code)
			          
			            SELECT NULL,                          NEWID(),                      -1,                                0,
			            h. trx_type,                                  '',                                  '',                                  0.0,
			             '',                                 '',                                  '',                                  '',
			             '',                                 '',                                  0,                                 '',
			             h.journal_ctrl_num,          '',                                  '',                                  SUSER_SNAME(),       ''
			            FROM   #gltrx_io h


			DROP TABLE #gltrx_io
			DROP TABLE #ibhdr
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glpsrcvrib_sp] TO [public]
GO
