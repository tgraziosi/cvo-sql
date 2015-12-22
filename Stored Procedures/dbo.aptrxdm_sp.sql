SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2009 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2009 Epicor Software Corporation, 2009    
                  All Rights Reserved                    
*/                                                
















































































































































  



					  

























































 

































































































































































































































































































CREATE PROC [dbo].[aptrxdm_sp]  
  @apply_to_num   varchar(16),
  @trx_ctrl_num   varchar(16),
  @trxtype        smallint,
  @date_entered   int,
  @date_applied   int,
  @user_id        smallint,
  @user_trx_type  varchar(8),
  @option_flag    smallint,
  @batch_code     varchar(16)
AS

DECLARE @vend_code      varchar(12),  @pay_to_code    varchar(8),
    @pay_to1        varchar(40),           @pay_to2        varchar(40),
    @pay_to3        varchar(40),           @pay_to4        varchar(40),
    @pay_to5        varchar(40),           @pay_to6        varchar(40),
    @att_name       varchar(40),           @att_phone      varchar(30),
    @headonly       smallint,
    @zeroqty        smallint,           @defltqty       smallint,
    @addr_type      smallint,           @loc_code       varchar(10),
    @stock_charge   float,         @next_id        smallint,
    @pur_ret_acct   varchar(32),      @company_id     smallint,
    @curr_precision smallint,       @company_code varchar(8),
    @currency_code varchar(8) 


DECLARE @pay_to_city	varchar(40),
		@pay_to_state varchar(40),
		@pay_to_postal_code varchar(15),
		@pay_to_country_code varchar(3)




SELECT  @headonly = 0,  @zeroqty =  1,  @defltqty = 2,  @addr_type = 1

SELECT  @pay_to1 = SPACE(1),    @pay_to2 = SPACE(1),    @pay_to3 = SPACE(1),
  @pay_to4 = SPACE(1),    @pay_to5 = SPACE(1),    @pay_to6 = SPACE(1)




SELECT  @company_id = company_id
FROM    apco

SELECT @company_code = company_code
FROM glco




SELECT  @pay_to_code = x.pay_to_code,
  @vend_code = v.vendor_code,
  @loc_code = v.location_code,
  @att_name = v.attention_name,
  @att_phone = v.attention_phone
FROM    apvohdr x, apvend v
WHERE   trx_ctrl_num = @apply_to_num
AND     x.vendor_code = v.vendor_code




IF EXISTS( SELECT pay_to_code FROM appayok_vw WHERE
   vendor_code = @vend_code AND pay_to_code = @pay_to_code )
BEGIN

  SELECT  @pay_to1 = addr1,
    @pay_to2 = addr2,
    @pay_to3 = addr3,
    @pay_to4 = addr4,
    @pay_to5 = addr5,
    @pay_to6 = addr6,
    @att_name = attention_name,
    @att_phone = attention_phone,
    @loc_code = location_code,
	
    @pay_to_city = city ,
    @pay_to_state = state,
    @pay_to_postal_code = postal_code,
    @pay_to_country_code = country_code
  FROM    apvnd_vw
  WHERE   vendor_code = @vend_code
  AND   pay_to_code = @pay_to_code
END

SELECT  @next_id = NULL

SELECT  @next_id = MAX( serial_id )
FROM    apvodet
WHERE   trx_ctrl_num = @apply_to_num

IF @next_id IS NULL
  SELECT @next_id = 0
ELSE
  SELECT @next_id = @next_id + 1

SELECT  @pur_ret_acct = NULL

SELECT  @pur_ret_acct = dbo.IBAcctMask_fn(a.purc_ret_acct_code, x.org_id)
FROM    apvohdr x, apaccts a
WHERE   trx_ctrl_num = @apply_to_num
AND     x.posting_code = a.posting_code

IF @pur_ret_acct IS NULL
  RETURN




      
BEGIN TRAN

DELETE  apinpdm_vw
WHERE   trx_ctrl_num = @trx_ctrl_num

DELETE  apinpcdt
WHERE   trx_ctrl_num = @trx_ctrl_num


