SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[mtvendck_sp] @vendor_code varchar(8),  @ep_currency_code varchar(8),  @new_vendor_ok smallint output 
AS DECLARE  @dft_currency_code varchar(8),  @one_cur_vendor smallint,  @remit_currency_code varchar(8), 
 @pay_to_code varchar(8) BEGIN TRANSACTION  SELECT @one_cur_vendor = one_cur_vendor 
 FROM apvend  WHERE vendor_code = @vendor_code  IF @@error != 0  BEGIN  ROLLBACK TRANSACTION 
 RETURN -1  END  IF ( (SELECT multi_currency_flag FROM glco) = 0 )  BEGIN  IF ( (SELECT home_currency FROM glco) != @ep_currency_code ) 
 SELECT @new_vendor_ok = 0  ELSE  SELECT @new_vendor_ok = 1  END  ELSE  BEGIN  IF ( @one_cur_vendor = 1 ) 
 BEGIN  SET ROWCOUNT 1       SELECT @dft_currency_code = ISNULL(nat_cur_code, ""), 
 @pay_to_code = ISNULL(pay_to_code, "")  FROM apvend  WHERE vendor_code = @vendor_code 
 SELECT @remit_currency_code = ISNULL(nat_cur_code, "")  FROM appayto  WHERE vendor_code = @vendor_code 
 AND pay_to_code = @pay_to_code  IF @@error != 0  BEGIN  ROLLBACK TRANSACTION  RETURN -1 
 END  IF ( @remit_currency_code != "" )  BEGIN           IF (@remit_currency_code = @ep_currency_code) 
 SELECT @new_vendor_ok = 1  ELSE  SELECT @new_vendor_ok = 0  END  ELSE          IF (@dft_currency_code = @ep_currency_code) 
 SELECT @new_vendor_ok = 1  ELSE  SELECT @new_vendor_ok = 0  END  ELSE  SELECT @new_vendor_ok = 1 
 END COMMIT TRANSACTION RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[mtvendck_sp] TO [public]
GO
