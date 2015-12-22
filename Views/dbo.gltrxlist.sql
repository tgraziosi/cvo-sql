SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2008 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2008 Epicor Software Corporation, 2008    
                  All Rights Reserved                    
*/                                                

                                             



CREATE VIEW [dbo].[gltrxlist]
	AS
	SELECT timestamp, journal_type, a.journal_ctrl_num, journal_description, date_entered, date_applied,
		recurring_flag, repeating_flag, reversing_flag, hold_flag, posted_flag, date_posted, source_batch_code, 
		batch_code, type_flag, intercompany_flag, company_code, app_id, home_cur_code, document_1, trx_type, 
		user_id, source_company_code, process_group_num, oper_cur_code, org_id, interbranch_flag 
	FROM gltrx_all a inner join 
		(
			select journal_ctrl_num 
			from gltrxdet left outer join Organization on (gltrxdet.org_id = Organization.organization_id)
			, glco
			group by  gltrxdet.journal_ctrl_num
			having sum(CASE WHEN offset_flag = 0 OR posted_flag = 1 THEN 1 ELSE 0 END) = 
					sum(CASE WHEN isnull(Organization.organization_id,'0') = '0' 
					and gltrxdet.rec_company_code != glco.company_code THEN 0 ELSE 1 END)
		)
		b  on (b.journal_ctrl_num = a.journal_ctrl_num)
	WHERE 	
		EXISTS( SELECT 1 FROM org_org_vw WHERE organization_id = org_id )				 
		OR posted_flag = 1
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[gltrxlist] TO [public]
GO
GRANT SELECT ON  [dbo].[gltrxlist] TO [public]
GO
GRANT INSERT ON  [dbo].[gltrxlist] TO [public]
GO
GRANT DELETE ON  [dbo].[gltrxlist] TO [public]
GO
GRANT UPDATE ON  [dbo].[gltrxlist] TO [public]
GO
