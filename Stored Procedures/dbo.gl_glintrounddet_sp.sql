SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*
              Confidential Information
   Limited Distribution of Authorized Persons Only
   Created 1996 and Protected as Unpublished Work
         Under the U.S. Copyright Act of 1976
Copyright (c) 1996 Platinum Software Corporation, 1996
                 All Rights Reserved 
 */
                                            CREATE PROC [dbo].[gl_glintrounddet_sp]  @rpt_ctry_code varchar(3), 
 @disp_ctrl_num varchar(16),  @disp_err_num varchar(16),  @arr_ctrl_num varchar(16), 
 @arr_err_num varchar(16) AS BEGIN DECLARE @round_int smallint     SELECT @round_int = round_int FROM gl_glctry WHERE country_code = @rpt_ctry_code 
 IF @@rowcount <> 1 OR @round_int <> 0 AND @round_int <> 1 AND @round_int <> 2  RETURN 8121 
    IF @round_int = 0  UPDATE gl_glintdet  SET amt_rpt = CEILING(amt_rpt),  stat_amt_rpt = CEILING(stat_amt_rpt), 
 weight_value = CEILING(weight_value),  supp_unit_value = CEILING(supp_unit_value) 
 WHERE int_ctrl_num IN (@disp_ctrl_num, @disp_err_num, @arr_ctrl_num, @arr_err_num) 
 IF @@error <> 0 RETURN 8100     IF @round_int = 1  UPDATE gl_glintdet  SET amt_rpt = ROUND(amt_rpt, 0), 
 stat_amt_rpt = ROUND(stat_amt_rpt, 0),  weight_value = ROUND(weight_value, 0),  supp_unit_value = ROUND(supp_unit_value, 0) 
 WHERE int_ctrl_num IN (@disp_ctrl_num, @disp_err_num, @arr_ctrl_num, @arr_err_num) 
 IF @@error <> 0 RETURN 8100     IF @round_int = 2  UPDATE gl_glintdet  SET amt_rpt = FLOOR(amt_rpt), 
 stat_amt_rpt = FLOOR(stat_amt_rpt),  weight_value = FLOOR(weight_value),  supp_unit_value = FLOOR(supp_unit_value) 
 WHERE int_ctrl_num IN (@disp_ctrl_num, @disp_err_num, @arr_ctrl_num, @arr_err_num) 
 IF @@error <> 0 RETURN 8100  RETURN 0 END 
GO
GRANT EXECUTE ON  [dbo].[gl_glintrounddet_sp] TO [public]
GO
