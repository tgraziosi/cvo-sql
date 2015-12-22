SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROC [dbo].[cc_del_note_sp]	@company_code	varchar(8),
									@key_type 		smallint,
									@key_1 			varchar(32),
									@sequence_id 	varchar(8000),
									@customer_code	varchar(8)

AS
	DECLARE @key_type_str varchar(20),
					@trx_num			varchar(16)

	SELECT @key_type_str = CONVERT(varchar(20), @key_type)









	IF @key_type = 2510
		EXEC(	'	DELETE comments 
						WHERE company_code = "' + @company_code + '" ' +
					'	AND key_1 = "' + @key_1 + '" ' + 
					'	AND key_type  = ' + @key_type_str +
					'	AND sequence_id IN ' + @sequence_id )
	ELSE
		BEGIN
			SELECT @trx_num = trx_ctrl_num 
			FROM artrx 
			WHERE doc_ctrl_num = @key_1 AND trx_type = @key_type

			AND customer_code = @customer_code


			EXEC(	'	DELETE comments 
							WHERE company_code = "' + @company_code + '" ' +
						'	AND key_1 = "' + @trx_num + '" ' + 
						'	AND key_type  = ' + @key_type_str +
						'	AND sequence_id IN ' + @sequence_id )
		END

GO
GRANT EXECUTE ON  [dbo].[cc_del_note_sp] TO [public]
GO
