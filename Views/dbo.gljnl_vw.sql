SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2002 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2002 Epicor Software Corporation, 2002    
                  All Rights Reserved                    
*/                                                




  
  



CREATE VIEW [dbo].[gljnl_vw] AS
 SELECT 
  	t1.journal_ctrl_num,
	t1.org_id, 
  	t1.journal_type,
  	t1.journal_description,
	app_title = t2.app_name,
  	t3.trx_type_desc,
  	posted_flag = case t1.posted_flag
  		when 0 then 'No'
  		when 1 then 'Yes'
  	end,
	t1.date_applied, 
  	t1.date_posted,
	reversing_flag = case t1.reversing_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,
  	repeating_flag = case t1.repeating_flag
  		when 0 then 'No'
  		when 1 then 'Yes'
  	end,
	recurring_flag = case t1.recurring_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,
  	hold_flag = case t1.hold_flag
  		when 0 then 'No'
  		when 1 then 'Yes'
  	end,
	intercompany_flag = case t1.intercompany_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,
	interbranch_flag = case t1.interbranch_flag
		when 0 then 'No'
		when 1 then 'Yes'
		when 2 then 'Yes'
	end,
	t1.source_company_code ,

	x_date_applied=t1.date_applied, 
 	x_date_posted=t1.date_posted

 
  
  FROM 
  	gltrxlist t1,
	glapp_vw t2,
	gltrxtyp t3

  WHERE t1.app_id = t2.app_id
	AND  t1.trx_type = t3.trx_type

GO
GRANT REFERENCES ON  [dbo].[gljnl_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[gljnl_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[gljnl_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[gljnl_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[gljnl_vw] TO [public]
GO
