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
           CREATE PROCEDURE [dbo].[eft_ctxprovld_sp] @bank_account_num varchar(20), @aba_number varchar(16), 
@account_type smallint , @char_parm1 varchar(12), @char_parm2 varchar(8) AS    DECLARE 
 @lenght int ,  @check char(10),  @e_code int,  @result smallint  SELECT @result = 0 
    IF @bank_account_num = ' ' BEGIN SELECT @e_code = 33000 EXEC @result = eft_erup_sp 
 @e_code,  @char_parm1,  @char_parm2 END   ELSE     BEGIN  SELECT @lenght = datalength(rtrim(@bank_account_num )) 
 IF (@lenght > 17)  BEGIN  SELECT @e_code = 33001  EXEC @result= eft_erup_sp  @e_code, 
 @char_parm1,  @char_parm2  END  END      IF @aba_number = ' '  BEGIN  SELECT @e_code = 33002 
 EXEC @result = eft_erup_sp  @e_code,  @char_parm1,  @char_parm2  END   ELSE  BEGIN 
     SELECT @lenght = datalength(ltrim(@aba_number))  IF (@lenght <> 9)  BEGIN  SELECT @e_code = 33003 
 EXEC @result = eft_erup_sp  @e_code,  @char_parm1,  @char_parm2  END  ELSE  BEGIN 
 SELECT @check = 'OK'  IF (SUBSTRING(ltrim(@aba_number),1,8) LIKE '%[a-z]%' ) -- SCR 1292 Make sure first 8 characters are numeric 
 SELECT @check = 'ERROR'  IF (@check = 'ERROR')  BEGIN  SELECT @e_code = 33003  EXEC @result = eft_erup_sp 
 @e_code,  @char_parm1,  @char_parm2  END  END   END      IF @account_type IN (0,1) 
BEGIN SELECT @e_code = 0 END  ELSE  BEGIN  SELECT @e_code = 33004  EXEC @result = eft_erup_sp 
 @e_code,  @char_parm1,  @char_parm2  END 
GO
GRANT EXECUTE ON  [dbo].[eft_ctxprovld_sp] TO [public]
GO
