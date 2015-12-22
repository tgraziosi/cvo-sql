SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2009 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2009 Epicor Software Corporation, 2009    
                  All Rights Reserved                    
*/                                                


























Create Procedure [dbo].[nbbatch_sp] @process_ctrl_num varchar (16), @result smallint output
as

declare @new_batch_code varchar(16),
	@batch_date_applied int,
	@trx_type smallint,
	@batch_trx_type smallint,
	@trx_ctrl_num varchar(16),
	@company_code varchar(8),
	@adm_org_id VARCHAR(30)



SET @adm_org_id = (select organization_id from Organization where outline_num = '1')

select @company_code = company_code from glco
 

if exists(select company_id from apco where batch_proc_flag = 1)
Begin
	---Vouchers: Create the batch for the voucher entered
	
	if EXISTS(select trx_ctrl_num from apinpchg where tax_code = 'NBTAX' and trx_type = 4091 and posted_flag = -1  and batch_code = '' )  
	Begin 
		
		set rowcount 1 
		select @batch_date_applied = Min(date_applied) from apinpchg where tax_code = 'NBTAX' and trx_type = 4091 and posted_flag = -1 and batch_code = ''
		set rowcount 0
		
	
		While @batch_date_applied is not null
		Begin
			select @trx_type = 4091, @batch_trx_type= 4010
		
			exec apnxtbat_sp   0,
				   '',
				   @batch_trx_type,
				   1,
				   @batch_date_applied,
				   @company_code,
				   @new_batch_code OUTPUT,
				   '',
				   @adm_org_id

			IF ( @result != 0 )
				RETURN  @result
		
			UPDATE  apinpchg
			SET     batch_code = @new_batch_code
			WHERE   date_applied = @batch_date_applied
			AND     trx_type = @trx_type
			AND	tax_code = 'NBTAX'
			AND     posted_flag = -1
			AND 	batch_code = ''
		
			UPDATE batchctl
			SET actual_number = (SELECT COUNT(*) FROM apinpchg
						WHERE batch_code = @new_batch_code),
			    actual_total = (SELECT ISNULL(SUM(amt_net),0.0) FROM apinpchg
						WHERE batch_code = @new_batch_code),
			    number_held = (SELECT COUNT(*) FROM apinpchg
						WHERE batch_code = @new_batch_code
						AND hold_flag = 1),
			    completed_date = start_date,
			    completed_time = start_time,
			    completed_user = start_user,
			    process_group_num = @process_ctrl_num,
			    posted_flag = -1
			WHERE batch_ctrl_num = @new_batch_code
	
			Select @batch_date_applied= null
	
			set rowcount 1 
			select @batch_date_applied= Min(date_applied) from apinpchg where tax_code = 'NBTAX' and trx_type = 4091 and posted_flag = -1 and batch_code = '' and date_applied > @batch_date_applied
			set rowcount 0
		End
	
	END 
	 
	select @new_batch_code = null

	--Debit Memos : Create the batch for the Debit Memos entered
	
	IF EXISTS(select trx_ctrl_num from apinpchg where tax_code = 'NBTAX' and trx_type = 4092 and posted_flag = -1 and batch_code = '')
	
	Begin 
		
		set rowcount 1 
		select @batch_date_applied = Min(date_applied) from apinpchg where tax_code = 'NBTAX' and trx_type = 4092 and posted_flag = -1 and batch_code = ''
		set rowcount 0
		
		While @batch_date_applied is not null
		Begin 
			
			select @trx_type = 4092, @batch_trx_type= 4030
			
			exec apnxtbat_sp   0,
					   '',
					   @batch_trx_type,
					   1,
					   @batch_date_applied,
					   @company_code,
					   @new_batch_code OUTPUT,
					   '',
					   @adm_org_id

			IF ( @result != 0 )
				RETURN  @result
			
			UPDATE  apinpchg
			SET     batch_code = @new_batch_code
			WHERE   date_applied = @batch_date_applied
			AND     trx_type = @trx_type
			AND	tax_code = 'NBTAX'
			AND     posted_flag = -1
			AND     batch_code = ''
	
			UPDATE batchctl
			SET actual_number = (SELECT COUNT(*) FROM apinpchg
						WHERE batch_code = @new_batch_code),
			    actual_total = (SELECT ISNULL(SUM(amt_net),0.0) FROM apinpchg
						WHERE batch_code = @new_batch_code),
			    number_held = (SELECT COUNT(*) FROM apinpchg
						WHERE batch_code = @new_batch_code
						AND hold_flag = 1),
			    completed_date = start_date,
			    completed_time = start_time,
			    completed_user = start_user,
			    process_group_num = @process_ctrl_num,
			    posted_flag = -1
			WHERE batch_ctrl_num = @new_batch_code
	
			Select @batch_date_applied= null
	
			set rowcount 1 
			select @batch_date_applied= Min(date_applied) from apinpchg where tax_code = 'NBTAX' and trx_type = 4092 and posted_flag = -1 and batch_code = '' and date_applied > @batch_date_applied
			set rowcount 0
		End
	END
	
	select @new_batch_code = null

	--Payments : Create the batch for the Payments entered

	if EXISTS(select trx_ctrl_num from apinppyt where trx_desc like 'Net%' and trx_type = 4111 and posted_flag = -1 and batch_code = '')  
	Begin  
		
		set rowcount 1 
		select @batch_date_applied = Min(date_applied) from apinppyt where trx_desc like 'Net%' and trx_type = 4111 and posted_flag = -1 and batch_code = ''
		set rowcount 0
	
		While @batch_date_applied is not null
		Begin 
			select @trx_type = 4111, @batch_trx_type= 4070
	
			
	
			exec apnxtbat_sp   0,
					   '',
					   @batch_trx_type,
					   1,
					   @batch_date_applied,
					   @company_code,
					   @new_batch_code OUTPUT,
					   '',
					   @adm_org_id
	
			IF ( @result != 0 )
				RETURN  @result
			
			UPDATE  apinppyt
			SET     batch_code = @new_batch_code
			WHERE   date_applied = @batch_date_applied
			AND     trx_type = @trx_type
			AND     trx_desc like 'Net%' 
			AND     posted_flag = -1
			AND     batch_code = ''
	
			UPDATE  apinpstl
			SET     batch_code = @new_batch_code
			WHERE   settlement_ctrl_num  in (select settlement_ctrl_num from apinppyt  where batch_code = @new_batch_code)		
	
			UPDATE batchctl
			SET actual_number = (SELECT COUNT(*) FROM apinppyt
						WHERE batch_code = @new_batch_code),
			    actual_total = (SELECT ISNULL(SUM(amt_payment),0.0) FROM apinppyt
						WHERE batch_code = @new_batch_code),
			    number_held = (SELECT COUNT(*) FROM apinppyt
						WHERE batch_code = @new_batch_code
						AND hold_flag = 1),
			    completed_date = start_date,
			    completed_time = start_time,
			    completed_user = start_user,
			    process_group_num = @process_ctrl_num,
			    posted_flag = -1			
			WHERE batch_ctrl_num = @new_batch_code
	
			Select @batch_date_applied= null
	
			set rowcount 1 
			select @batch_date_applied= Min(date_applied) from apinppyt where trx_desc like 'Net%' and trx_type = 4111 and posted_flag = -1 and batch_code = '' and date_applied > @batch_date_applied
			set rowcount 0
		End
	END 
