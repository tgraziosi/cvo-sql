SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


























  



					  

























































 




















































































































































































































































































































CREATE PROCEDURE [dbo].[arinppyt_sp]	@batch_ctrl_num	varchar( 16 ),
					@debug_level		smallint = 0,
					@perf_level		smallint = 0
WITH RECOMPILE
AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







DECLARE
	@status 	int
	declare @settlement_ctrl_num varchar(16)
	declare @process_group_num varchar(16)
	declare @date_posted int
	declare @count int
	declare @trx_ctrl_num varchar(16)
	declare @num	int
	declare @last_trx_ctrl_num varchar(16)
	declare @l_settlement_ctrl_num varchar(16)

BEGIN
	SELECT 	@status = 0

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arinppyt.cpp' + ', line ' + STR( 59, 5 ) + ' -- ENTRY: '
	
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'arinppyt.cpp', 61, 'entry arinppyt_sp', @PERF_time_last OUTPUT

	
CREATE TABLE ##batch_code_temp
(
	trx_ctrl_num varchar(16),
	batch_code   varchar(16)
)

	insert into ##batch_code_temp
	select a.trx_ctrl_num, a.batch_code
	FROM arinppyt a (NOLOCK)
		INNER JOIN #arinppyt_work b ON a.trx_ctrl_num = b.trx_ctrl_num

	DELETE	arinppyt
	FROM	#arinppyt_work a, arinppyt b
	WHERE	a.trx_ctrl_num = b.trx_ctrl_num 
	AND	a.trx_type = b.trx_type 
	AND	db_action > 0
	
	SELECT	@status = @@error	

	IF (@debug_level > 0)
	BEGIN
		SELECT 'nat_cur_code = '+nat_cur_code
		FROM	#arinppyt_work
	END
	
	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, 'arinppyt.cpp', 86, 'delete arinppyt: delete action', @PERF_time_last OUTPUT

	IF ( @status = 0 )
	BEGIN
		INSERT	arinppyt 
		( 
			trx_ctrl_num,		doc_ctrl_num,		trx_desc,
		   	batch_code,		trx_type,		non_ar_flag,
			non_ar_doc_num,	gl_acct_code,		date_entered,
		   	date_applied,		date_doc,		customer_code,
		   	payment_code,		payment_type,		amt_payment,
			amt_on_acct,		prompt1_inp,		prompt2_inp,
			prompt3_inp,		prompt4_inp,		deposit_num,
			bal_fwd_flag,		printed_flag,		posted_flag,
			hold_flag,		wr_off_flag,		on_acct_flag,
		   	user_id,		max_wr_off,		days_past_due,
			void_type,		cash_acct_code,	origin_module_flag,
		   	process_group_num,	source_trx_ctrl_num,	source_trx_type,
			nat_cur_code,		rate_type_home,	rate_home,
			rate_type_oper,	rate_oper,		amt_discount,
			reference_code,	settlement_ctrl_num, org_id
			
		)
		SELECT	trx_ctrl_num,		doc_ctrl_num,		trx_desc,
		   	batch_code,		trx_type,		non_ar_flag,
		   	non_ar_doc_num,	gl_acct_code,		date_entered,
			date_applied,		date_doc,		customer_code,
			payment_code,		payment_type,		amt_payment,
		   	amt_on_acct,		prompt1_inp,		prompt2_inp,
		   	prompt3_inp,		prompt4_inp,		deposit_num,
			bal_fwd_flag,		printed_flag,		posted_flag,
		   	hold_flag,		wr_off_flag,		on_acct_flag,
		   	user_id,		max_wr_off,		days_past_due,
	 	   	void_type,		cash_acct_code,	origin_module_flag,
		   	process_group_num,	source_trx_ctrl_num,	source_trx_type,
			nat_cur_code,		rate_type_home,	rate_home,
			rate_type_oper,	rate_oper,		amt_discount,
			reference_code,	settlement_ctrl_num, org_id
		FROM	#arinppyt_work
		WHERE	db_action > 0
		AND 	db_action < 4




		update arinppyt
		set arinppyt.batch_code = ##batch_code_temp.batch_code
		from ##batch_code_temp 
		where arinppyt.trx_ctrl_num = ##batch_code_temp.trx_ctrl_num

		DROP TABLE ##batch_code_temp




		SELECT	@last_trx_ctrl_num = '',
		@trx_ctrl_num = NULL


		/*DECLARE arinppyt_cursor CURSOR FOR
			SELECT trx_ctrl_num FROM #arinppyt_work 
			WHERE settlement_ctrl_num IS NULL
			AND trx_type = 2111
			AND non_ar_flag = 0

		OPEN arinppyt_cursor

		FETCH NEXT FROM arinppyt_cursor into @trx_ctrl_num
		WHILE @@FETCH_STATUS = 0*/
		WHILE (1 = 1)
		BEGIN
			  
			  SELECT @trx_ctrl_num = MIN(trx_ctrl_num) FROM #arinppyt_work 
			  WHERE settlement_ctrl_num IS NULL
			  AND trx_type = 2111
			  AND non_ar_flag = 0
			  AND trx_ctrl_num > @last_trx_ctrl_num

			       
			IF( @trx_ctrl_num IS NULL )
				BREAK 


			  EXEC ARGetNextControl_SP  2015,
                	            @settlement_ctrl_num OUTPUT,
                        	    @num OUTPUT

			UPDATE arinppyt
				SET settlement_ctrl_num = @settlement_ctrl_num
			WHERE trx_ctrl_num = @trx_ctrl_num			

			UPDATE #arinppyt_work
				SET settlement_ctrl_num = @settlement_ctrl_num
			WHERE trx_ctrl_num = @trx_ctrl_num

			exec ARCRAddStlTmp_SP	  @settlement_ctrl_num 
		
			SELECT	@last_trx_ctrl_num = @trx_ctrl_num
			SELECT	@trx_ctrl_num = NULL

			/*FETCH NEXT FROM arinppyt_cursor into @trx_ctrl_num*/
		END

		/*CLOSE arinppyt_cursor
		DEALLOCATE arinppyt_cursor*/
	
		create table #tmp 
		( 
		settlement_ctrl_num varchar(16)
		)

		select @date_posted = DATEDIFF(DD, '1/1/80',CONVERT(DATETIME,GETDATE()))+722815
		select @process_group_num =  (select distinct process_group_num 
						from #arinppyt_work where hold_flag = 0)
		
		DECLARE @hold_counter Int 
	
		IF ( ( select batch_proc_flag from arco) = 0)

		BEGIN
			/*DECLARE settle_cursor CURSOR FOR
			SELECT settlement_ctrl_num FROM #arinppyt_work WHERE hold_flag = 0 

			OPEN settle_cursor
			FETCH NEXT FROM settle_cursor into @settlement_ctrl_num
			WHILE @@FETCH_STATUS = 0
			BEGIN
				select @count = (select count(*) from #tmp where settlement_ctrl_num = @settlement_ctrl_num)
				if @count = 0 insert into #tmp select @settlement_ctrl_num
				FETCH NEXT FROM settle_cursor into @settlement_ctrl_num
			END
  
			CLOSE settle_cursor
			DEALLOCATE settle_cursor*/

			insert into #tmp SELECT DISTINCT settlement_ctrl_num FROM #arinppyt_work WHERE hold_flag = 0  

		END
		ELSE
		BEGIN

			SELECT  @hold_counter = count(hold_flag) 
			FROM 	#arinppyt_work 
			WHERE 	hold_flag = 1 
			AND 	batch_code =  @batch_ctrl_num

			IF 	@hold_counter = 0
			BEGIN
				/*DECLARE settle_cursor CURSOR FOR
				SELECT settlement_ctrl_num FROM #arinppyt_work 		
				OPEN settle_cursor
				FETCH NEXT FROM settle_cursor into @settlement_ctrl_num
				WHILE @@FETCH_STATUS = 0
				BEGIN
					select @count = (select count(*) from #tmp where settlement_ctrl_num = @settlement_ctrl_num)
					if @count = 0 insert into #tmp select @settlement_ctrl_num
					FETCH NEXT FROM settle_cursor into @settlement_ctrl_num
				END
  	
				CLOSE settle_cursor
				DEALLOCATE settle_cursor*/

				insert into #tmp SELECT DISTINCT settlement_ctrl_num FROM #arinppyt_work WHERE hold_flag = 0  
			END 
			
		END

		

		

		
 

		



		delete artrxstldtl where settlement_ctrl_num in (select settlement_ctrl_num from #arinppyt_work)
	
		insert artrxstldtl (settlement_ctrl_num,trx_ctrl_num,trx_type) 
		select settlement_ctrl_num,trx_ctrl_num,trx_type 
		from #arinppyt_work 
		where trx_type = 2111 
		and non_ar_flag = 0
		




		/*DECLARE settle_cursor CURSOR FOR
		SELECT settlement_ctrl_num FROM #tmp
		OPEN settle_cursor
		FETCH NEXT FROM settle_cursor into @settlement_ctrl_num
		WHILE @@FETCH_STATUS = 0
		BEGIN

			delete artrxstlhdr where settlement_ctrl_num = @settlement_ctrl_num
			
			insert into  artrxstlhdr
			(
			settlement_ctrl_num ,description ,date_entered ,date_applied,date_posted ,
			user_id,process_group_num ,doc_count_expected,doc_count_entered		
			,doc_sum_expected,doc_sum_entered,oa_cr_total_home,oa_cr_total_oper,
			cr_total_home ,cr_total_oper ,cm_total_home ,cm_total_oper		
			,inv_total_home	,inv_total_oper ,disc_total_home ,disc_total_oper,
			wroff_total_home ,wroff_total_oper ,onacct_total_home,onacct_total_oper	
			,gain_total_home,gain_total_oper,loss_total_home ,loss_total_oper ,
		 	customer_code, nat_cur_code, batch_code, rate_type_home, rate_home, rate_type_oper,
			rate_oper, inv_amt_nat, amt_doc_nat, amt_dist_nat, amt_on_acct, settle_flag,	org_id 
			)
			select 	settlement_ctrl_num ,description ,date_entered ,date_applied ,@date_posted ,
			user_id , @process_group_num,doc_count_expected ,doc_count_entered		
			,doc_sum_expected ,doc_sum_entered , oa_cr_total_home ,oa_cr_total_oper 
			,cr_total_home ,cr_total_oper ,cm_total_home ,cm_total_oper 
			,inv_total_home ,inv_total_oper ,disc_total_home,disc_total_oper 
			,wroff_total_home ,wroff_total_oper ,onacct_total_home ,onacct_total_oper 
			,gain_total_home,gain_total_oper,loss_total_home ,loss_total_oper ,
		 	customer_code, nat_cur_code, batch_code, rate_type_home, rate_home, rate_type_oper,
			rate_oper, inv_amt_nat, amt_doc_nat, amt_dist_nat, amt_on_acct, settle_flag,	org_id 
			from arinpstlhdr 
			where settlement_ctrl_num = @settlement_ctrl_num
		
			delete arinpstlhdr where settlement_ctrl_num = @settlement_ctrl_num 
	
			FETCH NEXT FROM settle_cursor into @settlement_ctrl_num

		END

		CLOSE settle_cursor
		DEALLOCATE settle_cursor*/

		        delete artrxstlhdr from  #tmp  where artrxstlhdr.settlement_ctrl_num = #tmp.settlement_ctrl_num
			
			insert into  artrxstlhdr
			(
			settlement_ctrl_num ,description ,date_entered ,date_applied,date_posted ,
			user_id,process_group_num ,doc_count_expected,doc_count_entered		
			,doc_sum_expected,doc_sum_entered,oa_cr_total_home,oa_cr_total_oper,
			cr_total_home ,cr_total_oper ,cm_total_home ,cm_total_oper		
			,inv_total_home	,inv_total_oper ,disc_total_home ,disc_total_oper,
			wroff_total_home ,wroff_total_oper ,onacct_total_home,onacct_total_oper	
			,gain_total_home,gain_total_oper,loss_total_home ,loss_total_oper ,
		 	customer_code, nat_cur_code, batch_code, rate_type_home, rate_home, rate_type_oper,
			rate_oper, inv_amt_nat, amt_doc_nat, amt_dist_nat, amt_on_acct, settle_flag,	org_id 
			)
			select 	arinpstlhdr.settlement_ctrl_num ,description ,date_entered ,date_applied ,@date_posted ,
			user_id , @process_group_num,doc_count_expected ,doc_count_entered		
			,doc_sum_expected ,doc_sum_entered , oa_cr_total_home ,oa_cr_total_oper 
			,cr_total_home ,cr_total_oper ,cm_total_home ,cm_total_oper 
			,inv_total_home ,inv_total_oper ,disc_total_home,disc_total_oper 
			,wroff_total_home ,wroff_total_oper ,onacct_total_home ,onacct_total_oper 
			,gain_total_home,gain_total_oper,loss_total_home ,loss_total_oper ,
		 	customer_code, nat_cur_code, batch_code, rate_type_home, rate_home, rate_type_oper,
			rate_oper, inv_amt_nat, amt_doc_nat, amt_dist_nat, amt_on_acct, settle_flag,	org_id 
			from arinpstlhdr, #tmp
			where arinpstlhdr.settlement_ctrl_num = #tmp.settlement_ctrl_num
		
			delete arinpstlhdr from #tmp where arinpstlhdr.settlement_ctrl_num = #tmp.settlement_ctrl_num 


		drop table #tmp 

		SELECT	@status = @@error

		IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, 'arinppyt.cpp', 294, 'insert arinppyt: insert action', @PERF_time_last OUTPUT

	END


	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'arinppyt.cpp', 298, 'exit arinppyt_sp', @PERF_time_last OUTPUT
	RETURN @status
END
GO
GRANT EXECUTE ON  [dbo].[arinppyt_sp] TO [public]
GO
