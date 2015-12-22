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




  
  



CREATE VIEW [dbo].[gllin_vw] AS
 SELECT 
  	t1.journal_ctrl_num,
	t1.org_id, 
	t2.journal_type,					-- CVO
  	t2.date_applied,
  	t1.sequence_id,
	t1.rec_company_code,
  	cast(t1.account_code as varchar(36)) as account_code, 
  	t1.description,
	t1.document_1,
	t1.document_2,
	t1.nat_cur_code, 
  	t1.nat_balance,
	t1.reference_code,
  	t1.rate_type_home,
	t1.rate,
	t2.home_cur_code,
  	t1.balance,
	t1.rate_type_oper,
	t1.rate_oper,
	t2.oper_cur_code,
	t1.balance_oper,
	posted_flag = case t1.posted_flag 
		when 0 then 'No'
		when 1 then 'Yes'
	end,

 	x_date_applied=t2.date_applied,
 	x_sequence_id=t1.sequence_id,
 	x_nat_balance=t1.nat_balance,
	x_rate=t1.rate,
 	x_balance=t1.balance,
	x_rate_oper=t1.rate_oper,
	x_balance_oper=t1.balance_oper

  FROM 
  	gltrxdet t1,
	gltrx t2

  WHERE t1.journal_ctrl_num = t2.journal_ctrl_num


GO
GRANT REFERENCES ON  [dbo].[gllin_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[gllin_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[gllin_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[gllin_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[gllin_vw] TO [public]
GO
