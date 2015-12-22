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




  
  


 







CREATE VIEW [dbo].[gltrx_io_vw] AS
SELECT 	g1.journal_ctrl_num,
	g1.org_id, 
  	g1.journal_type,
  	g1.journal_description,
	app_title = t2.app_name,
  	t3.trx_type_desc,
  	posted_flag = case g1.posted_flag
  		when 0 then 'No'
  		when 1 then 'Yes'
  	end,
	g1.date_applied, 
  	g1.date_posted,
	reversing_flag = case g1.reversing_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,
  	repeating_flag = case g1.repeating_flag
  		when 0 then 'No'
  		when 1 then 'Yes'
  	end,
	recurring_flag = case g1.recurring_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,
  	hold_flag = case g1.hold_flag
  		when 0 then 'No'
  		when 1 then 'Yes'
  	end,
	intercompany_flag = case g1.intercompany_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,
	interbranch_flag = case g1.interbranch_flag  
	  when 0 then 'No'  
	  when 1 then 'Yes'  
	end, 
	g1.source_company_code ,

	x_date_applied=g1.date_applied, 
 	x_date_posted=g1.date_posted,
	'source'=1, 'link_journal_ctrl_num'=g1.journal_ctrl_num
  FROM gltrxlist g1, glapp_vw t2, gltrxtyp t3
 WHERE g1.app_id = t2.app_id
   AND g1.trx_type = t3.trx_type
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[gltrx_io_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[gltrx_io_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[gltrx_io_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[gltrx_io_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[gltrx_io_vw] TO [public]
GO
