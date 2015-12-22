SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


 
CREATE PROCEDURE [dbo].[icv_verisign_batch] AS
BEGIN
	DECLARE @buf			CHAR(255)
	DECLARE	@LogActivity		CHAR(3)

	DECLARE @spid			INT
	DECLARE @trx_ctrl_num		VARCHAR(16)
	DECLARE @prompt1_inp 		VARCHAR(30)
	DECLARE @prompt2_inp 		VARCHAR(30)
	DECLARE @prompt3_inp 		VARCHAR(30)
	DECLARE @amt_payment 		FLOAT
	DECLARE @prompt4_inp 		VARCHAR(30)
	DECLARE @trx_code 		CHAR(2)
	DECLARE @new_ctrl_num 		CHAR(16)
	DECLARE @Month			CHAR(2)
	DECLARE @Year 			CHAR(4)
	DECLARE @xAmt 			CHAR(255)
	DECLARE @response		CHAR(255)
	DECLARE @valid			CHAR(1)
	DECLARE @authorization		VARCHAR(255)
	DECLARE @ret			INT
	DECLARE @iMonth			INT
	DECLARE @iYear			INT
	DECLARE @arinpchg_rowcount	INT
	DECLARE @arinppyt_rowcount	INT
	DECLARE @arinptmp_rowcount	INT
	DECLARE @arinptmp2_rowcount	INT
	DECLARE @payment_code		CHAR(8)
	DECLARE @customer_code		CHAR(8)
	DECLARE @rowcount		INT
	DECLARE @dateValid		INT
	DECLARE @result			INT
	DECLARE @I			INT
        DECLARE @nat_cur_code		VARCHAR(8)
	DECLARE @trx_type		SMALLINT	

	SET NOCOUNT ON

	SELECT @spid = @@spid, @ret = 0

	SELECT @buf = UPPER(configuration_text_value)
	 FROM icv_config
	 WHERE UPPER(configuration_item_name) = 'LOG ACTIVITY'

	IF @@rowcount <> 1
		SELECT @buf = 'NO'

	IF @buf = 'YES'
	BEGIN
		SELECT @LogActivity = 'YES'
	END
	ELSE
	BEGIN
		SELECT @LogActivity = 'NO'
	END


	DECLARE tmif_cursor INSENSITIVE CURSOR FOR 
	 SELECT trx_ctrl_num, prompt1_inp, prompt2_inp, prompt3_inp, amt_payment, trx_code FROM icv_temp WHERE spid = @spid

	OPEN tmif_cursor
	 FETCH NEXT FROM tmif_cursor INTO @trx_ctrl_num, @prompt1_inp, @prompt2_inp, @prompt3_inp, @amt_payment, @trx_code
					
	WHILE (@@FETCH_STATUS <> -1)
	BEGIN
		IF @@FETCH_STATUS <> -2
		BEGIN
			
			EXEC @result = icv_parse_expiration @prompt3_inp, @iMonth OUTPUT, @iYear OUTPUT, @dateValid OUTPUT
			IF @dateValid = 0
			BEGIN
				EXEC icv_Get_External_String_sp 'Invalid expiration date: ', @buf OUT
				SELECT @buf = @buf + @prompt3_inp
				EXEC icv_Log_sp @buf, @LogActivity
				GOTO FETCHNEXT
			END 

			SELECT @Month = CONVERT(CHAR(2), @iMonth)
			SELECT @Year = CONVERT(CHAR(4), @iYear)
			SELECT @xAmt = RTRIM(LTRIM(STR(@amt_payment,10,2)))

			SELECT @nat_cur_code= nat_cur_code, @trx_type = 2031 
			FROM arinpchg  
			WHERE trx_ctrl_num = @trx_ctrl_num AND  trx_type = 2031


			
			SELECT @payment_code = payment_code, @customer_code = customer_code
			  FROM arinptmp
			 WHERE trx_ctrl_num = @trx_ctrl_num
			SELECT @rowcount = @@rowcount

			IF @rowcount = 0
			BEGIN
				SELECT @buf = 'Get CC information from arinppyt'
				EXEC icv_Log_sp @buf, @LogActivity

				SELECT @payment_code = payment_code, @customer_code = customer_code, 
				       @nat_cur_code =nat_cur_code, @trx_type = 2111
				  FROM arinppyt
				 WHERE trx_ctrl_num = @trx_ctrl_num
				SELECT @rowcount = @@rowcount
			END

			EXEC @ret = icv_verisign @trx_code, @prompt2_inp, @Month, @Year, @xAmt, @response OUTPUT, 0, 0, @prompt1_inp, @trx_ctrl_num,@customer_code,@nat_cur_code,@trx_type

			SELECT @I = CHARINDEX( CHAR(34), SUBSTRING( @response, 2, 255 ) )

			IF ((@ret <> 0) OR (@I = 0))
			BEGIN
				EXEC icv_Convert_HRESULT_sp @ret, @buf OUT
				SELECT @buf = 'Nonzero return from icv_verisign: ' + RTRIM(LTRIM(@buf))
				EXEC icv_Log_sp @buf, @LogActivity
				
				INSERT INTO  #cca_errors (trx_ctrl_num,error_code, response)
				VALUES  (@trx_ctrl_num, @ret, @response)
 				
			END

			SELECT @iMonth = CONVERT(INT, @Month), @iYear = CONVERT(INT, @Year)
			EXEC icv_history 1, '', @trx_ctrl_num, @prompt1_inp, @prompt2_inp, @iMonth, @iYear, @amt_payment, @trx_code, @response
			EXEC icv_history 2, @response

			SELECT @authorization = SUBSTRING(@response, 3, @I - 2)
			IF CHARINDEX(':', @authorization)=0 
				SELECT @authorization=@authorization+':'+ SUBSTRING(@response, LEN(@authorization)+4,LEN (@response)-1)
			

			SELECT @response = RTRIM(LTRIM(SUBSTRING(@response,2,ISNULL(DATALENGTH(RTRIM(LTRIM(@response))),0)-2)))
