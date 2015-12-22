SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO





























  



					  

























































 




























































































































































































































































































































































































































































































































































































































































































































CREATE PROC [dbo].[ARCRProcPaymentDet_SP] 	@batch_ctrl_num 	varchar( 16 ),        
					@debug_level    	smallint = 0, 
					@perf_level        	smallint = 0
AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







DECLARE 
	@trx_ctrl_num    	varchar( 16 ),
	@doc_ctrl_num        varchar( 16 ),
	@apply_to_num        varchar( 16 ),
	@apply_trx_type 	smallint,
	@inv_amt_applied     float,
	@inv_amt_disc_taken 	float,
	@inv_amt_max_wr_off 	float,
	@payment_type   	smallint,
	@date_applied        int,
	@line_desc        	varchar( 40 ),
	@terms_code     	varchar( 8 ),
	@posting_code   	varchar( 8 ),
	@result         	int,
	@customer_code  	varchar(8),
	@trx_type        	smallint,
	@wr_off_flag       	smallint,
	@sequence_id      	int,
	@max_sequence_id   	int,
	@payer_cust_code	varchar(8),
	@prev_trx_ctrl_num	varchar( 16 ),
	@prev_doc_ctrl_num	varchar( 16 ),
	@prev_payer_cust_code varchar(8),
	@seq_offset		int,
	@num_rec		int,
	@cross_rate		float,
	@amt_applied		float,
	@amt_disc_taken	float,
	@nat_cur_code		varchar(8),
	@inv_cur_code		varchar(8),
	@gain_home		float,
	@gain_oper		float,
	@org_id			varchar(30),

/* Begin mod: CB0001 - Add working variables */
	@chargeback_type	varchar(8),
	@last_trx		varchar(16),
	@min_trx		varchar(16),
	@chargeamt 		float, 		
	@chargeref 		varchar(16),
	@customer 		varchar(8),
	@cb_reason_code 	varchar(8),	
	@cb_responsibility_code varchar(8),
	@store 			varchar(16)
