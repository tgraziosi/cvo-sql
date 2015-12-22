SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


    CREATE PROCEDURE 
[dbo].[imgltrxval_sp] @org_company varchar(8),
              @rec_company varchar(8),
              @journal_ctrl_num varchar(16) = NULL,
              @sequence_id int = NULL,
              @debug_level smallint = 0
    AS
    BEGIN
    DECLARE @result int,
            @home_currency_code varchar(8),
            @prec int,
            @rounding_factor float,
            @validate_details_flag smallint,
            @header_only_flag smallint,
            @work_time datetime,
            @start_time datetime,
            @oper_currency_code    varchar(8),
            @oper_prec        int,
            @oper_rounding_factor    float
    DECLARE @Routine_Name VARCHAR(128)
    SET @Routine_Name = 'imgltrxval_sp'
    IF @debug_level > 1
        BEGIN
        SELECT @Routine_Name + ': Entry.'
        SELECT @Routine_Name + ': Stored procedure parameters:'
        SELECT @Routine_Name + ':     @org_company: ' + @org_company
        SELECT @Routine_Name + ':     @rec_company: ' + @rec_company
        SELECT @Routine_Name + ':     @journal_ctrl_num: ' + ISNULL(@journal_ctrl_num, 'NULL')
        SELECT @Routine_Name + ':     @sequence_id: ' + ISNULL(CAST(@sequence_id AS VARCHAR), 'NULL')
        SELECT @Routine_Name + ':     @debug_level: ' + CAST(@debug_level AS VARCHAR)
    END
	SELECT @validate_details_flag = 0,
		@header_only_flag = 0
	
	
	SELECT @home_currency_code = home_currency,
		@oper_currency_code = oper_currency
	FROM glco
	
	SELECT @rounding_factor = rounding_factor,
		@prec = curr_precision
	FROM glcurr_vw
	WHERE currency_code = @home_currency_code

	SELECT @oper_rounding_factor = rounding_factor,
		@oper_prec = curr_precision
	FROM glcurr_vw
	WHERE currency_code = @oper_currency_code


	IF ( @rounding_factor IS NULL OR @prec IS NULL 
	OR @oper_rounding_factor IS NULL OR @oper_prec IS NULL )
	BEGIN
		RETURN 1050
	END
	
	IF ( @journal_ctrl_num IS NOT NULL )
	BEGIN
		UPDATE #gltrx
		SET trx_state = -1
		WHERE journal_ctrl_num = @journal_ctrl_num
		
		SELECT @header_only_flag = 1
		
		IF ( @sequence_id IS NOT NULL )
		BEGIN
			UPDATE #gltrxdet
			SET trx_state = -1
			WHERE journal_ctrl_num = @journal_ctrl_num
			AND sequence_id = @sequence_id
			
			SELECT @validate_details_flag = 1
		END

	END
	
	ELSE
	BEGIN
		UPDATE #gltrx
		SET trx_state = -1
		WHERE trx_state = 0
		AND company_code = @org_company
		
		UPDATE #gltrxdet
		SET trx_state = -1
		WHERE trx_state = 0
		AND rec_company_code = @rec_company
		
		SELECT @validate_details_flag = 1
	END
	
	IF ( @debug_level > 2 ) SELECT "tmp/gltrxval.sp" + ", line " + STR( 154, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Preparation Complete"

    IF ( @debug_level > 2 )
        BEGIN
        SELECT @Routine_Name + ': ' + LTRIM(RTRIM(CAST(COUNT(*) AS VARCHAR))) + ' transaction(s) to validate'
        FROM    #gltrx
        WHERE    trx_state = -1
        
        SELECT @Routine_Name + ':     with ' + LTRIM(RTRIM(CAST(COUNT(*) AS VARCHAR))) + ' transaction detail(s).'
        FROM    #gltrxdet
        WHERE    trx_state = -1
        
        END
	
	IF ( @validate_details_flag = 1 )
	BEGIN
		
		UPDATE #gltrxdet
		SET mark_flag = 1
		FROM glcomp_vw c, #gltrxdet t
		WHERE c.company_code = t.rec_company_code
		AND t.trx_state = -1
		
		INSERT #trxerror ( 
			journal_ctrl_num, 
			sequence_id, 
			error_code )
		SELECT journal_ctrl_num, 
			sequence_id, 
			1005 
		FROM #gltrxdet
		WHERE mark_flag = 0
		AND trx_state = -1
		
		UPDATE #gltrxdet
		SET mark_flag = 0
		WHERE trx_state = -1
		
		IF ( @debug_level > 2 ) SELECT "tmp/gltrxval.sp" + ", line " + STR( 202, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Validate details recipient company code"

		
		UPDATE #gltrxdet
		SET mark_flag = 1
		FROM glcomp_vw a, #gltrxdet t
		WHERE a.company_id = t.company_id
		AND t.trx_state = -1
		
		INSERT #trxerror ( 
			journal_ctrl_num, 
			sequence_id, 
			error_code )
		SELECT journal_ctrl_num, 
			sequence_id, 
			1006
		FROM #gltrxdet
		WHERE mark_flag = 0
		AND trx_state = -1
		
		UPDATE #gltrxdet
		SET mark_flag = 0
		WHERE trx_state = -1

		IF ( @debug_level > 2 ) SELECT "tmp/gltrxval.sp" + ", line " + STR( 230, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Validate details company ID"

		
		UPDATE #gltrxdet
		SET mark_flag = 1
		FROM glchart a, #gltrxdet t
		WHERE a.account_code = t.account_code
		AND t.trx_state = -1
		
		INSERT #trxerror ( 
			journal_ctrl_num, 
			sequence_id, 
			error_code )
		SELECT journal_ctrl_num, 
			sequence_id, 
			1007
		FROM #gltrxdet
		WHERE mark_flag = 0
		AND trx_state = -1
		
		UPDATE #gltrxdet
		SET mark_flag = 0
		WHERE trx_state = -1

		IF ( @debug_level > 2 ) SELECT "tmp/gltrxval.sp" + ", line " + STR( 258, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Validate details account code"
		
		UPDATE #gltrxdet
		SET mark_flag = 1
		FROM glchart a, #gltrxdet t
		WHERE a.account_code = t.account_code
		AND t.trx_state = -1
		AND	(a.currency_code = t.nat_cur_code
		OR	a.currency_code = "")
		
		INSERT #trxerror ( 
			journal_ctrl_num, 
			sequence_id, 
			error_code )
		SELECT journal_ctrl_num, 
			sequence_id, 
			3021
		FROM #gltrxdet
		WHERE mark_flag = 0
		AND trx_state = -1
		
		UPDATE #gltrxdet
		SET mark_flag = 0
		WHERE trx_state = -1

		IF ( @debug_level > 2 ) SELECT "tmp/gltrxval.sp" + ", line " + STR( 287, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Validate currency code against account code"
		
		UPDATE #gltrxdet
		SET mark_flag = 1
		FROM glcurr_vw a, #gltrxdet t
		WHERE a.currency_code = t.nat_cur_code
		AND t.trx_state = -1

		
 UPDATE #gltrx
 SET mark_flag = 1
		FROM #gltrx t, glcurr_vw c
 WHERE c.currency_code = t.oper_cur_code
 AND trx_state = -1

		
		INSERT #trxerror ( 
			journal_ctrl_num, 
			sequence_id, 
			error_code )
		SELECT journal_ctrl_num, 
			sequence_id, 
			1009
		FROM #gltrxdet
		WHERE mark_flag = 0
		AND trx_state = -1
		
		UPDATE #gltrxdet
		SET mark_flag = 0
		WHERE trx_state = -1

		IF ( @debug_level > 2 ) SELECT "tmp/gltrxval.sp" + ", line " + STR( 322, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Validate details natural currency code"
		
		UPDATE #gltrxdet
		SET mark_flag = 1
		FROM gltrxtyp a, #gltrxdet t
		WHERE a.trx_type = t.trx_type
		AND t.trx_state = -1
		
		INSERT #trxerror ( 
			journal_ctrl_num, 
			sequence_id, 
			error_code )
		SELECT journal_ctrl_num, 
			sequence_id, 
			1010
		FROM #gltrxdet
		WHERE mark_flag = 0
		AND trx_state = -1
		
		UPDATE #gltrxdet
		SET mark_flag = 0
		WHERE trx_state = -1

		IF ( @debug_level > 2 ) SELECT "tmp/gltrxval.sp" + ", line " + STR( 349, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Validate details transaction type"
		
		INSERT #trxerror ( 
			journal_ctrl_num, 
			sequence_id, 
			error_code )
		SELECT journal_ctrl_num, 
			sequence_id, 
			3025
		FROM #gltrxdet
		WHERE balance_oper IS NULL
		AND trx_state = -1

		IF ( @debug_level > 2 ) SELECT "tmp/gltrxval.sp" + ", line " + STR( 366, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Validate operational balance"
	END

	
	
	
	
	UPDATE #gltrx
	SET mark_flag = 1
	FROM #gltrx h, glprd p, glprd q
	WHERE h.trx_state = -1
	AND (h.repeating_flag = 1 
	OR h.reversing_flag = 1
	OR h.recurring_flag = 1)
	AND h.date_applied
	BETWEEN p.period_start_date AND p.period_end_date
	AND p.period_end_date < q.period_end_date

	
	INSERT #trxerror (
		journal_ctrl_num,
		sequence_id,
		error_code )
	SELECT journal_ctrl_num, 
		-1,
		1040
	FROM #gltrx
	WHERE (repeating_flag = 1
	OR reversing_flag = 1)
	AND mark_flag = 0
	AND trx_state = -1
	
	UPDATE #gltrx
	SET mark_flag = 0
	WHERE trx_state = -1

	IF ( @debug_level > 2 ) SELECT "tmp/gltrxval.sp" + ", line " + STR( 415, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Validate next fiscal period"
	
	UPDATE #gltrx
	SET mark_flag = 1
	FROM #gltrx t, glprd p
	WHERE t.date_applied BETWEEN p.period_start_date and p.period_end_date
	AND t.trx_state = -1

	INSERT #trxerror ( 
		journal_ctrl_num, 
		sequence_id, 
		error_code )
	SELECT journal_ctrl_num, 
		-1, 
		1023
	FROM #gltrx
	WHERE mark_flag = 0
	AND trx_state = -1

	UPDATE #gltrx
	SET mark_flag = 0
	WHERE trx_state = -1

	IF ( @debug_level > 2 ) SELECT "tmp/gltrxval.sp" + ", line " + STR( 442, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Validate apply date"
	
	IF ( @rec_company = @org_company )
	BEGIN
		
		UPDATE #gltrx
		SET mark_flag = 1
		FROM gltrxtyp a, #gltrx t
		WHERE a.trx_type = t.trx_type
		AND t.trx_state = -1
		
		INSERT #trxerror ( 
			journal_ctrl_num, 
			sequence_id, 
			error_code )
		SELECT journal_ctrl_num, 
			-1, 
			1010
		FROM #gltrx
		WHERE mark_flag = 0
		AND trx_state = -1
		
		UPDATE #gltrx
		SET mark_flag = 0
		WHERE trx_state = -1

		IF ( @debug_level > 2 ) SELECT "tmp/gltrxval.sp" + ", line " + STR( 475, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Validate transaction type"
		
		UPDATE #gltrx
		SET mark_flag = 1
		FROM glappid a, #gltrx t
		WHERE a.app_id = t.app_id
		AND t.trx_state = -1
		
		INSERT #trxerror ( 
			journal_ctrl_num, 
			sequence_id, 
			error_code )
		SELECT journal_ctrl_num, 
			-1, 
			1003 
		FROM #gltrx
		WHERE mark_flag = 0
		AND trx_state = -1
		
		UPDATE #gltrx
		SET mark_flag = 0
		WHERE trx_state = -1

		IF ( @debug_level > 2 ) SELECT "tmp/gltrxval.sp" + ", line " + STR( 502, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Validate applications ID"
		
        IF ( @header_only_flag = 0 )
            BEGIN
            --
            -- The essential difference between imgltrxval_sp and gltrxval_sp is in the 
            -- detection of error 1013.  gltrxval_sp uses a HAVING clause as follows:
            --     ABS(SUM((SIGN(balance) * ROUND(ABS(balance) + 0.0000001, @prec)))) >= @rounding_factor
            -- whereas imgltrxval_sp uses a HAVING as shown in the following code.
            -- See "AEG - Irvine" SCR 1866 and "ERA - Irvine" SCR 31203. 
            --           
            INSERT #trxerror
                    (journal_ctrl_num, sequence_id, error_code)
                    SELECT d.journal_ctrl_num, -1, 1013
                            FROM #gltrxdet d, #gltrx h
                            WHERE h.trx_state = -1
                                    AND h.journal_ctrl_num = d.journal_ctrl_num
                            GROUP BY d.journal_ctrl_num 
                            HAVING ROUND(ABS(SUM(balance)), @prec) >= @rounding_factor
                                    OR ROUND(ABS(SUM(balance_oper)), @oper_prec) >= @oper_rounding_factor
            --
            END
		
		UPDATE #gltrx
		SET mark_flag = 1
		FROM gljtype a, #gltrx t
		WHERE a.journal_type = t.journal_type
		AND t.trx_state = -1

		INSERT #trxerror ( 
			journal_ctrl_num, 
			sequence_id, 
			error_code )
		SELECT journal_ctrl_num, 
			-1, 
			1014
		FROM #gltrx
		WHERE mark_flag = 0
		AND trx_state = -1

		UPDATE #gltrx
		SET mark_flag = 0
		WHERE trx_state = -1

		IF ( @debug_level > 2 ) SELECT "tmp/gltrxval.sp" + ", line " + STR( 565, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Validate journal type"
		
		INSERT #trxerror ( 
			journal_ctrl_num, 
			sequence_id, 
			error_code )
		SELECT journal_ctrl_num, 
			-1, 
			1022
		FROM #gltrx
		WHERE date_entered <= 0
		AND trx_state = -1

		IF ( @debug_level > 2 ) SELECT "tmp/gltrxval.sp" + ", line " + STR( 582, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Validate date entered"
		
		INSERT #trxerror ( 
			journal_ctrl_num, 
			sequence_id, 
			error_code )
		SELECT journal_ctrl_num, 
			-1, 
			1024
		FROM #gltrx
		WHERE recurring_flag NOT IN ( 0, 1 )
		AND trx_state = -1

		IF ( @debug_level > 2 ) SELECT "tmp/gltrxval.sp" + ", line " + STR( 599, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Validate recurring flag"
		
		INSERT #trxerror ( 
			journal_ctrl_num, 
			sequence_id, 
			error_code )
		SELECT journal_ctrl_num, 
			-1, 
			1025
		FROM #gltrx
		WHERE repeating_flag NOT IN ( 0, 1 )
		AND trx_state = -1

		IF ( @debug_level > 2 ) SELECT "tmp/gltrxval.sp" + ", line " + STR( 616, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Validate repeating flag"
		
		INSERT #trxerror ( 
			journal_ctrl_num, 
			sequence_id, 
			error_code )
		SELECT journal_ctrl_num, 
			-1, 
			1026
		FROM #gltrx
		WHERE reversing_flag NOT IN ( 0, 1 )
		AND trx_state = -1

		IF ( @debug_level > 2 ) SELECT "tmp/gltrxval.sp" + ", line " + STR( 633, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Validate reversing flag"
		
		INSERT #trxerror ( 
			journal_ctrl_num, 
			sequence_id, 
			error_code )
		SELECT journal_ctrl_num, 
			-1, 
			1027
		FROM #gltrx
		WHERE type_flag NOT BETWEEN 0 AND 6
		AND trx_state = -1

		IF ( @debug_level > 2 ) SELECT "tmp/gltrxval.sp" + ", line " + STR( 650, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Validate type flag"
		
		UPDATE #gltrx
		SET mark_flag = 1
		FROM #gltrx t, glcomp_vw c
		WHERE t.company_code = c.company_code
		AND trx_state = -1

		INSERT #trxerror ( 
			journal_ctrl_num, 
			sequence_id, 
			error_code )
		SELECT journal_ctrl_num, 
			-1, 
			1005
		FROM #gltrx
		WHERE mark_flag = 0
		AND trx_state = -1

		UPDATE #gltrx
		SET mark_flag = 0
		WHERE trx_state = -1

		IF ( @debug_level > 2 ) SELECT "tmp/gltrxval.sp" + ", line " + STR( 677, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Validate transaction company code"
		
		UPDATE #gltrx
		SET mark_flag = 1
		FROM #gltrx t, glcurr_vw c
		WHERE c.currency_code = t.home_cur_code
		AND trx_state = -1
		
		UPDATE #gltrx
		SET mark_flag = 1
		FROM #gltrx t, glcurr_vw c
		WHERE c.currency_code = t.oper_cur_code
		AND trx_state = -1

		INSERT #trxerror ( 
			journal_ctrl_num, 
			sequence_id, 
			error_code )
		SELECT journal_ctrl_num, 
			-1, 
			1050
		FROM #gltrx
		WHERE mark_flag = 0
		AND trx_state = -1

		UPDATE #gltrx
		SET mark_flag = 0
		WHERE trx_state = -1

		IF ( @debug_level > 2 ) SELECT "tmp/gltrxval.sp" + ", line " + STR( 710, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Validate transaction home currency"
		
		UPDATE #gltrx
		SET mark_flag = 1
		FROM #gltrx t, glusers_vw c
		WHERE t.user_id = c.user_id
		AND trx_state = -1

		INSERT #trxerror ( 
			journal_ctrl_num, 
			sequence_id, 
			error_code )
		SELECT journal_ctrl_num, 
			-1, 
			1028
		FROM #gltrx
		WHERE mark_flag = 0
		AND trx_state = -1

		UPDATE #gltrx
		SET mark_flag = 0
		WHERE trx_state = -1

		IF ( @debug_level > 2 ) SELECT "tmp/gltrxval.sp" + ", line " + STR( 737, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Validate transaction user ID"
		
		INSERT #trxerror ( 
			journal_ctrl_num, 
			sequence_id, 
			error_code )
		SELECT journal_ctrl_num, 
			-1, 
			1029
		FROM #gltrx
		WHERE hold_flag NOT IN ( 0, 1 )
		AND trx_state = -1

		IF ( @debug_level > 2 ) SELECT "tmp/gltrxval.sp" + ", line " + STR( 754, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Validate transaction hold flag"
		
		
		UPDATE #gltrx
		SET intercompany_flag = 1
		FROM #gltrx h, #gltrxdet d
		WHERE h.journal_ctrl_num = d.journal_ctrl_num
		AND h.company_code != d.rec_company_code
		
		EXEC @result = gltrxoff_sp @org_company,
						@debug_level

		IF ( @debug_level > 2 ) SELECT "tmp/gltrxval.sp" + ", line " + STR( 779, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Create offset records for I/C transactions"

		IF ( @result != 0 )
			return @result
	END
	
	EXEC @result = gltrxusl_sp @org_company,
					@rec_company

	IF ( @debug_level > 2 ) SELECT "tmp/gltrxval.sp" + ", line " + STR( 797, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Perform user supplied processing"
	
	IF ( @rec_company = @org_company )
	BEGIN
		
		UPDATE #gltrx
		SET trx_state = 3
		FROM #gltrx t, #trxerror e
		WHERE t.journal_ctrl_num = e.journal_ctrl_num
		AND trx_state = -1
		
		UPDATE #gltrx
		SET trx_state = 2
		WHERE trx_state = -1
		
		UPDATE #gltrxdet
		SET trx_state = 0
	 	WHERE trx_state = -1
	END
	
	ELSE
	BEGIN
		UPDATE #gltrxdet
		SET trx_state = 0
	 	WHERE trx_state = -1
	END		
	
    IF EXISTS (SELECT * FROM #trxerror)
            OR NOT @result = 0
        BEGIN
        IF @debug_level > 1
            BEGIN
            SELECT @Routine_Name + ': Exit.  ' + LTRIM(RTRIM(CAST(COUNT(*) AS VARCHAR))) + ' errors.'
            SELECT convert( char(20), 'journal_ctrl_num' )+
                   convert( char(15), 'sequence_id' )+
                   convert( char(15), 'Description' )
            SELECT convert( char(20), journal_ctrl_num )+
                   convert( char(15), sequence_id )+
                   e_ldesc
                    FROM #trxerror t, glerrdef e
                    WHERE    t.error_code = e.e_code
            END
            RETURN 1056
        END
    ELSE
        BEGIN
        IF @debug_level > 1
            BEGIN
            SELECT @Routine_Name + ': Exit.  No errors.'
            END
        RETURN 0
        END
    END
GO
GRANT EXECUTE ON  [dbo].[imgltrxval_sp] TO [public]
GO
