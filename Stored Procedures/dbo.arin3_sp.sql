SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO









                                                









create proc [dbo].[arin3_sp] @WhereClause varchar(1024)="" as

create table #Payments (
	invoice_no varchar(16),		
	payment_no varchar(16), 	
	trx_ctrl_num varchar(16),	
	payment_date int,		
	payment_amt float,		
					
	deposit_num varchar(16) NULL,	
	payment_code varchar(8),	
	date_applied int,		
	void_flag int,			
	hold_flag int,			
	payment_type smallint,		
	customer_code varchar(8))	

create table #InvoicePayments (
	address_name varchar(40),	 
	customer_code varchar(8), 	
	doc_ctrl_num varchar(16), 	
	org_id varchar(30) NULL,
	inv_trx_num varchar(16),	
	inv_posted_flag varchar(4), 	
	inv_hold_flag varchar(4),	
	nat_cur_code varchar(8),	
	payment_no varchar(16) NULL,	
	trx_ctrl_num varchar(16),	
	pyt_posted_flag varchar(4),	
	pyt_hold_flag varchar(4),	
	void_flag varchar(4) NULL,	
	payment_amt float NULL,		
					
	payment_date int NULL,		
	deposit_num varchar(16) NULL,	
	payment_code varchar(8) NULL,	
	date_applied int NULL,		
	payment_type varchar(30) NULL)	




 insert into #Payments (
	invoice_no,			
	payment_no,			 
	trx_ctrl_num,			
	payment_date,			
	payment_amt,			
					
	deposit_num,			
	payment_code,			
	date_applied,			
	void_flag,			 
	hold_flag,			
	payment_type,			
	customer_code)			
 
 select 
	t1.apply_to_num,		
	t1.doc_ctrl_num,		
	t1.trx_ctrl_num,		
	t2.date_doc,			
	t1.inv_amt_applied,		
					
	t2.deposit_num,			
	t2.payment_code,		
	t2.date_applied,		
	t1.void_flag,			 
	0,				
	t2.payment_type,		
	t2.customer_code		
 from
	artrxpdt t1, artrx t2
 where 
	t1.trx_type in (2111) 		
 and t2.trx_type in (2111)
 and 	t2.payment_type in (1,2,3,4) 	
 					
					
					
					
					
					
 and 	t1.doc_ctrl_num = t2.doc_ctrl_num
 and 	t1.trx_ctrl_num = t2.trx_ctrl_num


 insert into #InvoicePayments (
	address_name,		 
	customer_code, 		
	doc_ctrl_num, 	
	org_id,	
	inv_trx_num,	 
	nat_cur_code,		
	payment_no,		
	trx_ctrl_num,		
	payment_amt,		
				
	payment_date,		
	deposit_num,		
	payment_code,		
	date_applied,		
	payment_type,		
	inv_posted_flag,	
	inv_hold_flag,		
	pyt_posted_flag,	
	pyt_hold_flag,		
	void_flag)		

 select 
	t2.address_name,	 
	t2.customer_code,	
	t1.doc_ctrl_num, 	
	t1.org_id,
	t1.trx_ctrl_num,	
	t1.nat_cur_code,	
	t3.payment_no,		
	t3.trx_ctrl_num,	
	t3.payment_amt,		
				
	t3.payment_date,	
	t3.deposit_num,		
	t3.payment_code,	
	t3.date_applied,	 
	payment_type = case t3.payment_type
		when 1 then 'Normal'
		when 2 then 'On Account'
		when 3 then 'Credit Memo Applied'
		when 4 then 'On Account Credit Memo'
	end,			
	'Yes',			
	'No',			
	'Yes',			
	hold_flag = case t3.hold_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,			
	void_flag = case t3.void_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end			

 from 
	artrx t1, armaster t2, #Payments t3
 where (t1.customer_code = t2.customer_code) 
	and t1.trx_type in (2031, 2021)		
						
	and t1.doc_ctrl_num = t1.apply_to_num	
	and t1.trx_type = t1.apply_trx_type 	
	and t2.address_type = 0
	and t1.void_flag = 0			
											
	and t1.doc_ctrl_num = t3.invoice_no


 

 delete #Payments
 insert into #Payments (
	invoice_no,		
	payment_no,		
	trx_ctrl_num,		
	payment_date,		
	payment_amt,		
				
	deposit_num,		
	payment_code,		
	date_applied,		
	void_flag,		
	hold_flag,		
	payment_type,		
	customer_code)		
 
 select 
	t1.apply_to_num,	
	t1.doc_ctrl_num,	
	t1.trx_ctrl_num,	
	t2.date_doc,		
	t1.inv_amt_applied,	
				
	t2.deposit_num,		
	t2.payment_code,	
	t2.date_applied,	
	0,			
	t2.hold_flag,		 
	t2.payment_type,	
	t2.customer_code	
 from
	arinppdt t1, arinppyt t2
 where 
	t1.trx_type in (2111) 	
 and t2.trx_type in (2111)
 and 	t2.payment_type in (1,2,3,4) 	
 				
				
				
				
				
				
 and 	t1.doc_ctrl_num = t2.doc_ctrl_num
 and 	t1.trx_ctrl_num = t2.trx_ctrl_num


 insert into #InvoicePayments (
	address_name,		 
	customer_code, 		
	doc_ctrl_num,
	org_id, 		
	inv_trx_num,	 
	nat_cur_code,		
	payment_no,		
	trx_ctrl_num,		
	payment_amt,		
				
	payment_date,		
	deposit_num,		
	payment_code,		
	date_applied,		
	payment_type,		
	inv_posted_flag,	
	inv_hold_flag,		
	pyt_posted_flag,	
	pyt_hold_flag,		
	void_flag)		

 select 
	t2.address_name,	 
	t2.customer_code,	
	t1.doc_ctrl_num,
	t1.org_id, 	
	t1.trx_ctrl_num,	
	t1.nat_cur_code,	
	t3.payment_no,		
	t3.trx_ctrl_num,	
	t3.payment_amt,		
				
	t3.payment_date,	
	t3.deposit_num,		
	t3.payment_code,	
	t3.date_applied,	 
	payment_type = case t3.payment_type
		when 1 then 'Normal'
		when 2 then 'On Account'
		when 3 then 'Credit Memo Applied'
		when 4 then 'On Account Credit Memo'
	end,			
	'Yes',			
	'No',			
	'No',			
	hold_flag = case t3.hold_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,			
	void_flag = case t3.void_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end			

 from 
	artrx t1, armaster t2, #Payments t3
 where (t1.customer_code = t2.customer_code) 
	and t1.trx_type in (2031, 2021)		
						
	and t1.doc_ctrl_num = t1.apply_to_num	
	and t1.trx_type = t1.apply_trx_type 	
	and t2.address_type = 0
	and t1.void_flag = 0			
											
	and t1.doc_ctrl_num = t3.invoice_no

 

 delete #Payments
 insert into #Payments (
	invoice_no,		
	payment_no,		
	trx_ctrl_num,		
	payment_date,		
	payment_amt,		
				
	deposit_num,		
	payment_code,		
	date_applied,		
	void_flag,		
	hold_flag,		
	payment_type,		
	customer_code)		
 
 select 
	apply_to_num,		
	doc_ctrl_num,		
	trx_ctrl_num,		
	date_doc,		
	amt_net,		
				
	'',			
	'',			
	date_applied,		
	0,			
	hold_flag,		 
	3,			
	customer_code		
 from
	arinpchg 
 where 
	trx_type in (2032) 	
 and	apply_trx_type in (2031)


 insert into #InvoicePayments (
	address_name,		 
	customer_code, 		
	doc_ctrl_num,
	org_id, 		
	inv_trx_num,	 
	nat_cur_code,		
	payment_no,		
	trx_ctrl_num,		
	payment_amt,		
				
	payment_date,		
	deposit_num,		
	payment_code,		
	date_applied,		
	payment_type,		
	inv_posted_flag,	
	inv_hold_flag,		
	pyt_posted_flag,	
	pyt_hold_flag,		
	void_flag)		

 select 
	t2.address_name,	 
	t2.customer_code,	
	t1.doc_ctrl_num,
	t1.org_id, 	
	t1.trx_ctrl_num,	
	t1.nat_cur_code,	
	t3.payment_no,		
	t3.trx_ctrl_num,	
	t3.payment_amt,		
				
	t3.payment_date,	
	t3.deposit_num,		
	t3.payment_code,	
	t3.date_applied,	 
	payment_type = case t3.payment_type
		when 1 then 'Normal'
		when 2 then 'On Account'
		when 3 then 'Credit Memo Applied'
		when 4 then 'On Account Credit Memo'
	end,			
	'Yes',			
	'No',			
	'No',			
	hold_flag = case t3.hold_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,			
	void_flag = case t3.void_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end			

 from 
	artrx t1, armaster t2, #Payments t3
 where (t1.customer_code = t2.customer_code) 
	and t1.trx_type in (2031, 2021)		
						
	and t1.doc_ctrl_num = t1.apply_to_num	
	and t1.trx_type = t1.apply_trx_type 	
	and t2.address_type = 0
	and t1.void_flag = 0			
											
	and t1.doc_ctrl_num = t3.invoice_no


 

 delete #Payments
 insert into #Payments (
	invoice_no,		
	payment_no,		
	trx_ctrl_num,		
	payment_date,		
	payment_amt,		
				
	deposit_num,		
	payment_code,		
	date_applied,		
	void_flag,		
	hold_flag,		
	payment_type,		
	customer_code)		
 
 select 
	t1.doc_ctrl_num,	
	t2.doc_ctrl_num,	
	t2.trx_ctrl_num,	
	t2.date_doc,		
	t2.amt_payment,		
				
	NULL,			
	t2.payment_code,	
	t1.date_applied,	
	0,			
	0,			 
	1,			
	t1.customer_code	
 from
	arinpchg t1, arinptmp t2
 where 
	t1.trx_type in (2031) 	
 and 	t1.trx_ctrl_num = t2.trx_ctrl_num


 insert into #InvoicePayments (
	address_name,		 
	customer_code, 		
	doc_ctrl_num, 		
	org_id,
	inv_trx_num,	 
	nat_cur_code,		
	payment_no,		
	trx_ctrl_num,		
	payment_amt,		
				
	payment_date,		
	deposit_num,		
	payment_code,		
	date_applied,		
	payment_type,		
	inv_posted_flag,	
	inv_hold_flag,		
	pyt_posted_flag,	
	pyt_hold_flag,		
	void_flag)		

 select 
	t2.address_name,	 
	t2.customer_code,	
	t1.doc_ctrl_num,
	t1.org_id, 	
	t1.trx_ctrl_num,	
	t1.nat_cur_code,	
	t3.payment_no,		
	t3.trx_ctrl_num,	
	t3.payment_amt,		
				
	t3.payment_date,	
	t3.deposit_num,		
	t3.payment_code,	
	t3.date_applied,	 
	payment_type = case t3.payment_type
		when 1 then 'Normal'
		when 2 then 'On Account'
		when 3 then 'Credit Memo Applied'
		when 4 then 'On Account Credit Memo'
	end,			
	'No',			
	inv_hold_flag=case t1.hold_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,		
				
	'No',			
	hold_flag = case t3.hold_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,			
	void_flag = case t3.void_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end			

 from 
	arinpchg t1, armaster t2, #Payments t3
 where (t1.customer_code = t2.customer_code) 
	and t1.trx_type in (2031, 2021)		
						
	and t2.address_type = 0
	and t1.doc_ctrl_num = t3.invoice_no
	and t1.trx_ctrl_num = t3.trx_ctrl_num





				

exec ("select *, x_payment_amt=payment_amt, x_payment_date=payment_date, x_date_applied=date_applied from #InvoicePayments" + @WhereClause)


GO
GRANT EXECUTE ON  [dbo].[arin3_sp] TO [public]
GO
