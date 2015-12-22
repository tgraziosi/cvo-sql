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




  
  








CREATE VIEW [dbo].[gltrxdet_io_vw] AS
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

 	x_date_applied = (datediff(day, '01/01/1900', t2.date_applied) + 693596),
 	x_sequence_id=t1.sequence_id * 1.0,
 	x_nat_balance=t1.nat_balance,
	x_rate=t1.rate,
 	x_balance=t1.balance,
	x_rate_oper=t1.rate_oper,
	x_balance_oper=t1.balance_oper,
	'source'=1, 'link_journal_ctrl_num'=t1.journal_ctrl_num
  FROM 
  	gltrxdet t1,
	gltrx t2
  WHERE t1.journal_ctrl_num = t2.journal_ctrl_num
/**/                                              


GO
GRANT REFERENCES ON  [dbo].[gltrxdet_io_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[gltrxdet_io_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[gltrxdet_io_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[gltrxdet_io_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[gltrxdet_io_vw] TO [public]
GO