/* End mod: CB0001 */ 

	
BEGIN
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arcrppd.cpp", 106, "Entering ARCRProcPaymentDet_SP", @PERF_time_last OUTPUT
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrppd.cpp" + ", line " + STR( 107, 5 ) + " -- ENTRY: "
	
	
CREATE TABLE #arcrinv
(
	doc_ctrl_num		varchar(16),
	trx_type		smallint,
	apply_to_num		varchar(16),
	apply_trx_type	smallint,
	date_aging		int,
	date_due		int,
	amt_due		float,  
	inv_amt_applied	float,
	inv_amt_disc_taken	float,  
	inv_amt_wr_off	float,
	gain_home		float,
	gain_oper		float,
	sequence_id		int		NULL
)



	
	



	SELECT pdt.payer_cust_code, pdt.doc_ctrl_num, 0 flag, MAX(pdt.sequence_id) max_sequence_id
	INTO	#pstd_max_seq_id
	FROM	#arinppyt_work pyt, artrxpdt pdt
	WHERE	pyt.batch_code = @batch_ctrl_num
	AND	pyt.customer_code = pdt.payer_cust_code
	AND	pyt.doc_ctrl_num = pdt.doc_ctrl_num
	GROUP BY pdt.payer_cust_code, pdt.doc_ctrl_num

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrppd.cpp" + ", line " + STR( 125, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	IF ( @debug_level > 2 ) 
	BEGIN
		SELECT	"dumping #pstd_max_seq_id..."
		SELECT "payer_cust_code = " + payer_cust_code +
			"doc_ctrl_num = " + doc_ctrl_num +
			"max_sequence_id = " + STR(max_sequence_id, 7)
		FROM	#pstd_max_seq_id
		
		SELECT "dumping #arinppyt_work.."
		SELECT "batch_code = " + batch_code +
			"trx_ctrl_num = " + trx_ctrl_num +
			"trx_type = " + STR(trx_type, 5)
		FROM	#arinppyt_work
		WHERE	batch_code = @batch_ctrl_num
		
		SELECT	"dumping #arinppdt_work.."
		SELECT	"trx_ctrl_num = " + trx_ctrl_num +
			"trx_type = " + STR(trx_type, 5) +
			"date_aging = " + STR(date_aging, 8) +
			"payer_cust_code = " + payer_cust_code +
			"doc_ctrl_num = " + doc_ctrl_num
		FROM	#arinppdt_work
	END
		
	








	INSERT  #artrxpdt_work 
		(
			doc_ctrl_num,              	trx_ctrl_num,        	sequence_id,    
			gl_trx_id,                	customer_code,          	trx_type,       
			apply_trx_type,            	apply_to_num,         	date_aging,     
			date_applied,           	amt_applied,            	amt_disc_taken, 
			amt_wr_off,            	void_flag,             	line_desc,      
			posted_flag,              	sub_apply_type,         	sub_apply_num,  
			amt_tot_chg,            	amt_paid_to_date,      	terms_code,     
			posting_code,              	payer_cust_code,		gain_home,
			gain_oper,			inv_amt_applied,		inv_amt_disc_taken,
			inv_amt_wr_off,		inv_cur_code, 			writeoff_code, 
			org_id,			db_action
		)
	SELECT  
			pdt.doc_ctrl_num,   		pdt.trx_ctrl_num,   		pdt.sequence_id+ISNULL(seq.max_sequence_id,0),        
			' ',           	   	pdt.customer_code,   	pdt.trx_type,   
			pdt.apply_trx_type,       	pdt.apply_to_num,    	pdt.date_aging, 
			pyt.date_applied,         	pdt.amt_applied,      	pdt.amt_disc_taken,     
			pdt.amt_max_wr_off,     	pdt.void_flag,          	pdt.line_desc,  
			1,                        	pdt.apply_trx_type,     	pdt.apply_to_num,       
			0.0,                     	0.0,                  	pdt.terms_code, 
			pdt.posting_code,      	pyt.customer_code,		pdt.gain_home,
			pdt.gain_oper,		pdt.inv_amt_applied,		pdt.inv_amt_disc_taken,
			pdt.inv_amt_max_wr_off,	pdt.inv_cur_code,		pdt.writeoff_code,
			pdt.org_id,	2		
	FROM   #arinppyt_work pyt 
	INNER JOIN #arinppdt_work pdt ON pyt.trx_ctrl_num = pdt.trx_ctrl_num and pyt.trx_type = pdt.trx_type
	LEFT OUTER JOIN #pstd_max_seq_id seq ON pdt.payer_cust_code = seq.payer_cust_code AND pdt.doc_ctrl_num = seq.doc_ctrl_num
	WHERE	pyt.batch_code = @batch_ctrl_num
	AND    pdt.date_aging > 0

	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrppd.cpp" + ", line " + STR( 200, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	



	SELECT pdt.payer_cust_code, pdt.doc_ctrl_num, pdt.trx_ctrl_num, COUNT(*) num_rec
	INTO	#multi_in_batch
	FROM	#arinppyt_work pyt, #artrxpdt_work pdt
	WHERE	pyt.batch_code = @batch_ctrl_num
	AND	pyt.customer_code = pdt.payer_cust_code
	AND	pyt.doc_ctrl_num = pdt.doc_ctrl_num
	GROUP BY pdt.payer_cust_code, pdt.doc_ctrl_num, pdt.trx_ctrl_num
	HAVING COUNT(*) > 1
	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrppd.cpp" + ", line " + STR( 219, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	SELECT @prev_trx_ctrl_num = '',
		@seq_offset = 0
	
	IF EXISTS (	SELECT payer_cust_code
			FROM	#multi_in_batch )
	BEGIN
		WHILE ( 0 = 0 )
		BEGIN
			SET ROWCOUNT 1
			
			SELECT @payer_cust_code = payer_cust_code,
				@doc_ctrl_num = doc_ctrl_num,
				@trx_ctrl_num = trx_ctrl_num,
				@num_rec = num_rec
			FROM	#multi_in_batch 
			WHERE	trx_ctrl_num > @prev_trx_ctrl_num
			ORDER BY payer_cust_code, doc_ctrl_num, trx_ctrl_num
			
			IF (@@rowcount = 0)
			BEGIN
				SET ROWCOUNT 0
				BREAK
			END
			
			SET ROWCOUNT 0
			
			




		 	IF ( (@payer_cust_code = @prev_payer_cust_code) AND (@doc_ctrl_num = @prev_doc_ctrl_num))
			BEGIN
				UPDATE	#arinppdt_work
				SET	sequence_id = sequence_id + @seq_offset
				WHERE	trx_ctrl_num = @trx_ctrl_num
				
				IF( @@error != 0 )
				BEGIN
					IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrppd.cpp" + ", line " + STR( 262, 5 ) + " -- EXIT: "
					RETURN 34563
				END
			END
			

	
			ELSE 			
				SELECT @seq_offset = 0
			
			SELECT	@prev_trx_ctrl_num = @trx_ctrl_num,
				@prev_payer_cust_code = @payer_cust_code,
				@prev_doc_ctrl_num = @doc_ctrl_num,
				@seq_offset = @seq_offset + @num_rec
			
		END
	END
	
	IF ( @debug_level > 2 ) 
	BEGIN
	     	SELECT "dumping #artrxpdt...for regular payments"
		SELECT "trx_ctrl_num = " + trx_ctrl_num +
			"customer_code = " + customer_code +
			"payer_cust_code = " + payer_cust_code +
			"doc_ctrl_num = " + doc_ctrl_num +
			"apply_to_num = " + apply_to_num
		FROM	#artrxpdt_work
	END
	IF ( @debug_level > 2 ) 
	BEGIN
	     	SELECT "dumping #artrxpdt...for regular payments"
		SELECT	"apply_to_num = " + apply_to_num +
			"sub_apply_num = " + sub_apply_num +
			"sequence_id = " + STR(sequence_id, 6 ) +
			"amt_applied = " + STR(amt_applied, 10, 2 ) +
			"amt_disc_taken = " + STR(amt_disc_taken, 10, 2 ) +
			"amt_wr_off = " + STR(amt_wr_off, 10, 2 ) 
		FROM	#artrxpdt_work
	END

	
	







	CREATE TABLE 	#max_seq
	(	payer_cust_code 	varchar(8),
		doc_ctrl_num		varchar(16),
		max_sequence_id	int
	)
	
	INSERT	#max_seq
	SELECT pdt.payer_cust_code, pdt.doc_ctrl_num, MAX(pdt.sequence_id)
	FROM   #artrxpdt_work pdt
	GROUP BY pdt.payer_cust_code, pdt.doc_ctrl_num
		
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrppd.cpp" + ", line " + STR( 324, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	UPDATE #pstd_max_seq_id
	SET	flag = 1
	FROM	#max_seq m
	WHERE	m.payer_cust_code = #pstd_max_seq_id.payer_cust_code
	AND	m.doc_ctrl_num = #pstd_max_seq_id.doc_ctrl_num		

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrppd.cpp" + ", line " + STR( 336, 5 ) + " -- EXIT: "
		RETURN 34563
	END
		
	INSERT	#max_seq
	SELECT pdt.payer_cust_code, pdt.doc_ctrl_num, max_sequence_id
	FROM   #pstd_max_seq_id pdt
	WHERE	pdt.flag = 0

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrppd.cpp" + ", line " + STR( 347, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	IF ( @debug_level >= 2 )
	BEGIN
		SELECT "dumping #max_seq...."
		SELECT "payer_cust_code = " + payer_cust_code +
			"doc_ctrl_num = " + doc_ctrl_num +
			"max_sequence_id = " + STR(max_sequence_id, 6 )
		FROM	#max_seq
	END
	
	IF ( @debug_level >= 2 )
	BEGIN
		SELECT "dumping #arinppdt_work...."
		SELECT "trx_ctrl_num = " + trx_ctrl_num +
			"customer_code = " + customer_code + 
			"sequence_id = " + STR(sequence_id, 6 ) +
			"temp_flag = " + STR(temp_flag, 2 ) +
			"amt_applied = " + STR(amt_applied, 10, 2) +
			"date_aging = " + STR(date_aging, 8 ) +
			"wr_off_flag = " + STR(wr_off_flag, 2 )
		FROM	#arinppdt_work
	END
		
	



	WHILE ( 1 = 1 )
	BEGIN
		


		SET ROWCOUNT 1
		
		



		SELECT @customer_code = pdt.customer_code,
			@trx_ctrl_num = pdt.trx_ctrl_num,
			@sequence_id = pdt.sequence_id,
			@doc_ctrl_num = pdt.doc_ctrl_num,
			@apply_to_num = pdt.apply_to_num,
			@apply_trx_type = pdt.apply_trx_type,
			@amt_applied = pdt.amt_applied,
			@amt_disc_taken = pdt.amt_disc_taken,
			@inv_amt_applied = pdt.inv_amt_applied,
			@inv_amt_disc_taken = pdt.inv_amt_disc_taken,
			@inv_amt_max_wr_off = pdt.inv_amt_max_wr_off,
			@wr_off_flag = pdt.wr_off_flag,
			@payment_type = pyt.payment_type,
			@date_applied = pyt.date_applied,
			@line_desc = pdt.line_desc,
			@terms_code = pdt.terms_code,
			@posting_code = pdt.posting_code,
			@max_sequence_id = ISNULL(#max_seq.max_sequence_id, 0),
			@payer_cust_code = pyt.customer_code,
			@gain_home = pdt.gain_home,
			@gain_oper = pdt.gain_oper,
			@inv_cur_code = pdt.inv_cur_code,
			@nat_cur_code = pyt.nat_cur_code,
			@org_id = pdt.org_id
		FROM   #arinppdt_work pdt
		INNER JOIN  #arinppyt_work pyt ON pdt.trx_ctrl_num = pyt.trx_ctrl_num	AND    pdt.trx_type = pyt.trx_type
		LEFT OUTER JOIN #max_seq ON pdt.payer_cust_code = #max_seq.payer_cust_code AND	pdt.doc_ctrl_num = #max_seq.doc_ctrl_num
		WHERE  pyt.batch_code = @batch_ctrl_num
		AND	pdt.date_aging = 0
		AND	pdt.wr_off_flag <= 1	   
		ORDER BY pdt.payer_cust_code, pdt.doc_ctrl_num, pdt.trx_ctrl_num, pdt.sequence_id
		
		


		IF (@@rowcount = 0)
		BEGIN
			SET ROWCOUNT 0
			BREAK
		END
		
		SET ROWCOUNT 0
					  
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrppd.cpp" + ", line " + STR( 432, 5 ) + " -- MSG: " + "Processing " + @apply_to_num
		IF (@debug_level > 2)
		BEGIN
			SELECT	"gain_home = " + str(@gain_home, 10, 2)
		END
		
		



		EXEC @result = ARCRProcSpecialInv_SP    	@batch_ctrl_num,
								@trx_ctrl_num,
								@max_sequence_id OUTPUT,
								@customer_code, 
								@apply_to_num,
								@apply_trx_type,
								@inv_amt_applied, 
								@inv_amt_disc_taken,
								@inv_amt_max_wr_off,
								@wr_off_flag,
								@gain_home,
								@gain_oper,
								@debug_level, 
								@perf_level
		
		IF (@result != 0)
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrppd.cpp" + ", line " + STR( 459, 5 ) + " -- EXIT: "
			RETURN @result
		END
		
		


		IF EXISTS (	SELECT payer_cust_code
				FROM	#max_seq
				WHERE	payer_cust_code = @payer_cust_code
				AND	doc_ctrl_num = @doc_ctrl_num  )
		BEGIN
			UPDATE #max_seq
			SET	max_sequence_id = @max_sequence_id
			WHERE	payer_cust_code = @payer_cust_code
			AND	doc_ctrl_num = @doc_ctrl_num
			AND	max_sequence_id != @max_sequence_id
			
			IF( @@error != 0 )
			BEGIN
				IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrppd.cpp" + ", line " + STR( 479, 5 ) + " -- EXIT: "
				RETURN 34563
			END
		END
		ELSE
		BEGIN
			INSERT #max_seq(payer_cust_code, doc_ctrl_num, max_sequence_id)
			VALUES(@payer_cust_code, @doc_ctrl_num, @max_sequence_id)
			
			IF( @@error != 0 )
			BEGIN
				IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrppd.cpp" + ", line " + STR( 490, 5 ) + " -- EXIT: "
				RETURN 34563
			END
		END
			
		
		


		IF ((ABS((@inv_amt_applied+@inv_amt_disc_taken)-(0.0)) > 0.0000001))
			SELECT @cross_rate = (@amt_applied+@amt_disc_taken)/
						(@inv_amt_applied+@inv_amt_disc_taken)
		
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrppd.cpp" + ", line " + STR( 505, 5 ) + " -- EXIT: "
			RETURN 34563
		END
		
		




		INSERT  #artrxpdt_work 
		(
			doc_ctrl_num,   	trx_ctrl_num,        sequence_id,    
			gl_trx_id,           customer_code,       trx_type,       
			apply_trx_type,      apply_to_num,        date_aging,     
			date_applied,        
			amt_applied,         
			amt_disc_taken, 
			amt_wr_off,          void_flag,           line_desc,      
			posted_flag,         sub_apply_type,      sub_apply_num,  
			amt_tot_chg,         amt_paid_to_date,    terms_code,     
			posting_code,        payer_cust_code,	gain_home,
			gain_oper,		inv_amt_applied,	inv_amt_disc_taken,
			inv_amt_wr_off,	inv_cur_code,		writeoff_code,
			org_id,		db_action		
		)
		SELECT  
			@doc_ctrl_num,    		@trx_ctrl_num,   			sequence_id,        
			' ',     	   		@customer_code,  			2111,      
			apply_trx_type,   		apply_to_num,   			date_aging, 
			@date_applied,    		
			round(inv_amt_applied*@cross_rate,a.curr_precision),	
			round(inv_amt_disc_taken*@cross_rate,a.curr_precision),     
			round(inv_amt_wr_off*@cross_rate, a.curr_precision), 0,                 			@line_desc,     
			0,             		trx_type,        			doc_ctrl_num,       
			0.0,            		0.0,           			@terms_code,    
			@posting_code,  		@payer_cust_code,			gain_home,
			gain_oper, 	   		round(inv_amt_applied,b.curr_precision),			round(inv_amt_disc_taken,b.curr_precision),
			round(inv_amt_wr_off,b.curr_precision),		@inv_cur_code,			" ",
			@org_id,	2   	
		FROM   #arcrinv, glcurr_vw a, glcurr_vw b
		WHERE 	@nat_cur_code = a.currency_code
		AND	@inv_cur_code = b.currency_code
		
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrppd.cpp" + ", line " + STR( 550, 5 ) + " -- EXIT: "
			RETURN 34563
		END   
		
		



		UPDATE	#arinppdt_work
		SET	wr_off_flag = 2
		WHERE	trx_ctrl_num = @trx_ctrl_num
		AND	sequence_id = @sequence_id         
		
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrppd.cpp" + ", line " + STR( 565, 5 ) + " -- EXIT: "
			RETURN 34563
		END 
	END
	
	DROP TABLE #arcrinv
	
	IF ( @debug_level >= 2 ) 
	BEGIN
	     	SELECT "dumping #artrxpdt......"
		SELECT "trx_ctrl_num = " + trx_ctrl_num +
			"trx_type = " + STR(trx_type, 6 ) +
			"customer_code = " + customer_code +
			"payer_cust_code = " + payer_cust_code +
			"doc_ctrl_num = " + doc_ctrl_num 
		FROM	#artrxpdt_work
	END
	IF ( @debug_level >= 2 ) 
	BEGIN
	     	SELECT "dumping #artrxpdt......"
		SELECT "apply_to_num = " + apply_to_num +
			"sequence_id = " + STR(sequence_id, 6 ) +
			"amt_applied = " + STR(amt_applied, 10, 2 ) +
			"amt_disc_taken = " + STR(amt_disc_taken, 10, 2 ) +
			"amt_wr_off = " + STR(amt_wr_off, 10, 2 ) +
			"gain_home = " + STR(gain_home, 10, 2 ) +
			"gain_oper = " + STR(gain_oper, 10, 2 ) 
		FROM	#artrxpdt_work
	END


	IF ( EXISTS(SELECT 1 from arco with (nolock) where chargeback_flag = 1 ))
	BEGIN
		/*Begin mod: CB0001 - Read the archgbk table and create chargebacks against the check */


			SELECT @last_trx = ""
			WHILE (1=1)
			BEGIN	
				SET ROWCOUNT 1
			
				/* Get the minimum control number not yet processed - The Emerald Group - Chargebacks */
				SELECT @min_trx=trx_ctrl_num
				FROM	#arinppyt_work
				WHERE 	trx_ctrl_num > @last_trx
				/* Begin fix: 06112003 */
				AND batch_code = @batch_ctrl_num
				/* End fix: 06112003 */
		
		
		
				IF (@@rowcount = 0)
				BEGIN
					SET ROWCOUNT 0
					BREAK
				END
		
				/* Get the data from the next control number to be processes - The Emerald Group - Chargebacks */
				SELECT 	@trx_ctrl_num=trx_ctrl_num, 
					@doc_ctrl_num=doc_ctrl_num, 
					@customer_code=customer_code
				FROM	#arinppyt_work
				WHERE	trx_ctrl_num=@min_trx
				
				
				
				/* Create any chargebacks for the control number - The Emerald Group - Chargebacks */			
				EXEC @result = ARProcessChargebacks_SP @trx_ctrl_num, @doc_ctrl_num, @customer_code, 
					@chargeback_type, @debug_level
				
				/* Set this control number to the last one processed - The Emerald Group - Chargebacks */
				SELECT @last_trx = @trx_ctrl_num
				
			END	

		/* End mod: CB0001 */
	END


	
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arcrppd.cpp", 596, "Leaving ARCRProcPaymentDet_SP", @PERF_time_last OUTPUT
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrppd.cpp" + ", line " + STR( 597, 5 ) + " -- EXIT: "      
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARCRProcPaymentDet_SP] TO [public]
GO