DELETE  apinptax
WHERE   trx_ctrl_num = @trx_ctrl_num and trx_type = @trxtype

DELETE  apinptaxdtl
WHERE   trx_ctrl_num = @trx_ctrl_num and trx_type = @trxtype

DELETE  gltcDocTaxOverride
WHERE   trx_ctrl_num = @trx_ctrl_num and trx_type = @trxtype


INSERT  apinpchg (

  trx_ctrl_num,
  trx_type,
  doc_ctrl_num,
  apply_to_num,
  user_trx_type_code,
  batch_code,
  po_ctrl_num,
  vend_order_num,
  ticket_num,
  date_applied,
  date_aging,
  date_due,
  date_doc,
  date_entered,
  date_received,
  date_required,
  date_recurring,
  date_discount,
  posting_code,
  vendor_code,
  pay_to_code,
  branch_code,
  class_code,
  approval_code,
  comment_code,
  fob_code,
  terms_code,
  tax_code,
  recurring_code,
  location_code,
  payment_code,
  times_accrued,
  accrual_flag,
  drop_ship_flag,
  posted_flag,
  hold_flag,
  add_cost_flag,
  approval_flag,
  recurring_flag,
  one_time_vend_flag,
  one_check_flag,
  amt_gross,
  amt_discount,
  amt_tax ,
  amt_freight,
  amt_misc,
  amt_net ,
  amt_paid,
  amt_due ,
  amt_restock,
  amt_tax_included,
  frt_calc_tax,
  doc_desc,
  hold_desc,
  user_id ,
  next_serial_id,
  pay_to_addr1,
  pay_to_addr2,
  pay_to_addr3,
  pay_to_addr4,
  pay_to_addr5,
  pay_to_addr6,
  attention_name,
  attention_phone,
  intercompany_flag,
  company_code,
  cms_flag,
  process_group_num,
  nat_cur_code,  
  rate_type_home,  
  rate_type_oper,  
  rate_home,       
  rate_oper,
  net_original_amt,
  org_id,
  tax_freight_no_recoverable,
  pay_to_city , 
  pay_to_state,
  pay_to_postal_code,
  pay_to_country_code
 )
SELECT                            
  @trx_ctrl_num,                  
  @trxtype,                       
  doc_ctrl_num,                   
  @apply_to_num,                  
  @user_trx_type,                 
  @batch_code,                    
  po_ctrl_num,                    
  vend_order_num,                 
  ticket_num,                     
  @date_applied,                  
  0,                              
  0,                              
  @date_entered,                  
  @date_entered,                  
  0,                              
  0,                              
  0,                              
  0,                              
  posting_code,                   
  @vend_code,                     
  @pay_to_code,                   
  branch_code,                    
  class_code,                     
  approval_code,                  
  SPACE(1),                       
  fob_code,                       
  terms_code,                     
  tax_code,                       
  recurring_code,                 
  @loc_code,                      
  payment_code,                   
  times_accrued,                  
  accrual_flag,                   
  0,                              
  -1,                             
  0,                              
  0,                              
  0,                              
  0,                              
  0,                              
  0,                              
  0.0,                            
  0.0,                            
  0.0,                            
  0.0,                            
  0.0,                            
  0.0,                            
  0.0,                            
  0.0,                            
  0.0,                            
  0.0,                            
  0.0,                            
  SPACE(1),                       
  SPACE(1),                       
  @user_id,                       
  @next_id,                        
  @pay_to1,                       
  @pay_to2,                       
  @pay_to3,                       
  @pay_to4,                       
  @pay_to5,                       
  @pay_to6,                       
  @att_name,                      
  @att_phone,                     
  intercompany_flag,              
  @company_code,                   
  0,                        
  '',
  currency_code,   
  rate_type_home,  
  rate_type_oper,  
  rate_home,       
  rate_oper,
  net_original_amt,
  org_id,
  tax_freight_no_recoverable,
  
  @pay_to_city,
  @pay_to_state,
  @pay_to_postal_code,
  @pay_to_country_code
