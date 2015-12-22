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
	CREATE PROC [dbo].[gl_statamtcalc_sp]  @src_trx_id varchar(4), 
		 @src_ctrl_num varchar(16),  
		@src_line_id int,  
		@total_amt float,  
		@is_detail_freight smallint, 
		@amt_freight float,  
		@cv_code varchar(12),  
		@cv_branch_code varchar(8),  
		@zone_code varchar(8),
		@local_loc	varchar(8),
		@outside_loc	varchar(8)

AS BEGIN DECLARE  @rpt_ctry_code varchar(3),  @flag_stat_amt smallint,  @flag_border_stat smallint, 
 @disp_amt_freight float,  @arr_amt_freight float,  @local_zone varchar(8),  @cv_zone varchar(8), 
 @prc_border float,  @curr_precision smallint     IF @src_trx_id IS NULL OR @src_ctrl_num IS NULL OR @src_line_id IS NULL RETURN 8101 
 IF @src_trx_id = '' OR @src_ctrl_num = '' OR @src_line_id <= 0 RETURN 8101  SELECT @amt_freight = ISNULL(@amt_freight, 0.0), @prc_border = 100.0 
 SELECT @disp_amt_freight = @amt_freight, @arr_amt_freight = @amt_freight     SELECT @rpt_ctry_code = rpt_ctry_code 
 FROM gl_glinphdr  WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num 
 SELECT @flag_stat_amt = flag_stat_amt, @flag_border_stat = flag_border_stat  FROM gl_glctry 
 WHERE country_code = @rpt_ctry_code  IF @flag_stat_amt <> 1 SELECT @flag_stat_amt = 0 
 IF @flag_border_stat <> 1 SELECT @flag_border_stat = 0     
IF @flag_border_stat = 1 
BEGIN  
		IF EXISTS (SELECT name FROM sysobjects WHERE name = "locations")
		BEGIN
			IF NOT @local_loc IS NULL AND @local_loc <> ''
				SELECT @local_zone = zone_code FROM locations WHERE location = @local_loc

			IF @cv_zone = '' AND NOT @outside_loc IS NULL AND @outside_loc <> ''
				SELECT @cv_zone = zone_code FROM locations WHERE location = @outside_loc
		END


	SELECT @cv_zone = ISNULL(@zone_code, '')  
	SELECT @cv_zone = ISNULL(@cv_zone, ''), @local_zone = ISNULL(@local_zone, '') 

	IF @local_zone = ''  
		SELECT @local_zone = zone_code 
		FROM gl_rptctry 
		WHERE country_code = @rpt_ctry_code 

	IF @cv_zone = ''  
	BEGIN  
		IF @src_trx_id = "2031" OR @src_trx_id = "2032"  OR @src_trx_id = "OEIV" OR @src_trx_id = "OECM" 
		BEGIN  
			SELECT @cv_zone = ISNULL(dest_zone_code, '')  
			FROM arshipto  
			WHERE customer_code = @cv_code 
			AND ship_to_code = @cv_branch_code 

		IF @cv_zone = ''  
			SELECT @cv_zone = ISNULL(dest_zone_code, '') 
			FROM arcust 
			WHERE customer_code = @cv_code 
		END  
		ELSE  
		BEGIN  
			SELECT @cv_zone = ISNULL(orig_zone_code, '')  
			FROM appayto  
			WHERE vendor_code = @cv_code 
			AND pay_to_code = @cv_branch_code 

		IF @cv_zone = ''  
			SELECT @cv_zone = ISNULL(orig_zone_code, '') 
			FROM apvend 
			WHERE vendor_code = @cv_code 
	END  
END  


SELECT @prc_border = ISNULL(prc_border, 100.0)  FROM gl_prczone  WHERE zone_code = @local_zone AND cv_zone_code = @cv_zone 
 IF @prc_border IS NULL OR @prc_border <= 0.0 OR @prc_border > 100.0 SELECT @prc_border = 100.0 
 SELECT @disp_amt_freight = @amt_freight * @prc_border / 100.0  SELECT @arr_amt_freight = @amt_freight - @disp_amt_freight 
 END     IF @flag_stat_amt <> 0 AND @is_detail_freight <> 0  BEGIN  UPDATE gl_glinpdet 
 SET disp_stat_amt_nat = ISNULL(amt_nat + @disp_amt_freight, amt_nat),  arr_stat_amt_nat = ISNULL(amt_nat + @arr_amt_freight, amt_nat) 
 WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num AND src_line_id = @src_line_id 
 IF @@error <> 0 RETURN 8100  END     IF @flag_stat_amt <> 0 AND @is_detail_freight = 0 
 BEGIN  IF @total_amt IS NULL OR @total_amt <= 1.192092896e-07  SELECT @flag_stat_amt = 0 
 ELSE  BEGIN  UPDATE gl_glinpdet  SET disp_stat_amt_nat = ISNULL(amt_nat + @disp_amt_freight * (amt_nat / @total_amt), amt_nat), 
 arr_stat_amt_nat = ISNULL(amt_nat + @arr_amt_freight * (amt_nat / @total_amt), amt_nat) 
 WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num AND src_line_id = @src_line_id 
 IF @@error <> 0 RETURN 8100  SELECT @curr_precision = curr_precision  FROM glcurr_vw 
 WHERE currency_code =  (SELECT nat_cur_code FROM gl_glinphdr  WHERE src_trx_id = @src_trx_id 
 AND src_ctrl_num = @src_ctrl_num)  UPDATE gl_glinpdet  SET disp_stat_amt_nat = ROUND(disp_stat_amt_nat, ISNULL(@curr_precision, 2)) 
 WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num AND src_line_id = @src_line_id 
         IF @@error <> 0 RETURN 8100  UPDATE gl_glinpdet  SET arr_stat_amt_nat = ROUND(arr_stat_amt_nat, ISNULL(@curr_precision, 2)) 
 WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num AND src_line_id = @src_line_id 
         IF @@error <> 0 RETURN 8100  END  END     IF @flag_stat_amt = 0  BEGIN  UPDATE gl_glinpdet 
 SET disp_stat_amt_nat = amt_nat,  arr_stat_amt_nat = amt_nat  WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num AND src_line_id = @src_line_id 
 IF @@error <> 0 RETURN 8100  END  RETURN 0 END 
GO
GRANT EXECUTE ON  [dbo].[gl_statamtcalc_sp] TO [public]
GO
