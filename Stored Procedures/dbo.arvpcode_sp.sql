SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*
              Confidential Information
   Limited Distribution of Authorized Persons Only
   Created 1996 and Protected as Unpublished Work
         Under the U.S. Copyright Act of 1976
Copyright (c) 1996 Platinum Software Corporation, 1996
                 All Rights Reserved 
 */
                                        CREATE PROC [dbo].[arvpcode_sp]  @p_proc_key int, 
 @posting_code char(8),  @date_applied int,  @save_info smallint AS DECLARE  @ar_acct_code char(32), 
 @fin_chg_acct_code char(32),  @rev_acct_code char(32),  @freight_acct_code char(32), 
 @disc_taken_acct_code char(32),  @disc_given_acct_code char(32),  @late_chg_acct_code char(32), 
 @wr_off_acct_code char(32),  @cm_on_acct_code char(32),  @sales_ret_acct_code char(32), 
 @invalid_flag smallint,  @inactive_flag smallint,  @result smallint    select @result=null 
SELECT @result=sum(inactive_flag+invalid_flag)  from aractst  WHERE posting_code=@posting_code 
 AND date=@date_applied    IF (@result IS NOT NULL) RETURN @result    SELECT  @posting_code = posting_code , 
 @ar_acct_code = ar_acct_code,  @fin_chg_acct_code = fin_chg_acct_code,  @rev_acct_code = rev_acct_code, 
 @freight_acct_code = freight_acct_code,  @disc_taken_acct_code = disc_taken_acct_code, 
 @disc_given_acct_code = disc_given_acct_code,  @late_chg_acct_code = late_chg_acct_code, 
       @cm_on_acct_code = cm_on_acct_code,  @sales_ret_acct_code = sales_ret_acct_code 
FROM araccts WHERE posting_code=@posting_code EXEC @result = arglvco_sp @p_proc_key, @posting_code,@ar_acct_code ,@date_applied,@save_info 
EXEC @result = arglvco_sp @p_proc_key, @posting_code,@fin_chg_acct_code ,@date_applied,@save_info 
EXEC @result = arglvco_sp @p_proc_key, @posting_code,@rev_acct_code ,@date_applied,@save_info 
EXEC @result = arglvco_sp @p_proc_key, @posting_code,@freight_acct_code ,@date_applied,@save_info 
EXEC @result = arglvco_sp @p_proc_key, @posting_code,@disc_taken_acct_code,@date_applied,@save_info 
EXEC @result = arglvco_sp @p_proc_key, @posting_code,@disc_given_acct_code,@date_applied,@save_info 
EXEC @result = arglvco_sp @p_proc_key, @posting_code,@late_chg_acct_code ,@date_applied,@save_info 
   EXEC @result = arglvco_sp @p_proc_key, @posting_code,@cm_on_acct_code ,@date_applied,@save_info 
EXEC @result = arglvco_sp @p_proc_key, @posting_code,@sales_ret_acct_code ,@date_applied,@save_info 
SELECT @result=NULL SELECT @result=sum(inactive_flag+invalid_flag)  FROM aractst 
 WHERE posting_code=@posting_code  AND date=@date_applied  AND proc_key = @p_proc_key 
IF ( @result is NULL ) SELECT @result=0 RETURN @result 

 /**/
GO
GRANT EXECUTE ON  [dbo].[arvpcode_sp] TO [public]
GO
