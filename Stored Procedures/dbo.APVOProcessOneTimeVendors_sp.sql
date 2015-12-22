SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE PROC [dbo].[APVOProcessOneTimeVendors_sp] @debug_level smallint = 0

AS

DECLARE
			@one_time_count int,
			@pay_to_num int,
			@pay_to_num_mask varchar(16),
			@pay_to_code varchar(8),
			@result int


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvopotv.sp" + ", line " + STR( 56, 5 ) + " -- ENTRY: "


SELECT @one_time_count = count(trx_ctrl_num)
FROM #apvochg_work
WHERE one_time_vend_flag = 1




BEGIN TRAN PAYTONUMBERS

		UPDATE apnumber
		SET next_pay_to_num = next_pay_to_num + @one_time_count 

		SELECT @pay_to_num = next_pay_to_num - @one_time_count,
				@pay_to_num_mask = pay_to_num_mask
		FROM apnumber


COMMIT TRAN PAYTONUMBERS



	INSERT #apvomast_work
	(
		trx_ctrl_num, 
		vendor_code, 
		pay_to_code, 
		address_name,
		addr1, 
		addr2,
		addr3, 
		addr4, 
		addr5,
		addr6,
		attention_name, 
		attention_phone,
		db_action,
		rate_type_home,
		rate_type_oper,
		nat_cur_code )
	SELECT
		trx_ctrl_num, 
		vendor_code,
		"", 			
		pay_to_addr1,
		pay_to_addr1, 
		pay_to_addr2,
		pay_to_addr3, 
		pay_to_addr4, 
		pay_to_addr5,
		pay_to_addr6,
		attention_name, 
		attention_phone,
		2,
		rate_type_home,
		rate_type_oper,
		nat_cur_code
	FROM #apvochg_work
	WHERE one_time_vend_flag = 1




WHILE (1=1)
 BEGIN

 		exec fmtctlnm_sp @pay_to_num, @pay_to_num_mask, 
		@pay_to_code OUTPUT, @result OUTPUT

		 
		 SET ROWCOUNT 1

		 UPDATE #apvomast_work
		 SET pay_to_code = @pay_to_code
		 WHERE pay_to_code = ""

		 IF @@rowcount = 0 BREAK

		 SET ROWCOUNT 0


		 SELECT @pay_to_num = @pay_to_num + 1

 END

SET ROWCOUNT 0


UPDATE #apvochg_work
SET pay_to_code = b.pay_to_code
FROM #apvochg_work a, #apvomast_work b
WHERE a.trx_ctrl_num = b.trx_ctrl_num
AND a.one_time_vend_flag = 1



UPDATE #apinppyt
SET pay_to_code = a.pay_to_code
FROM #apvochg_work a, #apinppyt



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvopotv.sp" + ", line " + STR( 173, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APVOProcessOneTimeVendors_sp] TO [public]
GO
