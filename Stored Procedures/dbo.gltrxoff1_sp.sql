SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2008 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2008 Epicor Software Corporation, 2008    
                  All Rights Reserved                    
*/
CREATE PROCEDURE [dbo].[gltrxoff1_sp]	@company_code		varchar(8),
				@debug			smallint=0
AS
BEGIN
	DECLARE		@journal_ctrl_num	varchar(16),
			@sequence_id		int,
			@company_id		smallint,
			@SQL 			varchar(600),
			@rec_company_code	varchar(8),
			@db_name 		varchar(128)
			
	IF ( @debug > 3 )
		SELECT	'*** gltrxoff_sp - Creating offset records for company = '+@company_code
	



	IF EXISTS (	SELECT  *
			FROM	#gltrx
			WHERE	intercompany_flag = 1
			AND	trx_state = -1 )
	BEGIN
		IF ( @debug > 1 )
			SELECT	'*** gltrxoff_sp - Intercompany records found'
		
		GOTO INTERCOMPANY_EXISTS
	END

	ELSE
	BEGIN
		IF ( @debug > 1 )
		BEGIN
		     SELECT	'*** gltrxoff_sp - No intercompany records found'
		     SELECT	'*** gltrxoff_sp - No Creating offset records '

			
		     
		     IF EXISTS ( select count(*) from #gltrxdet )	
		     BEGIN
		        
		        SELECT 'gltrxoff_sp - Details From #GLTRXDET'
			SELECT 'header: Journal Ctrl , ic flag , source company code , process group num , batch code '  
			SELECT '      ' + convert( char(20), journal_ctrl_num )+ ' ' +
				convert( char(10), intercompany_flag ) + ' ' +
				convert( char(10), source_company_code ) + ' ' +
				convert( char(17) , process_group_num ) + ' ' +
				convert( char(17) , batch_code ) 
			FROM #gltrx

			SELECT  'Detail '
			SELECT  ' Journal Ctrl , rate oper ,  balance oper , ' + 
				'   balance  ,   rec company    ,   account code ,     org id '

			SELECT  convert( char(20), journal_ctrl_num )+ ' ' +
				convert( char(10), rate_oper )+ ' ' +
				convert( char(20), balance_oper ) + ' ' +
				convert( char(20), balance ) + ' ' +
				convert( char(10), rec_company_code )+ ' ' +
				convert( char(10), account_code )+ ' ' +
				convert( char(30), org_id  )
			FROM 	#gltrxdet
	
			
		     END 
		END	
			
		RETURN 0
	END
	
	INTERCOMPANY_EXISTS:
	
	SELECT	@company_id = company_id
	FROM	glcomp_vw
	WHERE	company_code = @company_code

	
	


	


	DELETE  #offset_accts		

	INSERT	#offset_accts (
		account_code,
		org_code,
		rec_code,
		sequence_id )
	SELECT	d.account_code,
		c.org_code,
		c.rec_code,
		MIN( c.sequence_id )
	FROM	#gltrx h, #gltrxdet d, glcocodt_vw c
	WHERE	h.trx_state = -1
	AND	h.journal_ctrl_num = d.journal_ctrl_num
	AND	c.org_code =  @company_code
	AND	d.rec_company_code = c.rec_code
	AND	d.account_code LIKE c.account_mask
	GROUP BY d.account_code, c.org_code, c.rec_code
	
	IF ( @debug > 3 )
		SELECT	'*** gltrxoff_sp - #offset_accts  table created'
		
	IF ( @debug > 4 )
	BEGIN
		SELECT	'*** gltrxoff_sp - Contents of #offset_accts'
		SELECT	convert( char(35), 'account_code ' )+
			convert( char(15), 'org_code ' )+
			convert( char(15), 'rec_code ' )+
			convert( char(10), 'sequence_id ' )
		SELECT	convert( char(35), account_code )+ ' '+
			convert( char(15), org_code )+ ' ' +
			convert( char(15), rec_code )+ ' ' +
			convert( char(10), sequence_id )
		FROM	#offset_accts
	END
			
	
	UPDATE	#gltrxdet		/*ggr*/
	SET	trx_state = -1


	UPDATE	#gltrxdet
	SET	mark_flag = 1
	WHERE	trx_state = -1
	AND	rec_company_code = @company_code
	




	UPDATE	#gltrxdet
	SET	mark_flag = 1
	FROM	#gltrx h, #gltrxdet d, #offset_accts a
	WHERE	h.trx_state = -1
	AND	h.journal_ctrl_num = d.journal_ctrl_num
	AND	d.account_code = a.account_code
	AND	d.rec_company_code = a.rec_code
	


	INSERT	#trxerror (	
		journal_ctrl_num, 
		sequence_id, 
		error_code )
	SELECT	d.journal_ctrl_num, 
		d.sequence_id, 
		1011
	FROM	#gltrx h, #gltrxdet d
	WHERE	h.trx_state = -1
	AND	h.journal_ctrl_num = d.journal_ctrl_num
	AND	d.mark_flag = 0

	UPDATE	#gltrx
	SET	mark_flag = 0
	WHERE	trx_state = -1
	


	IF ( @debug > 3 )
		SELECT	'*** gltrxoff_sp - recipient offset records temp table created'

	INSERT	#offsets (	
		journal_ctrl_num,
		sequence_id,
		company_code,
		company_id,
		org_ic_acct,
		org_seg1_code,
		org_seg2_code,
		org_seg3_code,
		org_seg4_code,
		org_org_id,
		rec_ic_acct,
		rec_seg1_code,
		rec_seg2_code,
		rec_seg3_code,
		rec_seg4_code,
		rec_org_id )
	SELECT	d.journal_ctrl_num,
		d.sequence_id,
		d.rec_company_code,
		d.company_id,
		c.org_ic_acct,
		c.org_seg1_code,
		c.org_seg2_code,
		c.org_seg3_code,
		c.org_seg4_code,
		h.org_id,
		c.rec_ic_acct,
		c.rec_seg1_code,
		c.rec_seg2_code,
		c.rec_seg3_code,
		c.rec_seg4_code,
		d.org_id
	FROM	#gltrx h, glcocodt_vw c, #gltrxdet d, #offset_accts t
	WHERE	h.trx_state = -1
	AND	h.journal_ctrl_num = d.journal_ctrl_num
	AND	t.rec_code = c.rec_code
	AND	t.org_code =  c.org_code
	AND	t.sequence_id = c.sequence_id
	AND	t.rec_code = d.rec_company_code
	AND	t.account_code = d.account_code
	ORDER BY
		d.journal_ctrl_num, d.sequence_id

	IF ( @debug > 4 )
	BEGIN
		SELECT	'*** gltrxoff_sp - recipient offset records temp table created'
		SELECT	convert( char(17), 'journal_ctrl_num') +
		        convert( char(5),  'seq ' )  +
		        convert( char(15), 'company_code ' ) +
			convert( char(35), 'org_ic_acct ' ) +
			convert( char(30), 'org_org_id ' ) +
			convert( char(35 ),'rec_ic_acct ') +
			convert( char(35 ),'rec_org_id')
			
		SELECT	convert( char(17), journal_ctrl_num )+ ' '+
		        convert( char(5), sequence_id ) + ' ' +
		        convert( char(10), company_code )+ ' '+
		        convert( char(35), org_ic_acct )+ ' '+
			convert( char(30), org_org_id )+ ' ' +
			convert( char(35), rec_ic_acct )+ ' ' +
			convert( char(35), rec_org_id )
		FROM	#offsets
			
	END
	
	
	UPDATE #offsets
	SET org_ic_acct = dbo.IBAcctMask_fn (  org_ic_acct , org_org_id )

	UPDATE #offsets 
	SET org_seg1_code = g.seg1_code, 
	    org_seg2_code = g.seg2_code, 
	    org_seg3_code = g.seg3_code, 
	    org_seg4_code = g.seg4_code
	FROM #offsets o, glchart g 
	WHERE o.org_ic_acct = g.account_code  

	

	
	SELECT @rec_company_code =''	
	WHILE (1=1)
		BEGIN

			SET ROWCOUNT 1
				 SELECT DISTINCT @db_name = g.db_name,
				       @rec_company_code = g.company_code
				 FROM #offsets o
					INNER JOIN glcomp_vw g
					ON o.company_code = g.company_code
				 WHERE o.company_code > @rec_company_code 
				 ORDER BY  g.company_code				


			IF @@ROWCOUNT = 0 BEGIN 
				-- @@ROWCOUNT = 0 
                                SET ROWCOUNT 0 
				BREAK
			END

			SET ROWCOUNT 0

			SELECT  @SQL  = ' UPDATE #offsets ' 
			SELECT  @SQL  = @SQL + 	' SET rec_ic_acct = '+@db_name+'.dbo.IBAcctMask_fn (  rec_ic_acct , rec_org_id ) '
			SELECT  @SQL  = @SQL + 	' WHERE company_code = ''' + @rec_company_code + ''''


			EXEC 	(@SQL)

			SELECT @SQL  = ' UPDATE #offsets '
			SELECT  @SQL  = @SQL + 	' SET rec_seg1_code = g.seg1_code, ' 
			SELECT  @SQL  = @SQL + 	'     rec_seg2_code = g.seg2_code, ' 
			SELECT  @SQL  = @SQL + 	'     rec_seg3_code = g.seg3_code, ' 
			SELECT  @SQL  = @SQL + 	'     rec_seg4_code = g.seg4_code ' 
			SELECT  @SQL  = @SQL + 	'  FROM #offsets o, ' + @db_name  +'..glchart g ' 
			SELECT  @SQL  = @SQL +  '  WHERE o.rec_ic_acct = g.account_code AND o.company_code = ''' + @rec_company_code + ''''
			
			EXEC 	(@SQL)
		
		END
	


	IF ( @debug > 4 )
	BEGIN
		SELECT	'*** gltrxoff_sp - Contents of #offsets Updated'
		SELECT	convert( char(17), 'journal_ctrl_num') +
		        convert( char(5),  'seq ' )  +
		        convert( char(10), 'company_code ' ) +
			convert( char(35), 'org_ic_acct ' ) +
			convert( char(30), 'org_org_id ' ) +
			convert( char(35 ),'rec_ic_acct ') +
			convert( char(35 ),'rec_org_id')
			
		SELECT	convert( char(17), journal_ctrl_num )+ ' '+
		        convert( char(5), sequence_id ) + ' ' +
		        convert( char(10), company_code )+ ' '+
		        convert( char(35), org_ic_acct )+ ' '+
			convert( char(30), org_org_id )+ ' ' +
			convert( char(35), rec_ic_acct )+ ' ' +
			convert( char(35), rec_org_id )
		FROM	#offsets
	END
	
	



	WHILE 1=1
	BEGIN
		SELECT	@journal_ctrl_num = MIN( journal_ctrl_num )
		FROM	#offsets
		
		SELECT	@sequence_id = NULL
		
		SELECT	@sequence_id = MIN( sequence_id )
		FROM	#offsets
		WHERE	journal_ctrl_num = @journal_ctrl_num
		
		IF ( @sequence_id IS NULL )
			break
		



		INSERT	#gltrxdet (
			trx_state,
			mark_flag,
			journal_ctrl_num,	
			sequence_id,	
			rec_company_code,
			company_id,		
			account_code,	
			description,
			document_1,		
			document_2,	
			reference_code,
			balance,		
			nat_balance,	
			nat_cur_code,
			rate,			
			posted_flag,	
			date_posted,
			trx_type,		
			offset_flag,
			seg1_code,
			seg2_code,
			seg3_code,
			seg4_code,
			seq_ref_id ,
			balance_oper,
			rate_oper,
		        rate_type_home,
			rate_type_oper,
			org_id )
		SELECT	-1,
			0,
			d.journal_ctrl_num,	
			h.next_seq_id,	
			@company_code,
			@company_id,		
			t.org_ic_acct,	
			d.description, 
			d.document_1,
			d.document_2,
			'',
			d.balance,		
			d.nat_balance,	
			d.nat_cur_code,
			d.rate,			
			0, 
			0,
			d.trx_type, 
			1,
			t.org_seg1_code,
			t.org_seg2_code,
			t.org_seg3_code,
			t.org_seg4_code,
			t.sequence_id,
			d.balance_oper,
			d.rate_oper,
		        d.rate_type_home,
			d.rate_type_oper,
			h.org_id
		FROM	#gltrx h, #offsets t, #gltrxdet d
		WHERE	h.journal_ctrl_num = d.journal_ctrl_num
		AND	d.journal_ctrl_num = t.journal_ctrl_num
		AND	d.sequence_id = t.sequence_id
		AND	d.journal_ctrl_num = @journal_ctrl_num
		AND	d.sequence_id = @sequence_id
		
		IF ( @@error != 0 )
			RETURN	1039

		
		INSERT	#gltrxdet (
			trx_state,
			mark_flag,
			journal_ctrl_num,	
			sequence_id,	
			rec_company_code,
			company_id,		
			account_code,	
			description,
			document_1,		
			document_2,	
			reference_code,
			balance,		
			nat_balance,	
			nat_cur_code,
			rate,			
			posted_flag,	
			date_posted,
			trx_type,		
			offset_flag,
			seg1_code,
			seg2_code,
			seg3_code,
			seg4_code,
			seq_ref_id ,
			balance_oper,
			rate_oper,
		        rate_type_home,
			rate_type_oper,
			org_id )
		SELECT	-1,
			0,
			d.journal_ctrl_num,	
			h.next_seq_id+1,	
			t.company_code,
			t.company_id,		
			t.rec_ic_acct,	
			d.description, 
			d.document_1,
			d.document_2,
			'',
			-(d.balance),		
			-(d.nat_balance),	
			d.nat_cur_code,
			d.rate,			
			0, 
			0,
			d.trx_type, 
			1,
			t.rec_seg1_code,
			t.rec_seg2_code,
			t.rec_seg3_code,
			t.rec_seg4_code,
			t.sequence_id,
			-(d.balance_oper),
			d.rate_oper,
		        d.rate_type_home,
			d.rate_type_oper,
			d.org_id
		FROM	#gltrx h, #offsets t, #gltrxdet d
		WHERE	h.journal_ctrl_num = d.journal_ctrl_num
		AND	d.journal_ctrl_num = t.journal_ctrl_num
		AND	d.sequence_id = t.sequence_id
		AND	d.journal_ctrl_num = @journal_ctrl_num
		AND	d.sequence_id = @sequence_id

		IF ( @@error != 0 )
			RETURN	1039

		UPDATE	#gltrx
		SET	next_seq_id = next_seq_id + 2
		FROM	#gltrx
		WHERE	journal_ctrl_num = @journal_ctrl_num
		
		IF ( @debug > 4 )
		BEGIN
			SELECT	'*** gltrxoff_sp - Created offsets for journal_ctrl_num = '+
				@journal_ctrl_num + ' sequence_id = '+ convert(char(10), @sequence_id)
		END
		
		DELETE	#offsets
		FROM	#offsets
		WHERE	journal_ctrl_num = @journal_ctrl_num
		AND	sequence_id = @sequence_id
	END

	IF ( @debug > 1 )
	BEGIN 
			SELECT 'gltrxoff_sp - Details From #GLTRXDET'
			
			SELECT 'header: Journal Ctrl , ic flag , source company code , process group num , batch code '  
			SELECT '      ' + convert( char(20), journal_ctrl_num )+ ' ' +
				convert( char(10), intercompany_flag ) + ' ' +
				convert( char(10), source_company_code ) + ' ' +
				convert( char(17) , process_group_num ) + ' ' +
				convert( char(17) , batch_code ) 
			FROM #gltrx

			SELECT  'Detail '
			SELECT  ' Journal Ctrl , rate oper ,  balance oper , ' + 
				'   balance  ,   rec company    ,   account code ,     org id '

			SELECT  convert( char(20), journal_ctrl_num )+ ' ' +
				convert( char(10), rate_oper )+ ' ' +
				convert( char(20), balance_oper ) + ' ' +
				convert( char(20), balance ) + ' ' +
				convert( char(10), rec_company_code )+ ' ' +
				convert( char(10), account_code )+ ' ' +
				convert( char(30), org_id  )
			FROM 	#gltrxdet
	END


	RETURN  0
END
GO
GRANT EXECUTE ON  [dbo].[gltrxoff1_sp] TO [public]
GO
