SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                







create proc [dbo].[apdm1_sp] @WhereClause varchar(1024)="" as 
declare
	@OrderBy	varchar(255)

create table #DebitMemos 
( 
	vendor_name	varchar(40),				 
	vendor_code	varchar(12),	
	pay_to_code	varchar(8),	
	debit_memo_no	varchar(16), 	
	org_id		varchar(30) NULL,
	posted_flag	varchar(4) NULL,					
	hold_flag	varchar(4) NULL,					
	nat_cur_code	varchar(8) NULL,				
	amt_net	float NULL, 					
 	gl_trx_id	varchar(16) NULL,
	date_doc	int NULL, 					
	date_applied	int NULL,
	po_ctrl_num	varchar(16) NULL,
	doc_ctrl_num	varchar(16) NULL				
)
create clustered index dm_1 on #DebitMemos (vendor_name,vendor_code,debit_memo_no)


select @OrderBy = " order by vendor_name, debit_memo_no"

exec (" insert #DebitMemos select * from apdm1pst_vw " + @WhereClause + @OrderBy)
exec (" insert #DebitMemos select * from apdm1unp_vw " + @WhereClause + @OrderBy)
 

exec (" select *, x_amt_net=amt_net, x_date_doc=date_doc, x_date_applied=date_applied from #DebitMemos " + @OrderBy)

/**/                                              
GO
GRANT EXECUTE ON  [dbo].[apdm1_sp] TO [public]
GO
