SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE  PROCEDURE	[dbo].[glpsprep_sp] 
			@batch_code		varchar(16), 
			@debug_level			smallint = 0
	WITH RECOMPILE

AS

BEGIN

	DECLARE @error			int,
		@work_time		datetime,
		@post_ctrl_num		varchar(16),
		@post_user_id		smallint,
		@post_date		int,
		@period_end		int,
		@batch_type		smallint,
		@no_trans		int,
		@no_details		int,
		@result			int,
		@rounding_factor	float,
        @prec                   smallint,
        @rounding_factor_oper   float,
        @prec_oper              float,
		@company_code		varchar(8)		

	



	IF ( @@trancount > 0 )
	BEGIN
		return 1052
	END


	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'glpsprep.cpp' + ', line ' + STR( 163, 5 ) + ' -- ENTRY: '
	SELECT	@work_time = getdate()
	


	EXEC	@result = batinfo_sp	@batch_code,
					@post_ctrl_num	OUTPUT,
					@post_user_id	OUTPUT,
					@post_date	OUTPUT,
					@period_end	OUTPUT,
					@batch_type	OUTPUT
	IF ( @result != 0 )
		return	1021
	


	SELECT	@rounding_factor = rounding_factor,
		@prec = curr_precision
	FROM	glcurr_vw c, glco h
	WHERE	c.currency_code = h.home_currency
        IF ( @rounding_factor IS NULL OR @prec IS NULL )
	BEGIN
	 	RETURN 1050
        END
        


        SELECT  @rounding_factor_oper = rounding_factor,
                @prec_oper = curr_precision
	FROM	glcurr_vw c, glco h
        WHERE   c.currency_code = h.oper_currency

        IF ( @rounding_factor_oper IS NULL OR @prec_oper IS NULL )
	BEGIN
                
                RETURN 1050
	END


	SELECT @company_code = company_code FROM glco


	


	INSERT	#gldtrx (
		journal_ctrl_num,
		date_applied,
		repeating_flag,
		reversing_flag,
		recurring_flag,
		mark_flag,
		interbranch_flag)
	SELECT  journal_ctrl_num, 
		date_applied,
		repeating_flag,
		reversing_flag,
		recurring_flag,
		0,
		interbranch_flag
	FROM    gltrx
	WHERE   batch_code = @batch_code

	SELECT	@no_trans = @@rowcount, @error = @@error

	IF ( @error != 0 )
		return 1039

	INSERT	#gldtrdet (
		journal_ctrl_num,
		sequence_id,
		account_code,
		balance, 
		nat_balance,
		nat_cur_code,
		rec_company_code,
                mark_flag,
                balance_oper,
		org_id)
	SELECT 	d.journal_ctrl_num, 
		d.sequence_id,
	       	d.account_code,	   
	       	ROUND( d.balance, @prec ),
	       	ROUND( d.nat_balance, curr_precision ),
	       	d.nat_cur_code,	   
		d.rec_company_code,
                0,                  
                ROUND( d.balance_oper, @prec_oper ),
		d.org_id
	FROM	#gldtrx h, gltrxdet d, glcurr_vw c
	WHERE	h.journal_ctrl_num = d.journal_ctrl_num
	AND	d.nat_cur_code = c.currency_code

	SELECT	@no_details = @@rowcount, @error = @@error

	IF ( @error != 0 )
		return 1039
	



	IF ( @no_trans = 0 OR @no_details = 0 )
	BEGIN
		IF ( @debug_level > 0 )
		BEGIN
			SELECT	'Error: no transactions or details to post'
			SELECT	'# trx = ' + CONVERT( char(10), @no_trans) + 
				' # details = ' + CONVERT( char(10), @no_details )
		END
		RETURN 1001
	END

	IF ( @debug_level > 2 )
	BEGIN
		SELECT	'# trx = ' + CONVERT( char(10), @no_trans) + 
			' # details = ' + CONVERT( char(10), @no_details )
	END

	IF ( @debug_level > 2 ) SELECT 'glpsprep.cpp' + ', line ' + STR( 281, 5 ) + ' -- MSG: ' + CONVERT(char,@work_time,100) + 'Inserting transactions into distribution tables'

	IF ( @debug_level > 3 )
	BEGIN
		SELECT	'Batch Information for this posting run'
		SELECT	'Posting Control Number: ' + CONVERT( char(20), @post_ctrl_num )
		SELECT	'Posting user id       : ' + CONVERT( char(5), @post_user_id )
	 	SELECT	'Posting date          : ' + CONVERT( char(10), @post_date )
		SELECT	'Period end date       : ' + CONVERT( char(10), @period_end )
		SELECT	'Batch type            : ' + CONVERT( char(5), @batch_type )
	END


	









	SELECT	d.account_code,
		MIN( s.sequence_id ) sequence_id, 
		d.org_id
	INTO	#glincsum
	FROM	#gldtrdet d, glincsum s, glchart c
	WHERE	d.account_code = c.account_code
	AND	d.account_code LIKE s.account_pattern
	AND	c.account_type >= 400
	AND	c.account_type < 600
	AND 	d.rec_company_code = @company_code  
	GROUP BY
		d.account_code, d.org_id
	




	INSERT 	#summary (
	       	summary_code,
	       	summary_type,
	       	account_code )
	SELECT 	dbo.IBAcctMask_fn(s.is_acct_code, t.org_id), 
	       	0,
	       	t.account_code
	FROM   	#glincsum t, glincsum s
	WHERE  	t.sequence_id = s.sequence_id

	IF ( @@error != 0 )
		return 1039

	IF ( @debug_level > 2 ) SELECT 'glpsprep.cpp' + ', line ' + STR( 334, 5 ) + ' -- MSG: ' + CONVERT(char,@work_time,100) + 'Getting income summary account codes'
	



	INSERT 	#summary (
	       	summary_code,
	       	summary_type,
	       	account_code )
	SELECT 	dbo.IBAcctMask_fn(s.re_acct_code, t.org_id), 
	       	1,
	       	t.account_code
	FROM   	#glincsum t, glincsum s
	WHERE  	t.sequence_id = s.sequence_id

	IF ( @@error != 0 )
		return 1039
	


	DROP TABLE	#glincsum
	



	INSERT		#sumhdr (
			summary_code,
			summary_type,
			bal_fwd_flag,
			balance_type,
			seg1_code,
			seg2_code,
			seg3_code,
			seg4_code,
			account_type  )
	SELECT DISTINCT	t.summary_code,
			t.summary_type,
			t.summary_type, 
			1, 	
			c.seg1_code,
			ISNULL( c.seg2_code, ' ' ),
			ISNULL( c.seg3_code, ' ' ),
			ISNULL( c.seg4_code, ' ' ),
			c.account_type
	FROM		#summary t, glchart c
	WHERE		t.summary_code = c.account_code

	IF ( @@error != 0 )
		return 1039

	IF ( @debug_level > 2 ) SELECT 'glpsprep.cpp' + ', line ' + STR( 384, 5 ) + ' -- MSG: ' + CONVERT(char,@work_time,100) + 'Getting retained earnings account codes'
	









	INSERT	#summary (
		summary_code,
		summary_type,
		account_code )
	SELECT 	DISTINCT
		s.summary_code, 
	       	2,
	       	d.account_code
	FROM   	#gldtrdet d, glsumdet s
	WHERE  	d.account_code LIKE s.account_pattern
	ORDER BY
		d.account_code

	IF ( @@error != 0 )
		return 1039

	INSERT		#sumhdr (
			summary_code,
			summary_type,
			bal_fwd_flag,
			balance_type,
			seg1_code,
			seg2_code,
			seg3_code,
			seg4_code,
			account_type )
	SELECT DISTINCT	t.summary_code, 
			t.summary_type,
			c.bal_fwd_flag,
			2,		
			c.seg1_code,
			ISNULL( c.seg2_code, ' ' ),
			ISNULL( c.seg3_code, ' ' ),
			ISNULL( c.seg4_code, ' ' ),
			0                
	FROM		#summary t, glsummnt c
	WHERE		t.summary_code = c.summary_code
	AND		t.summary_type = 2

	IF ( @@error != 0 )
		return 1039

	IF ( @debug_level > 2 ) SELECT 'glpsprep.cpp' + ', line ' + STR( 437, 5 ) + ' -- MSG: ' + CONVERT(char,@work_time,100) + 'Getting rollup codes'

	IF ( @debug_level > 3 )
	BEGIN
		SELECT	'Contents of #summary table'
		SELECT	convert( char(35), 'Summary code' )+
			convert( char(10), 'Sum. type' ) +
			convert( char(35), 'Account Code' )
		SELECT	convert( char(35), summary_code ) +
			convert( char(10), summary_type ) +
			convert( char(35), account_code )
		FROM	#summary
	END

	IF ( @debug_level > 1 )
	BEGIN
		SELECT	'-----------------------  Leaving GLPSPREP_SP -------------------------'
	END

	RETURN 0
	
END

GO
GRANT EXECUTE ON  [dbo].[glpsprep_sp] TO [public]
GO
