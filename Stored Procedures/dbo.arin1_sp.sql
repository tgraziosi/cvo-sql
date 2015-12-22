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










CREATE proc [dbo].[arin1_sp] @WhereClause varchar(1024)='' as   
declare
	@OrderBy	varchar(255)

create table #Invoices ( 
	address_name varchar(40),	 
	customer_code varchar(8), 
	state_code varchar(40),					--v1.0		
	doc_ctrl_num varchar(16), 	
	trx_ctrl_num varchar(16), 	
	org_id varchar(30) NULL,
	past_due_status varchar(4) NULL,	
	settled_status varchar(4) NULL,	
	hold_flag varchar(4),			
	posted_flag varchar(4),		
	nat_cur_code varchar(8),	
	amt_net float,
	amt_freight float,--dmoon SOW Mod 05/25/2010
	amt_tax float, --dmoon SOW Mod 05/25/2010
	amt_paid_to_date float NULL,
	unpaid_balance float NULL, 	
	amt_past_due float NULL,
	terms_code varchar(8) null, -- tag 020414	
	date_doc int, 				
	date_applied int,			
	date_due int,				
	date_shipped int,			
	last_payment_date int NULL,	
	cust_po_num varchar(20), 	
	order_ctrl_num varchar(16),
	gl_trx_id varchar(16),
	trx_type smallint,
	trx_desc varchar(10),
	buying_group varchar(10))

create clustered index inv_1 on #Invoices (address_name,customer_code,doc_ctrl_num)


select @OrderBy = ' order by address_name, doc_ctrl_num'

exec (' insert #Invoices select * from arin1pst_vw ' + @WhereClause + @OrderBy)





exec (' update 	#Invoices set 	settled_status = ''Yes'' from arinppyt a, arinppdt b, #Invoices c where	b.apply_to_num = c.doc_ctrl_num and c.customer_code = b.customer_code ')
exec (' insert #Invoices select * from arin1unp_vw ' + @WhereClause + @OrderBy)

exec (' select *, x_amt_net=amt_net, x_amt_paid_to_date=amt_paid_to_date, x_unpaid_balance=unpaid_balance, x_amt_past_due=amt_past_due, x_date_doc=date_doc, x_date_applied=date_applied, x_date_due=date_due, x_date_shipped=date_shipped, x_last_payment_date=last_payment_date from #Invoices ' + @OrderBy)

/**/                                              


GO
GRANT EXECUTE ON  [dbo].[arin1_sp] TO [public]
GO
