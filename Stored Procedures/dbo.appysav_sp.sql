SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE  PROCEDURE [dbo].[appysav_sp]  @proc_user_id smallint, @batch_code varchar(16) = NULL,
                              @debug smallint = 0
							
				
AS

BEGIN

	DECLARE @tran_started           smallint,
		@batch_module_id    smallint, 
		@batch_date_applied     int,            
		@batch_source       varchar(16),
		@batch_trx_type   smallint,
		@trx_type         smallint,
		@home_company     varchar(8),
		@result           smallint,
		@new_batch_code    varchar(16),
		@org_id		   varchar(30) 


		DECLARE @count_actual_number int
		DECLARE @sum_amt_payment float
		DECLARE @number_held int
	

	


	IF NOT EXISTS (SELECT 1 FROM #apinppyt)
	   RETURN 0


	SELECT  @tran_started = 0
	



	IF EXISTS(      SELECT  1
			FROM    apco
			WHERE   batch_proc_flag = 1 )
	BEGIN
		INSERT #appybat
		SELECT  DISTINCT    date_applied, 
				    process_group_num,
				    trx_type,
				    org_id 
		FROM    #apinppyt

		



		IF @@rowcount > 1
		    SELECT @batch_code = NULL

	END
	

	SELECT @home_company = company_code from glco
	




	IF ( @@trancount = 0 )
	BEGIN
		BEGIN TRANSACTION
		SELECT  @tran_started = 1
	END
	



	IF EXISTS(      SELECT  1
			FROM    apco
			WHERE   batch_proc_flag = 1 )
	BEGIN
		IF @batch_code IS NULL
			BEGIN
				WHILE 1=1
				BEGIN
					SELECT  @batch_date_applied = NULL
					SELECT  @batch_date_applied = MIN( date_applied )
					FROM    #appybat
			
					IF ( @batch_date_applied IS NULL )
						break
			
			

					SELECT @batch_source = MIN( process_group_num),
					       @org_id = MIN(org_id) 
					FROM   #appybat
					WHERE  date_applied  = @batch_date_applied

					SELECT @trx_type = MIN( trx_type )
					FROM   #appybat
					WHERE  date_applied = @batch_date_applied
					AND    process_group_num = @batch_source
					AND    org_id = @org_id 

			
					IF     @trx_type IN (4111,4011)
					       SELECT @batch_trx_type = 4040
				    ELSE IF @trx_type = 4112
						   SELECT @batch_trx_type = 4060


					EXEC    @result = apnxtbat_sp   
								@batch_module_id,
								@batch_source,
								@batch_trx_type,
								@proc_user_id,
								@batch_date_applied,
								@home_company,
								@new_batch_code OUTPUT,
								NULL,
								@org_id 

					IF ( @result != 0 )
						RETURN  @result
				
					UPDATE  #apinppyt
					SET     batch_code = @new_batch_code
					WHERE   date_applied = @batch_date_applied
					AND     trx_type = @trx_type
					AND 	org_id  =@org_id




					SELECT @count_actual_number = COUNT(1), @sum_amt_payment = ISNULL(SUM(amt_payment),0.0) 
					FROM #apinppyt WHERE batch_code = @new_batch_code

					SELECT @number_held = COUNT(1) FROM #apinppyt
					WHERE batch_code = @new_batch_code
					AND hold_flag = 1					
				
					UPDATE batchctl_all
					SET actual_number = @count_actual_number,
						actual_total = @sum_amt_payment,
						number_held = @number_held,
						hold_flag = SIGN(number_held)
					WHERE batch_ctrl_num = @new_batch_code


			
















					DELETE  #appybat
					WHERE   date_applied = @batch_date_applied
					AND trx_type = @trx_type
					AND org_id = @org_id 
				
					SELECT @new_batch_code = NULL 
		
				END
		
			END
		ELSE
			BEGIN
				SELECT @new_batch_code = @batch_code
				
				SELECT     @trx_type = trx_type, 
					   @batch_date_applied = date_applied,
					   @org_id = org_id	
			    FROM   #appybat
		
				IF     @trx_type IN (4111,4011)
				       SELECT @batch_trx_type = 4040
			    ELSE IF @trx_type = 4112
					   SELECT @batch_trx_type = 4060
				
				EXEC    @result = apnxtbat_sp   
							@batch_module_id,
							@batch_source,
							@batch_trx_type,
							@proc_user_id,
							@batch_date_applied,
							@home_company,
							@new_batch_code OUTPUT,
							NULL,
							@org_id


--REV  3.1

				SELECT @count_actual_number = COUNT(1), @sum_amt_payment = ISNULL(SUM(amt_payment),0.0) FROM #apinppyt
				select @number_held = COUNT(1) FROM #apinppyt WHERE hold_flag = 1
		
				UPDATE batchctl_all
				SET actual_number = @count_actual_number,
					actual_total = @sum_amt_payment,
					number_held = @number_held,
					hold_flag = SIGN(number_held)
				WHERE batch_ctrl_num = @new_batch_code















				UPDATE  #apinppyt
				SET     batch_code = @new_batch_code

			END
			 
		END













DECLARE @zero_balance_payments  TABLE 
	( 
		trx_ctrl_num varchar ( 16 ) , 
		amount float 
	)

--INSERT INTO #zero_balance_payments 
INSERT INTO @zero_balance_payments 
	( 
		trx_ctrl_num , 
		amount 
	)
SELECT 	trx_ctrl_num, 
		sum(amt_applied) 
FROM  	#apinppdt 
GROUP BY trx_ctrl_num


UPDATE	#apinppyt
SET		printed_flag = 2,
		doc_ctrl_num = a.trx_ctrl_num
FROM 	#apinppyt a, @zero_balance_payments b
WHERE  	a.trx_ctrl_num = b.trx_ctrl_num
AND  	b.amount = 0


--FROM 	#apinppyt a, #zero_balance_payments b
--DROP TABLE #zero_balance_payments


	
	INSERT  apinppyt (      
	
	timestamp,
	trx_ctrl_num,
    trx_type,
	doc_ctrl_num,
	trx_desc,
	batch_code,
	cash_acct_code,
	date_entered,
	date_applied,
	date_doc,
    vendor_code,
	pay_to_code,
	approval_code,
	payment_code,
	payment_type,
    amt_payment,
	amt_on_acct,
	posted_flag,
	printed_flag,
	hold_flag,
	approval_flag,
	gen_id,
	user_id,
	void_type,       
	amt_disc_taken,
	print_batch_num,          
	company_code,
	process_group_num,
	nat_cur_code,
	rate_type_home,
	rate_type_oper,
	rate_home,
	rate_oper,
	org_id
	 )
			
	SELECT          NULL,
	trx_ctrl_num,
    trx_type,
	doc_ctrl_num,
	trx_desc,
	batch_code,
	cash_acct_code,
	date_entered,
	date_applied,
	date_doc,
    vendor_code,
	pay_to_code,
	approval_code,
	payment_code,
	payment_type,
    amt_payment,
	amt_on_acct,
	posted_flag,
	printed_flag,
	hold_flag,
	approval_flag,
	gen_id,
	user_id,
	void_type,       
	amt_disc_taken,
	print_batch_num,          
	company_code,
	process_group_num,
	nat_cur_code,
	rate_type_home,
	rate_type_oper,
	rate_home,
	rate_oper,
	org_id
	FROM    #apinppyt

	IF ( @@error != 0 )
	BEGIN
		rollback transaction
		RETURN  -1
	END
	


	INSERT  apinppdt (
		timestamp,
		trx_ctrl_num,
		trx_type,
		sequence_id,    
		apply_to_num,
		apply_trx_type,       
		amt_applied,          
		amt_disc_taken,  
		line_desc,
		void_flag,
		payment_hold_flag,
		vendor_code,
		vo_amt_applied,
		vo_amt_disc_taken,
		gain_home,
		gain_oper,
		nat_cur_code,
		org_id
		)
				
	SELECT  NULL,
		trx_ctrl_num,
		trx_type,
		sequence_id,    
		apply_to_num,
		apply_trx_type,       
		amt_applied,          
		amt_disc_taken,  
		line_desc,
		void_flag,
		payment_hold_flag,
		vendor_code,
		vo_amt_applied,
		vo_amt_disc_taken,
		gain_home,
		gain_oper,
		nat_cur_code,
		org_id
	FROM    #apinppdt


	IF ( @@error != 0 )
	BEGIN
		rollback transaction
		RETURN  -1
	END

		




	






	EXEC    @result = appyusv_sp
	IF ( @result != 0 )
		RETURN  @result
		
	TRUNCATE TABLE #apinppyt
	TRUNCATE TABLE  #apinppdt

	TRUNCATE TABLE  #appybat

	IF ( @tran_started = 1 )
	BEGIN
		COMMIT TRANSACTION
		SELECT  @tran_started = 0
	END
	




END
GO
GRANT EXECUTE ON  [dbo].[appysav_sp] TO [public]
GO