FROM    apvohdr
WHERE   trx_ctrl_num = @apply_to_num




IF @@rowcount = 0 OR @option_flag = @headonly
BEGIN
  COMMIT TRAN
  RETURN
END




IF @option_flag = @zeroqty
BEGIN
  INSERT  apinpcdt (

    trx_ctrl_num,
    trx_type,
    sequence_id,
    location_code,
    item_code,
    bulk_flag,
    qty_ordered,
    qty_received,
    qty_returned,
    qty_prev_returned,
    approval_code,
    tax_code,
    return_code,
    code_1099,
    po_ctrl_num,
    unit_code,
    unit_price,
    amt_discount,
    amt_freight,
    amt_tax,
    amt_misc,
    amt_extended,
    calc_tax,
    date_entered,
    gl_exp_acct,
    new_gl_exp_acct,
    rma_num,
    line_desc,
    serial_id,
    company_id,
    iv_post_flag,
    po_orig_flag,
    rec_company_code,
    new_rec_company_code,
    reference_code,
    new_reference_code,
    org_id,
    amt_nonrecoverable_tax,
    amt_tax_det )
  SELECT                   
    @trx_ctrl_num,          
    @trxtype,               
    sequence_id,            
    location_code,          
    item_code,              
    0,              
    qty_ordered,            
    0,                      
    0.0,                    
    qty_returned,           
    '',          
    tax_code,               
    '',            
    code_1099,              
    '',            
    unit_code,              
    unit_price,             
    0,                      
    0.0,                    
    0.0,                    
    0.0,                    
    0.0,                    
    0.0,                    
    @date_entered,          
    gl_exp_acct,    
    '',        
    SPACE(1),               
    line_desc,              
    serial_id,              
    comp.company_id,             
    1,                      
    0,                      
    rec_company_code,       
    '',   
    reference_code,         
    ''   ,   
    org_id,
    0,
    0
  FROM    apvodet, glcomp_vw comp
  WHERE   trx_ctrl_num = @apply_to_num
  AND     rec_company_code = comp.company_code

  IF      @@rowcount = 0
  BEGIN
    ROLLBACK TRAN
    RETURN
  END             
