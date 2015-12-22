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
                                                                    CREATE PROC [dbo].[gl_makesrcnum_sp] 
 @src_trx_id varchar(4),  @is_adm_call smallint,  @ctrl_int int,  @ext_int int,  @ctrl_str varchar(16), 
 @ext_str varchar(20),  @alt_ctrl_str varchar(16),  @src_doc_num varchar(36) OUTPUT 
AS BEGIN  IF @is_adm_call = 0  SELECT @src_doc_num =  CASE @src_trx_id  WHEN "2031" THEN @ctrl_str 
 WHEN "2032" THEN @ctrl_str  WHEN "4091" THEN @ctrl_str  WHEN "4092" THEN @ctrl_str 
 WHEN "OEIV" THEN @ext_str  WHEN "OECM" THEN @ext_str  WHEN "PMVO" THEN CONVERT(char(16), @alt_ctrl_str) + CONVERT(char(20), @ext_str) 
 WHEN "PMDM" THEN CONVERT(char(16), @alt_ctrl_str) + CONVERT(char(20), @ext_str) 
 ELSE ''  END  ELSE  SELECT @src_doc_num =  CASE @src_trx_id  WHEN "OEIV" THEN LTRIM(RTRIM(STR(@ctrl_int, 16))) + '-' + LTRIM(RTRIM(STR(@ext_int, 16))) 
 WHEN "OECM" THEN LTRIM(RTRIM(STR(@ctrl_int, 16))) + '-' + LTRIM(RTRIM(STR(@ext_int, 16))) 
 WHEN "PMVO" THEN CONVERT(char(16), @ctrl_int) + CONVERT(char(20), @ext_str)  WHEN "PMDM" THEN CONVERT(char(16), @ctrl_int) + CONVERT(char(20), @ext_str) 
 WHEN "IVSH" THEN LTRIM(RTRIM(STR(@ctrl_int, 16)))  WHEN "IVRV" THEN LTRIM(RTRIM(STR(@ctrl_int, 16))) 
 ELSE ''  END  IF @src_doc_num = '' RETURN 8145  RETURN 0 END 
GO
GRANT EXECUTE ON  [dbo].[gl_makesrcnum_sp] TO [public]
GO
