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
                                          CREATE PROC [dbo].[gl_glintunpost_sp]  @rpt_ctry_code varchar(3), 
 @int_period_id int AS BEGIN DECLARE  @post_flag smallint,  @disp_ctrl_num varchar(16), 
 @arr_ctrl_num varchar(16)  SELECT @post_flag = post_flag,  @disp_ctrl_num = disp_ctrl_num, 
 @arr_ctrl_num = arr_ctrl_num  FROM gl_glinthdr  WHERE rpt_ctry_code = @rpt_ctry_code AND int_period_id = @int_period_id 
 UPDATE gl_glinthdr  SET post_flag = 0  WHERE rpt_ctry_code = @rpt_ctry_code AND int_period_id = @int_period_id AND post_flag = 1 
 UPDATE gl_glintdet  SET weight_flag = 0,  supp_unit_flag = 0  WHERE int_ctrl_num = @disp_ctrl_num OR int_ctrl_num = @arr_ctrl_num 
 RETURN 0 END 
GO
GRANT EXECUTE ON  [dbo].[gl_glintunpost_sp] TO [public]
GO