END

--AR batches

if exists(select company_id from arco where batch_proc_flag = 1)
Begin
	--Invoices : Create the batch for the Invoices entered
	if EXISTS(select trx_ctrl_num from arinpchg  where tax_code = 'NBTAX' and trx_type = 2031 and posted_flag = -1 and batch_code = '')  
	Begin  
	
		
		set rowcount 1 
		select @batch_date_applied = Min(date_applied) from arinpchg  where tax_code = 'NBTAX' and trx_type = 2031 and posted_flag = -1 and batch_code = ''
		set rowcount 0
	
		While @batch_date_applied is not null
		Begin 
			select @trx_type = 2031, @batch_trx_type= 2010
	
			
				EXEC @result = arnxtbat_sp	
					   0,
					   '',
					   @batch_trx_type,
					   1,
					   @batch_date_applied,
					   @company_code, --@company_code,
					   @new_batch_code OUTPUT,
					   0,
					   @adm_org_id
								
				
				IF ( @result != 0 )
					RETURN  @result
	
		
				UPDATE	arinpchg
				SET	batch_code = @new_batch_code
				WHERE	date_applied = @batch_date_applied
				AND     tax_code = 'NBTAX'
				AND     trx_type = @trx_type
				AND	batch_code = ''
				AND	posted_flag = -1
	
				UPDATE batchctl
				SET actual_number = (SELECT COUNT(*) FROM arinpchg
							WHERE batch_code = @new_batch_code),
				    actual_total = (SELECT ISNULL(SUM(amt_net),0.0) FROM arinpchg
							WHERE batch_code = @new_batch_code),
				    number_held = (SELECT COUNT(*) FROM arinpchg
							WHERE batch_code = @new_batch_code
							AND hold_flag = 1),
				    completed_date = start_date,
				    completed_time = start_time,
				    completed_user = start_user,
				    process_group_num = @process_ctrl_num,
				    posted_flag = -1			
				WHERE	batch_ctrl_num = @new_batch_code
	
			set rowcount 1 
			select @batch_date_applied= Min(date_applied) from arinpchg  where tax_code = 'NBTAX' and trx_type = 2031 and posted_flag = -1 and batch_code = '' and date_applied > @batch_date_applied
			set rowcount 0
		End
	End
	
	--Credit Memos : Create the batch for the Credit Memos  entered
	if EXISTS(select trx_ctrl_num from arinpchg  where tax_code = 'NBTAX' and trx_type = 2032 and posted_flag = -1 and batch_code = '')  
	Begin  
	
		set rowcount 1 
		select @batch_date_applied = Min(date_applied) from arinpchg  where tax_code = 'NBTAX' and trx_type = 2032 and posted_flag = -1 and batch_code = ''
		set rowcount 0
	
		While @batch_date_applied is not null
		Begin 
			select @trx_type = 2032, @batch_trx_type= 2030
	
				EXEC @result = arnxtbat_sp	
					   0,
					   '',
					   @batch_trx_type,
					   1,
					   @batch_date_applied,
					   @company_code, --@company_code,
					   @new_batch_code OUTPUT,
					   0,
					   @adm_org_id
								
				
				IF ( @result != 0 )
					RETURN  @result
	
				
				UPDATE	arinpchg
				SET	batch_code = @new_batch_code
				WHERE	date_applied = @batch_date_applied
				AND     tax_code = 'NBTAX'
				AND     trx_type = @trx_type
				AND	batch_code = ''
				AND	posted_flag = -1
	
				UPDATE batchctl
				SET actual_number = (SELECT COUNT(*) FROM arinpchg
							WHERE batch_code = @new_batch_code),
				    actual_total = (SELECT ISNULL(SUM(amt_net),0.0) FROM arinpchg
							WHERE batch_code = @new_batch_code),
				    number_held = (SELECT COUNT(*) FROM arinpchg
							WHERE batch_code = @new_batch_code
							AND hold_flag = 1),
				    completed_date = start_date,
				    completed_time = start_time,
				    completed_user = start_user,
				    process_group_num = @process_ctrl_num,
				    posted_flag = -1			
				WHERE	batch_ctrl_num = @new_batch_code
	
			set rowcount 1 
			select @batch_date_applied= Min(date_applied) from arinpchg  where tax_code = 'NBTAX' and trx_type = 2032 and posted_flag = -1 and batch_code = '' and date_applied > @batch_date_applied
			set rowcount 0
		End
	End
	
	--Cash Receipts: the AR Cash Receipts do not need batch.
	






























































END

Return 0

/**/                                              
GO
GRANT EXECUTE ON  [dbo].[nbbatch_sp] TO [public]
GO