END
ELSE
IF @option_flag = @defltqty
BEGIN
  SELECT @curr_precision = a.curr_precision
  FROM glcurr_vw a, apinpchg b
  WHERE b.trx_ctrl_num = @trx_ctrl_num
  AND b.nat_cur_code = a.currency_code


 
  UPDATE apinpchg SET  amt_gross =  vo.amt_gross,
   amt_discount = vo.amt_discount,
   amt_tax  = vo.amt_tax,
   amt_freight = vo.amt_freight,
   amt_misc = vo.amt_misc ,
   amt_net = (vo.amt_gross - vo.amt_discount + vo.amt_tax - vo.amt_tax_included + vo.amt_freight + vo.amt_misc),
   amt_paid = vo.amt_paid_to_date,
   amt_tax_included = vo.amt_tax_included,
   frt_calc_tax = vo.frt_calc_tax,
   net_original_amt = (vo.amt_gross - vo.amt_discount + vo.amt_tax - vo.amt_tax_included + vo.amt_freight + vo.amt_misc)
  FROM apvohdr vo , apinpchg ap 
  WHERE ap.trx_ctrl_num = @trx_ctrl_num
    AND  vo.trx_ctrl_num = @apply_to_num

	 
	






	DECLARE @TaxTypesTemp TABLE
	(
	  trx_ctrl_num varchar(16),
	  tax_type_code varchar(8),
	  sum_amt_tax float
	)

	INSERT INTO @TaxTypesTemp ( trx_ctrl_num, tax_type_code, sum_amt_tax)
	select trx_ctrl_num, tax_type_code, (SIGN(sum(amt_tax)) * ROUND(ABS(sum(amt_tax)) + 0.0000001, @curr_precision)) sum_amt_tax from aptrxtaxdtl 
	where trx_ctrl_num =  @apply_to_num and  trx_type  = 4091  
	group by trx_ctrl_num, tax_type_code 
	
	
  INSERT apinptax (
        trx_ctrl_num,
        trx_type,
        sequence_id,
        tax_type_code,
        amt_taxable,
        amt_gross,
        amt_tax,
        amt_final_tax )
  SELECT                    
    @trx_ctrl_num,          
    @trxtype,               
    1,    
    a.tax_type_code,
    isnull(a.amt_taxable,0.0) ,
    isnull(a.amt_gross,0.0)  ,     
    isnull(b.sum_amt_tax,0.0) ,
    isnull(a.amt_tax , 0.0)
    from  aptrxtax a 
		left outer join @TaxTypesTemp b  
			on (a.trx_ctrl_num = b.trx_ctrl_num and a.tax_type_code = b.tax_type_code ) 
	where a.trx_ctrl_num = @apply_to_num
       and a.trx_type  = 4091 
       
 



  


  INSERT  apinpcdt (
  
    trx_ctrl_num,
    trx_type,
    sequence_id,
    location_code,
    item_code,
    bulk_flag,
    qty_ordered,
    qty_received,
    qty_returned,
    qty_prev_returned,
    approval_code,
    tax_code,
    return_code,
    code_1099,
    po_ctrl_num,
    unit_code,
    unit_price,
    amt_discount,
    amt_freight,
    amt_tax,
    amt_misc,
    amt_extended,
    calc_tax,
    date_entered,
    gl_exp_acct,
    new_gl_exp_acct,
    rma_num,
    line_desc,
    serial_id,
    company_id ,
    iv_post_flag,
    po_orig_flag,
    rec_company_code,
    new_rec_company_code,
    reference_code,
    new_reference_code,
    org_id,
    amt_nonrecoverable_tax,
    amt_tax_det )

  SELECT                    
    @trx_ctrl_num,          
    @trxtype,               
    sequence_id,            
    location_code,          
    item_code,              
    0,              
    qty_ordered,            
    qty_received,
          
    qty_received - qty_returned,
          
    qty_returned,           
    '',          
    tax_code,               
    '',            
    code_1099,              
    '',            
    unit_code,              
    unit_price,             
    amt_discount,           
    amt_freight,            
    amt_tax,                
    amt_misc,               
    (SIGN((qty_received - qty_returned) * unit_price) * ROUND(ABS((qty_received - qty_returned) * unit_price) + 0.0000001, @curr_precision)),     
    calc_tax,               
    @date_entered,          
    gl_exp_acct,    
    '',        
    SPACE(1),               
    line_desc,              
    serial_id,              
    comp.company_id,             
    1,                      
    0,                      
    rec_company_code,       
    '',           
    reference_code,         
    '' ,     
    org_id,
    amt_nonrecoverable_tax,
    amt_tax_det
  FROM    apvodet, glcomp_vw comp
  WHERE   trx_ctrl_num = @apply_to_num
  AND     rec_company_code = comp.company_code

INSERT apinptaxdtl
(
	trx_ctrl_num,
	sequence_id,
	trx_type,
	tax_sequence_id,
	detail_sequence_id,
	tax_type_code,
	amt_taxable,
	amt_gross,
	amt_tax,
	amt_final_tax,
	recoverable_flag,
	account_code                     
)
SELECT
	@trx_ctrl_num,
	sequence_id,
	@trxtype,
	tax_sequence_id,
	detail_sequence_id,
	tax_type_code,
	amt_taxable,
	amt_gross,
	amt_tax,
	amt_final_tax,
	recoverable_flag,
	account_code
FROM aptrxtaxdtl
WHERE   trx_ctrl_num = @apply_to_num


insert into gltcDocTaxOverride
(trx_ctrl_num, trx_type, line, TaxOverrided)
select @trx_ctrl_num, @trxtype, line, TaxOverrided
from gltcDocTaxOverride where trx_ctrl_num = @apply_to_num



END

















COMMIT TRAN
RETURN

GO
GRANT EXECUTE ON  [dbo].[aptrxdm_sp] TO [public]
GO
