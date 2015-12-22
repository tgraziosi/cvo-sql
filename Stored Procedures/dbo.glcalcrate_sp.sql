SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROC [dbo].[glcalcrate_sp]
AS
		SET ROWCOUNT 1
		SELECT 1 FROM #gltrxdet WHERE rate_oper = NULL
		IF (@@ROWCOUNT > 0 )
		BEGIN 
				


				DECLARE @nat_currency_code VARCHAR(8),
						@oper_currency_code VARCHAR(8),
						@oper_rate_type		VARCHAR(8),
						@home_rate_type		VARCHAR(8),
						@oper_prec			smallint,
						@currency_date		int,
						@rate_used			float,
						@result				INT

				


				SELECT	@oper_currency_code = oper_currency,
						@oper_rate_type = rate_type_oper,
						@home_rate_type = rate_type_home
				FROM glco
				SET ROWCOUNT 0
				
				


				SELECT @oper_prec = curr_precision
					FROM    glcurr_vw
				WHERE   currency_code = @oper_currency_code
				
				



				UPDATE  #gltrxdet
						SET rate_oper =	1
					FROM #gltrxdet
						WHERE nat_cur_code = @oper_currency_code
				
				


				SELECT DISTINCT d.nat_cur_code, h.date_applied INTO #currency_date
					FROM   #gltrxdet d
						INNER JOIN #gltrx h	ON h.journal_ctrl_num=  d.journal_ctrl_num
					WHERE rate_oper = NULL 
				
				SET ROWCOUNT 1
				SELECT @nat_currency_code = nat_cur_code FROM #currency_date ORDER BY nat_cur_code
				SET ROWCOUNT 0
				


				WHILE @nat_currency_code IS NOT NULL
				BEGIN
					
					SET ROWCOUNT 1
					SELECT @currency_date = date_applied FROM #currency_date WHERE @nat_currency_code = nat_cur_code
					ORDER BY date_applied 
					SET ROWCOUNT 0
					


					WHILE @currency_date IS NOT NULL
					BEGIN
							


							EXEC @result = CVO_Control..mccurate_sp 	@currency_date, 
										@nat_currency_code, @oper_currency_code,
										@oper_rate_type, @rate_used OUTPUT, 0
										
							IF  (@result != 0) BEGIN
								


								UPDATE  #gltrxdet
									SET     mark_flag = 1
								FROM  #gltrxdet d
									INNER JOIN #gltrx h	ON h.journal_ctrl_num=  d.journal_ctrl_num
									WHERE h.date_applied = @currency_date 
										AND d.nat_cur_code = @nat_currency_code AND d.rate_oper = NULL
							END
							
							

							
							UPDATE  #gltrxdet
								SET     balance_oper = (SIGN(balance * ( SIGN(1 + SIGN(@rate_used))*(@rate_used) + (SIGN(ABS(SIGN(ROUND(@rate_used,6))))/(@rate_used + SIGN(1 - ABS(SIGN(ROUND(@rate_used,6)))))) * SIGN(SIGN(@rate_used) - 1) )) * ROUND(ABS(balance * ( SIGN(1 + SIGN(@rate_used))*(@rate_used) + (SIGN(ABS(SIGN(ROUND(@rate_used,6))))/(@rate_used + SIGN(1 - ABS(SIGN(ROUND(@rate_used,6)))))) * SIGN(SIGN(@rate_used) - 1) )) + 0.0000001, @oper_prec)),
								rate_oper = @rate_used
							FROM #gltrxdet d
								INNER JOIN #gltrx h	ON h.journal_ctrl_num=  d.journal_ctrl_num
								WHERE h.date_applied = @currency_date AND d.nat_cur_code = @nat_currency_code AND d.rate_oper = NULL
						
						

	
						SET ROWCOUNT 1
						SELECT @currency_date = date_applied FROM #currency_date 
							WHERE nat_cur_code = @nat_currency_code AND date_posted > @currency_date
							ORDER BY date_applied 
						SET ROWCOUNT 0
					END
					
					

	
					SET ROWCOUNT 1
					SELECT @nat_currency_code = nat_cur_code FROM #currency_date 
						WHERE nat_cur_code > @nat_currency_code AND rate_oper = NULL
					SET ROWCOUNT 0
					
				END

				DROP TABLE #currency_date
		END
		SET ROWCOUNT 0
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glcalcrate_sp] TO [public]
GO
