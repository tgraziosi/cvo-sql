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





























CREATE PROC [dbo].[ARCRAddStlRec_SP]	  @settlement_ctrl_num varchar(16)
				
AS

DECLARE
      	
    @on_acct_total_home float,
    @on_acct_total_oper float,
    @doc_sum_entered   float,
    @cr_total_home   float,
    @cr_total_oper   float,
    @oa_cr_total_home   float,
    @oa_cr_total_oper   float,
    @inv_total_home    float,
    @inv_total_oper    float,
    @disc_total_home   float,
    @disc_total_oper   float,
    @wroff_total_home  float,
    @wroff_total_oper  float,
    @gain_total_home   float,
    @gain_total_oper   float,
    @loss_total_home   float,
    @loss_total_oper   float,
    @hold_flag	       smallint,
    @date_entered 	int,
    @date_applied 	int,
    @user_id		smallint,
    @process_group_num  varchar(16),
    @customer_code	varchar(8),	
    @nat_cur_code	varchar(8),
    @batch_code		varchar(16),
    @rate_type_home	varchar(8),
    @org_id		varchar(30),   
    @rate_home		float,
    @rate_type_oper	varchar(8),
    @rate_oper		float,
    @inv_total_nat	float,
    @amt_dist_nat	float,
    @amt_on_acct	float		


BEGIN
	
  


  SELECT  @cr_total_home = ISNULL( SUM( amt_payment * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ) ), 0.0 ),
          @cr_total_oper = ISNULL( SUM( amt_payment * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ) ), 0.0 ),
          @on_acct_total_home = ISNULL( SUM( amt_on_acct * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ) ), 0.0 ),
          @on_acct_total_oper = ISNULL( SUM( amt_on_acct * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ) ), 0.0 ),
	  @oa_cr_total_home = ISNULL( SUM( amt_on_acct * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ) ), 0.0 ),
          @oa_cr_total_oper = ISNULL( SUM( amt_on_acct * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ) ), 0.0 ),
	  @amt_dist_nat = ISNULL( SUM( amt_payment ), 0.0 ),	
	  @amt_on_acct = ISNULL( SUM( amt_on_acct ), 0.0 )
  FROM    arinppyt
  WHERE     settlement_ctrl_num = @settlement_ctrl_num

  SELECT  @doc_sum_entered = SUM( amt_payment )
  FROM    arinppyt
  WHERE   settlement_ctrl_num = @settlement_ctrl_num

  SELECT  @inv_total_home = ISNULL( SUM( amt_applied * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ) ), 0.0 ),
          @inv_total_oper = ISNULL( SUM( amt_applied * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ) ), 0.0 ),
          @disc_total_home = ISNULL( SUM( amt_disc_taken * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ) ), 0.0 ),
          @disc_total_oper = ISNULL( SUM( amt_disc_taken * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ) ), 0.0 ),
          @wroff_total_home = ISNULL( SUM( amt_max_wr_off * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ) ), 0.0 ),
          @wroff_total_oper = ISNULL( SUM( amt_max_wr_off * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ) ), 0.0 ),
	  @inv_total_nat = ISNULL( SUM( amt_applied ), 0.0 )	
  FROM    arinppyt h, arinppdt d
  WHERE   h.trx_ctrl_num = d.trx_ctrl_num
  AND 	  settlement_ctrl_num = @settlement_ctrl_num

  SELECT  @gain_total_home = ISNULL( SUM( gain_home ),0.0 )
  FROM    arinppdt
  WHERE   gain_home > 0.0

  SELECT  @gain_total_oper = ISNULL( SUM( gain_oper ),0.0 )
  FROM    arinppdt
  WHERE   gain_oper > 0.0

  SELECT  @loss_total_home = ISNULL( SUM( gain_home ), 0.0 )
  FROM    arinppdt
  WHERE   gain_home < 0.0

  SELECT  @loss_total_oper = ISNULL( SUM( gain_oper ), 0.0 )
  FROM    arinppdt
  WHERE   gain_oper < 0.0

  SELECT @hold_flag = hold_flag,
         @date_entered = date_entered,
 	 @date_applied = date_applied,
	 @user_id = user_id,
	 @process_group_num = process_group_num,
	 @customer_code = customer_code,		
	 @nat_cur_code = nat_cur_code,
	 @batch_code = batch_code,
	 @rate_type_home = rate_type_home,   
	 @rate_home = rate_home,
	 @rate_type_oper = rate_type_oper,
	 @rate_oper = rate_oper,
	 @org_id = org_id
  FROM   arinppyt
  WHERE  settlement_ctrl_num = @settlement_ctrl_num
  
	DELETE arinpstlhdr WHERE settlement_ctrl_num = @settlement_ctrl_num

	INSERT arinpstlhdr
	(
	  timestamp,
	  settlement_ctrl_num,
	  description,
	  hold_flag,
	  posted_flag,
	  date_entered,
	  date_applied, 
	  user_id,
	  process_group_num,
	  doc_count_expected,
	  doc_count_entered,
	  doc_sum_expected,
	  doc_sum_entered,
	  cr_total_home,
	  cr_total_oper,
	  oa_cr_total_home,
	  oa_cr_total_oper,
	  cm_total_home,
	  cm_total_oper,
	  inv_total_home,
	  inv_total_oper,
	  disc_total_home,
	  disc_total_oper,
	  wroff_total_home,
	  wroff_total_oper,
	  onacct_total_home,
	  onacct_total_oper,
	  gain_total_home,
	  gain_total_oper,
	  loss_total_home,
	  loss_total_oper,
 	  customer_code,   
  	  nat_cur_code,
  	  batch_code,
  	  rate_type_home,
  	  rate_home,
	  rate_type_oper,
	  rate_oper,
	  inv_amt_nat,			
	  amt_doc_nat,
	  amt_dist_nat,
	  amt_on_acct,			
	  settle_flag,
	  org_id	    
	  )
	  SELECT
	  NULL, 
	  @settlement_ctrl_num,
	  '',
	  @hold_flag,
	  0,
	  @date_entered,
  	  @date_applied,
	  @user_id,
	  @process_group_num,
	  0,
	  1,
	  0,
	  @doc_sum_entered,
	  @cr_total_home,
	  @cr_total_oper,
	  @oa_cr_total_home,
	  @oa_cr_total_oper,
	  0,
	  0,
	  @inv_total_home,
	  @inv_total_oper,
	  @disc_total_home,
	  @disc_total_oper,
	  @wroff_total_home,
	  @wroff_total_oper,
	  @on_acct_total_home,
	  @on_acct_total_oper,
	  @gain_total_home,
	  @gain_total_oper,
	  @loss_total_home,
	  @loss_total_oper,
	  @customer_code,
	  @nat_cur_code,
	  @batch_code,
	  @rate_type_home,   
	  @rate_home,
	  @rate_type_oper,
	  @rate_oper,
	  @inv_total_nat,		
	  @doc_sum_entered,
	  @amt_dist_nat,
	  @amt_on_acct,			
   	  0,
	  @org_id

END
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[ARCRAddStlRec_SP] TO [public]
GO