--			SELECT @authorization = RTRIM(LTRIM(SUBSTRING(@response,2,ISNULL(DATALENGTH(RTRIM(LTRIM(@response))),0)-1)))

			SELECT @valid = UPPER(SUBSTRING(@response, 1, 1))


			IF @valid = 'Y'
			BEGIN
				IF (@trx_code = 'C4')
					SELECT @authorization = 'BOOKED'

				UPDATE arinpchg SET hold_flag = 0
				 WHERE trx_ctrl_num = @trx_ctrl_num
				SELECT @arinpchg_rowcount = @@ROWCOUNT
				UPDATE arinppyt SET hold_flag = 0, prompt4_inp = @authorization
				 WHERE trx_ctrl_num = @trx_ctrl_num
				SELECT @arinppyt_rowcount = @@ROWCOUNT
				UPDATE arinptmp SET prompt4_inp = @authorization
				 WHERE trx_ctrl_num = @trx_ctrl_num
				SELECT @arinptmp_rowcount = @@ROWCOUNT
				UPDATE arinptmp SET arinptmp.prompt4_inp = @authorization
				 FROM arinptmp AS a, arinpchg AS b
				 WHERE a.trx_ctrl_num = b.trx_ctrl_num
				 AND b.order_ctrl_num = @trx_ctrl_num
				SELECT @arinptmp2_rowcount = @@ROWCOUNT
				SELECT @buf = 'Batch booking succeeded, @trx_ctrl_num: ' + @trx_ctrl_num + ', @authorization: ' + @authorization
				EXEC icv_Log_sp @buf, @LogActivity

				SELECT @buf = 'arinpchg: ' + RTRIM(LTRIM(CONVERT(CHAR, @arinpchg_rowcount))) + ', ' + 'arinppyt: ' + RTRIM(LTRIM(CONVERT(CHAR, @arinppyt_rowcount))) + ', ' + 'arinptmp: ' + RTRIM(LTRIM(CONVERT(CHAR, @arinptmp_rowcount))) + ', ' + 'arinptmp2: ' + RTRIM
				(LTRIM(CONVERT(CHAR, @arinptmp2_rowcount)))
				EXEC icv_Log_sp @buf, @LogActivity
	
				
				SELECT @payment_code = payment_code, @customer_code = customer_code
				 FROM arinptmp
				 WHERE trx_ctrl_num = @trx_ctrl_num
				SELECT @rowcount = @@rowcount

				IF @rowcount = 0
				BEGIN
					SELECT @buf = 'Get CC information from arinppyt'
					EXEC icv_Log_sp @buf, @LogActivity
					SELECT @payment_code = payment_code, @customer_code = customer_code
					 FROM arinppyt
					 WHERE trx_ctrl_num = @trx_ctrl_num
					SELECT @rowcount = @@rowcount
				END

				IF @rowcount = 0
				BEGIN
					SELECT @buf = 'Get CC information based on order_ctrl_num'
					EXEC icv_Log_sp @buf, @LogActivity
					SELECT @payment_code = a.payment_code, @customer_code = a.customer_code
					 FROM arinptmp AS a, arinpchg AS b
					 WHERE a.trx_ctrl_num = b.trx_ctrl_num
					 AND b.order_ctrl_num = @trx_ctrl_num
					SELECT @rowcount = @@rowcount
				END

				SELECT @buf = 'payment_code: ' + RTRIM(LTRIM(@payment_code)) + ', customer_code: ' + RTRIM(LTRIM(@customer_code)) + ', trx_ctrl_num: ' + RTRIM(LTRIM(@trx_ctrl_num)) + ', rowcount: ' + RTRIM(LTRIM(CONVERT(CHAR, @rowcount)))
				EXEC icv_Log_sp @buf, @LogActivity
	
				IF @rowcount <> 0
				BEGIN
					EXEC icv_savecc @payment_code, @customer_code, @prompt1_inp, @prompt2_inp, @prompt3_inp, ''
				END
			END
		    
























		END

FETCHNEXT:
		FETCH NEXT FROM tmif_cursor INTO @trx_ctrl_num, @prompt1_inp, @prompt2_inp, @prompt3_inp, @amt_payment, @trx_code
	END

	CLOSE tmif_cursor
	DEALLOCATE tmif_cursor

ITBOUT:
	RETURN @ret

END


grant execute on icv_verisign_batch to public
GO
GRANT EXECUTE ON  [dbo].[icv_verisign_batch] TO [public]
GO
