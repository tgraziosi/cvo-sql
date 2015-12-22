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









create proc [dbo].[apvo3_comp_sp] @WhereClause varchar(1024)="", @comp_name varchar(30)="" as
DECLARE
	@CM_interfaced 	smallint

create table #Payments (
	voucher_no varchar(16),		
	pyt_doc_no varchar(16), 	
	pyt_ctrl_no varchar(16),	
	payment_date int,		
	payment_amt float,		
					
	payment_disc float,								
	payment_code varchar(8),	
	date_applied int,		
	void_flag smallint,		
	hold_flag smallint,		
	cleared_flag smallint,		
	approval_flag smallint,		
	posted_flag smallint,		
	vendor_code varchar(12))	

create table #VoucherPayments (
	company_name varchar(30),	
	vendor_name varchar(40),	 
	vendor_code varchar(12), 	
	voucher_no varchar(16), 	
	org_id varchar(30) NULL,	
	vo_posted_flag varchar(4),   	
	vo_hold_flag varchar(4),	    
	vo_approval_flag varchar(4), 	
	nat_cur_code varchar(8),	
	pyt_doc_no varchar(16) NULL,	
	pyt_ctrl_no varchar(16) NULL,	
	pyt_posted_flag varchar(4) NULL,
	pyt_hold_flag varchar(4) NULL,	
	pyt_cleared_flag varchar(4) NULL,  
					
	pyt_approval_flag varchar(4) NULL, 
					
	pyt_void_flag varchar(4) NULL,	
	payment_amt float NULL,		
					
	payment_disc float NULL,									
	payment_date int NULL,		
	payment_code varchar(8) NULL,	
	date_applied int NULL)		







select
	@CM_interfaced = bb_flag
from
	apco
	
if (@CM_interfaced <> 0)
begin

  insert into #Payments (
	voucher_no,		
	pyt_doc_no,		 
	pyt_ctrl_no,		
	payment_date,		
	payment_amt,		
				
	payment_disc,								
	payment_code,		
	date_applied,		
	void_flag,		 
	hold_flag,		
	cleared_flag,		
	approval_flag,		
	posted_flag,		
	vendor_code)		
  
  select 
	t1.apply_to_num,	
	t2.doc_ctrl_num,	
	t1.trx_ctrl_num,	
	t2.date_doc,		
	t1.vo_amt_applied,	
				
	t1.vo_amt_disc_taken,	
										
	t2.payment_code,	
	t2.date_applied,	
	t2.void_flag,		 
	0,			
	ISNULL(t3.reconciled_flag,0),
				
	0,			
	1,			
	t2.vendor_code		
  from
	appydet t1 INNER JOIN appyhdr t2 ON t1.trx_ctrl_num = t2.trx_ctrl_num
	LEFT OUTER JOIN cminpdtl t3 	ON t2.doc_ctrl_num = t3.doc_ctrl_num
					AND t1.trx_ctrl_num = t3.trx_ctrl_num








end
else
begin

	


  insert into #Payments (
	voucher_no,		
	pyt_doc_no,		 
	pyt_ctrl_no,		
	payment_date,		
	payment_amt,		
				
	payment_disc,								
	payment_code,		
	date_applied,		
	void_flag,		 
	hold_flag,		
	cleared_flag,		
	approval_flag,		
	posted_flag,		
	vendor_code)		
  
  select 
	t1.apply_to_num,	
	t2.doc_ctrl_num,	
	t1.trx_ctrl_num,	
	t2.date_doc,		
	t1.vo_amt_applied,	
				
	t1.vo_amt_disc_taken,							
	t2.payment_code,	
	t2.date_applied,	
	t2.void_flag,		 
	0,			
	0,			
	0,			
	1,			
	t2.vendor_code		
  from
	appydet t1, appyhdr t2
  where 
   	t1.trx_ctrl_num = t2.trx_ctrl_num

