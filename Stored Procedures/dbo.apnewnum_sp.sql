SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\PROCS\apnewnum.SPv - e7.2.2 : 1.5.1.0
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                










 



					 










































 

















































































































































































































































































































































































































































































































































































 































































CREATE PROCEDURE [dbo].[apnewnum_sp]	@trx_type 		smallint, 
								@company_code varchar(8),
								@next_tcn varchar(16) OUTPUT


AS DECLARE 

		@mask varchar(16), 
		@next_number int,
		@result smallint,
		@tran_started smallint



IF (@trx_type = 4091)
	SELECT @mask=voucher_num_mask
	FROM apnumber
ELSE IF (@trx_type = 4092)
	SELECT @mask=dm_num_mask
	FROM apnumber
ELSE IF (@trx_type = 4021)
	SELECT @mask=adj_num_mask
	FROM apnumber
ELSE IF (@trx_type IN (4111,4112,4011))
	SELECT @mask=cash_disb_num_mask
	FROM apnumber
ELSE IF (@trx_type = 4116)
	SELECT @mask=settlement_num_mask
	FROM apnumber


IF ( @@trancount = 0 )
BEGIN
	BEGIN TRAN
	SELECT @tran_started = 1
END


WHILE 1=1
BEGIN
	
IF (@trx_type = 4091)
	UPDATE apnumber
	SET next_voucher_num=next_voucher_num+1
ELSE IF (@trx_type = 4092)
	UPDATE apnumber
	SET next_dm_num=next_dm_num+1
ELSE IF (@trx_type = 4021)
	UPDATE apnumber
	SET next_adj_trx=next_adj_trx+1
ELSE IF (@trx_type IN (4111,4112,4011))
	UPDATE apnumber
	SET next_cash_disb_num = next_cash_disb_num+1
ELSE IF (@trx_type = 4116)
	UPDATE apnumber
	SET next_settlement_num=next_settlement_num+1



IF (@trx_type = 4091)
	SELECT	@next_number=next_voucher_num - 1
	FROM apnumber
ELSE IF (@trx_type = 4092)
	SELECT 	@next_number=next_dm_num - 1
	FROM apnumber
ELSE IF (@trx_type = 4021)
	SELECT	@next_number=next_adj_trx - 1
	FROM apnumber
ELSE IF (@trx_type IN (4111,4112,4011))
	SELECT	@next_number=next_cash_disb_num - 1 
	FROM apnumber
ELSE IF (@trx_type = 4116)
	SELECT	@next_number=next_settlement_num - 1
	FROM apnumber


	
	EXEC fmtctlnm_sp @next_number, 
				@mask, 
				@next_tcn OUTPUT, 
				@result OUTPUT

	IF ( @result != 0 )
	BEGIN
		IF ( @tran_started = 1 )
			ROLLBACK TRAN

		SELECT @next_tcn = NULL

		RETURN -1
	END

	IF @trx_type = 4091
	 BEGIN
		 IF EXISTS( SELECT *	FROM apinpchg
						WHERE trx_ctrl_num = @next_tcn )
				CONTINUE

			IF EXISTS( SELECT * FROM apvohdr
							WHERE trx_ctrl_num = @next_tcn )
				 CONTINUE

	 END
	ELSE IF @trx_type = 4021
	 BEGIN
		 IF EXISTS( SELECT *	FROM apinpchg
						WHERE trx_ctrl_num = @next_tcn )
				CONTINUE

			IF EXISTS( SELECT * FROM apvahdr
							WHERE trx_ctrl_num = @next_tcn )
				 CONTINUE

	 END
	ELSE IF @trx_type = 4092
	 BEGIN
		 IF EXISTS( SELECT *	FROM apinpchg
						WHERE trx_ctrl_num = @next_tcn )
				CONTINUE

			IF EXISTS( SELECT * FROM apdmhdr
							WHERE trx_ctrl_num = @next_tcn )
				 CONTINUE

	 END
	ELSE IF @trx_type IN (4111,4011)
	 BEGIN
		 IF EXISTS( SELECT *	FROM apinppyt
						WHERE trx_ctrl_num = @next_tcn )
				CONTINUE

			IF EXISTS( SELECT * FROM appyhdr
							WHERE trx_ctrl_num = @next_tcn )
				 CONTINUE

	 END
	ELSE IF @trx_type IN (4116)
	 BEGIN
		 IF EXISTS( SELECT *	FROM apinppyt
						WHERE settlement_ctrl_num = @next_tcn )
				CONTINUE

			IF EXISTS( SELECT * FROM appyhdr
							WHERE settlement_ctrl_num = @next_tcn )
				 CONTINUE

	 END
	ELSE IF @trx_type = 4112
	 BEGIN
		 IF EXISTS( SELECT *	FROM apinppyt
						WHERE trx_ctrl_num = @next_tcn )
				CONTINUE

			IF EXISTS( SELECT * FROM appahdr
							WHERE trx_ctrl_num = @next_tcn )
				 CONTINUE

	 END

 
 BREAK


END

IF ( @tran_started = 1 )
	COMMIT TRAN

RETURN 0




/**/                                              
GO
GRANT EXECUTE ON  [dbo].[apnewnum_sp] TO [public]
GO
