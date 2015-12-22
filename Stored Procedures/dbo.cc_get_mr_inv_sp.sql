SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_get_mr_inv_sp]	@customer_code varchar(8),
																	@posted_status	smallint = 0,
																	@days_old int = 0

AS

	DECLARE 		@mask	varchar(16),
					@pos_str	varchar(2),
					@start_pos	smallint,
					@cur_pos	smallint,
					@mask_len	smallint,
					@mask_lenp	smallint,
					@today int

	
	



	SELECT		@start_pos = 0,
					@cur_pos = 0,
					@mask_len = 0

	SELECT @mask = mask from ewnumber where num_type = 2997

	SELECT @mask_len = DATALENGTH(@mask)

	SELECT @today = DATEDIFF(dd, '1/1/1753', CONVERT(datetime, GETDATE())) + 639906

	



	SELECT @cur_pos = 1

	WHILE ( @cur_pos <= @mask_len)
 	BEGIN
			SELECT @pos_str = SUBSTRING(@mask, @cur_pos, 1)

			IF @start_pos = 0
				BEGIN
					IF @pos_str = '0' OR @pos_str = '#'
						SELECT @start_pos = @cur_pos, @mask_lenp = 1
				END
			ELSE
				BEGIN
					IF @pos_str != '0' AND @pos_str != '#'
						BREAK
		
					SELECT @mask_lenp = @mask_lenp + 1
				END

			SELECT @cur_pos = @cur_pos + 1
		END

	SELECT @mask = SUBSTRING(@mask, 1, @start_pos - 1)
	SELECT @mask = @mask + '%'


	IF @posted_status = 0
		SELECT DISTINCT doc_ctrl_num 
		FROM artrx 
		WHERE ( source_trx_type = 2998 OR doc_ctrl_num LIKE @mask )
		AND customer_code = @customer_code
		AND void_flag = 0
		AND date_doc >= @today - @days_old
	ELSE
		SELECT DISTINCT doc_ctrl_num 
		FROM arinpchg 
		WHERE source_trx_type = 2998
		AND	trx_type = 2031
		AND customer_code = @customer_code
		AND date_doc >= @today - @days_old
		UNION
		SELECT DISTINCT doc_ctrl_num 
		FROM arinpchg 
		WHERE trx_type = 2998
		AND customer_code = @customer_code
		AND date_doc >= @today - @days_old


GO
GRANT EXECUTE ON  [dbo].[cc_get_mr_inv_sp] TO [public]
GO