end

  insert into #VoucherPayments (
	company_name,		
	vendor_name,		 
	vendor_code, 		
	voucher_no, 		
	org_id,			
	nat_cur_code,		
	pyt_doc_no,		
	pyt_ctrl_no,		
	payment_amt,		
				
	payment_disc,								
	payment_date,		
	payment_code,		
	date_applied,		
	vo_posted_flag,		
	vo_hold_flag,		
	vo_approval_flag,	
	pyt_posted_flag,	
	pyt_hold_flag,		
	pyt_cleared_flag,	
	pyt_approval_flag,	
	pyt_void_flag)		

  select 
	company_name = @comp_name, 
	t2.vendor_name,		 
	t2.vendor_code,		
	t1.trx_ctrl_num, 	
	t1.org_id,		
	nat_cur_code=t1.currency_code,	
				
	t3.pyt_doc_no,		
	t3.pyt_ctrl_no,		
	t3.payment_amt,		
				
	t3.payment_disc,							
	t3.payment_date,	
	t3.payment_code,	
	t3.date_applied,	  
	'Yes',			
	'No',			
	'No',			
	posted_flag = case t3.posted_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,			
	hold_flag = case t3.hold_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,			       
	cleared_flag = case t3.cleared_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,			
	apprvoal_flag = case t3.approval_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,			
	void_flag = case t3.void_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end			

  from 
	apvohdr t1, apvend t2, #Payments t3

  where (t1.vendor_code = t2.vendor_code) 
	and t1.trx_ctrl_num  	= t3.voucher_no
	and t1.vendor_code 	= t3.vendor_code 	


 

  delete #Payments
  insert into #Payments (
	voucher_no,		
	pyt_doc_no,		
	pyt_ctrl_no,		
	payment_date,		
	payment_amt,		
				 
	payment_disc,								
	payment_code,		
	date_applied,		
	void_flag,		
	hold_flag,		
	cleared_flag,		
	approval_flag,		
	posted_flag,		
	vendor_code)		
  
  select 
	t1.apply_to_num,	
	t2.doc_ctrl_num,	
	t1.trx_ctrl_num,	
	t2.date_doc,		
	t1.vo_amt_applied,	
				
	t1.vo_amt_disc_taken,							
	t2.payment_code,	
	t2.date_applied,	
	0,			
	t2.hold_flag,		 
	0,			
	t2.approval_flag,	
	t2.posted_flag,		
	t2.vendor_code		
  from
	apinppdt t1, apinppyt t2
  where 
	t1.trx_type in (4111) 	
  and   t2.trx_type in (4111)
  and 	t1.trx_ctrl_num = t2.trx_ctrl_num


  insert into #VoucherPayments (
	company_name,		
	vendor_name,		 
	vendor_code, 		
	voucher_no, 		
	org_id,			
	nat_cur_code,		
	pyt_doc_no,		
	pyt_ctrl_no,		
	payment_amt,		
				
	payment_disc,								
	payment_date,		
	payment_code,		
	date_applied,		
	vo_posted_flag,		
	vo_hold_flag,		
	vo_approval_flag,	
	pyt_posted_flag,	
	pyt_hold_flag,		
	pyt_cleared_flag,	
	pyt_approval_flag,	
	pyt_void_flag)		

  select 
	company_name = @comp_name, 
	t2.vendor_name,		 
	t2.vendor_code,		
	t1.trx_ctrl_num, 	
	t1.org_id,			
	nat_cur_code=t1.currency_code,	
				
	t3.pyt_doc_no,		
	t3.pyt_ctrl_no,		
	t3.payment_amt,		
				
	t3.payment_disc,							
	t3.payment_date,	
	t3.payment_code,	
	t3.date_applied,	  
	'Yes',			
	'No',			   
	'No',			
	posted_flag = case t3.posted_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,			
	hold_flag = case t3.hold_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,			
	cleared_flag = case t3.cleared_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,			
	approval_flag = case t3.approval_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,			
	void_flag = case t3.void_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end			

  from 
	apvohdr t1, apvend t2, #Payments t3
  where (t1.vendor_code = t2.vendor_code) 
	and t1.trx_ctrl_num  = t3.voucher_no
	and t1.vendor_code = t3.vendor_code 

 

  delete #Payments
  insert into #Payments (
	voucher_no,		
	pyt_doc_no,		
	pyt_ctrl_no,		
	payment_date,		
	payment_amt,		
				 
	payment_disc,								
	payment_code,		
	date_applied,		
	void_flag,		
	hold_flag,		
	cleared_flag,		
	approval_flag,		
	posted_flag,		
	vendor_code)		

  select 
	t1.apply_to_num,	
	t1.trx_ctrl_num,	
	"",			
	t1.date_doc,		
	t1.amt_net,		
				
	t1.amt_discount,							
	t1.payment_code,	
	t1.date_applied,	
	0,			
	t1.hold_flag,		 
	0,			
	t1.approval_flag,	
	0,			
	t1.vendor_code		
  from
	apinpchg t1
  where
    t1.trx_type = 4092	
  

  insert into #VoucherPayments (
	company_name,		
	vendor_name,		 
	vendor_code, 		
	voucher_no, 		
	org_id,			
	nat_cur_code,		
	pyt_doc_no,		
	pyt_ctrl_no,		
	payment_amt,		
				
	payment_disc,								
	payment_date,		
	payment_code,		
	date_applied,		
	vo_posted_flag,		
	vo_hold_flag,		
	vo_approval_flag,	
	pyt_posted_flag,	
	pyt_hold_flag,		
	pyt_cleared_flag,	
	pyt_approval_flag,	
	pyt_void_flag)		

  select 
	company_name = @comp_name, 
	t2.vendor_name,		 
	t2.vendor_code,		
	t1.trx_ctrl_num, 	
	t1.org_id,		
	nat_cur_code=t1.currency_code,	
				
	t3.pyt_doc_no,		
	t3.pyt_ctrl_no,		
	t3.payment_amt,		
				
	t3.payment_disc,							
	t3.payment_date,	
	t3.payment_code,	
	t3.date_applied,	  
	posted_flag='Yes',	
	'No',			   
	'No',			
	posed_flag = case t3.posted_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,			
	hold_flag = case t3.hold_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,			
	cleared_flag = case t3.cleared_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,			
	approval_flag = case t3.approval_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,			
	void_flag = case t3.void_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end			

  from 
	apvohdr t1, apvend t2, #Payments t3
  where (t1.vendor_code = t2.vendor_code) 
	and t1.trx_ctrl_num  = t3.voucher_no
	and t1.vendor_code = t3.vendor_code 



 

  delete #Payments
  insert into #Payments (
	voucher_no,		
	pyt_doc_no,		
	pyt_ctrl_no,		
	payment_date,		
	payment_amt,		
				 
	payment_disc,								
	payment_code,		
	date_applied,		
	void_flag,		
	hold_flag,		
	cleared_flag,		
	approval_flag,		
	posted_flag,		
	vendor_code)		
  
  select 
	t1.trx_ctrl_num,	
	t1.doc_ctrl_num,	
	"",			
	t1.date_doc,		
	t1.amt_payment,		
				
	t1.amt_disc_taken,							
	t1.payment_code,	
	t1.date_applied,	
	0,			
	0,			 
	0,			
	t1.approval_flag,	
	0,			
	t1.vendor_code		
  from
	apinptmp t1


  insert into #VoucherPayments (
	company_name,		
	vendor_name,		 
	vendor_code, 		
	voucher_no, 		
	org_id,			
	nat_cur_code,		
	pyt_doc_no,		
	pyt_ctrl_no,		
	payment_amt,		
				
	payment_disc,								
	payment_date,		
	payment_code,		
	date_applied,		
	vo_posted_flag,		
	vo_hold_flag,		
	vo_approval_flag,	
	pyt_posted_flag,	
	pyt_hold_flag,		
	pyt_cleared_flag,	
	pyt_approval_flag,	
	pyt_void_flag)		

  select 
	company_name = @comp_name, 
	t2.vendor_name,		 
	t2.vendor_code,		
	t1.trx_ctrl_num, 	
	t1.org_id,		
	t1.nat_cur_code,	
	t3.pyt_doc_no,		
	t3.pyt_ctrl_no,		
	t3.payment_amt,		
				
	t3.payment_disc,							
	t3.payment_date,	
	t3.payment_code,	
	t3.date_applied,	  
	posted_flag = case t1.posted_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,			
	hold_flag = case t1.hold_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,			
	approval_flag = case t1.approval_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,									
	posted_flag = case t3.posted_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,			
	hold_flag = case t3.hold_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,			
	clear_flag = case t3.cleared_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,			
	approval_flag = case t3.approval_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,			
	void_flag = case t3.void_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end			

  from 
	apinpchg t1, apvend t2, #Payments t3

  where 
	t1.vendor_code = t2.vendor_code
	and t1.trx_type in (4091)		
	and t1.trx_ctrl_num  = t3.voucher_no
	and t1.vendor_code 	 = t3.vendor_code






exec ("select *, x_payment_amt=payment_amt, x_payment_disc=payment_disc, x_payment_date=payment_date, x_date_applied=date_applied from #VoucherPayments" + @WhereClause)


GO
GRANT EXECUTE ON  [dbo].[apvo3_comp_sp] TO [public]
GO
