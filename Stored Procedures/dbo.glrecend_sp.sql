SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\GL\PROCS\glrecend.SPv - e7.2.2 : 1.13
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                



CREATE	PROCEDURE [dbo].[glrecend_sp] 
	@e_jour_num 		varchar(32),	
	@e_sys_date 		int,	
	@e_period_end_date 	int,
	@e_year_end_type 	smallint, 
	@e_proc_key 		smallint, 
	@e_user_id 		smallint, 	
	@e_orig_flag 		smallint, 	
	@new_jour_num 		varchar(32) OUTPUT

AS

DECLARE 
	@base_amt 		float,	
	@cur_date 		int,
	@err_msg 		varchar(80),
	@last_applied 		int,	
	@length 		smallint, 	
	@start_col 		smallint, 	
	@result			int,
	@E_CANT_INSERT_GLRECUR	int,
	@E_CANT_INSERT_GLRECDET	int,
	@client_id		varchar(20)

SELECT	@client_id = "POSTTRX"

SELECT	@E_CANT_INSERT_GLRECUR = e_code
FROM	glerrdef
WHERE	e_sdesc = "E_CANT_INSERT_GLRECUR"

SELECT	@E_CANT_INSERT_GLRECDET = e_code
FROM	glerrdef
WHERE	e_sdesc = "E_CANT_INSERT_GLRECDET"


IF ( @e_year_end_type = 1 )
BEGIN
	UPDATE	glrecur
	SET	posted_flag = 1
	WHERE	journal_ctrl_num = @e_jour_num

	UPDATE	glrecdet
	SET	posted_flag = 1
	WHERE	journal_ctrl_num = @e_jour_num

	RETURN 0
END


EXEC	@result = glnxtrec_sp	@new_jour_num 	OUTPUT

IF ( @result != 0 )
BEGIN
	EXEC @result =	glputerr_sp 	@client_id, 
					@e_user_id,
					@result,
					"GLRECEND.SP",
					NULL, 		
					NULL,		
					NULL,		
					NULL,		
					NULL		
	RETURN @result
END


INSERT	glrecur(
	journal_ctrl_num, recur_description, journal_type,
	tracked_balance_flag, percentage_flag, continuous_flag,
	year_end_type, recur_if_zero_flag, hold_flag,
	posted_flag, tracked_balance_amount, base_amount,
	date_last_applied, date_end_period_1, date_end_period_2,
	date_end_period_3, date_end_period_4, date_end_period_5,
	date_end_period_6, date_end_period_7, date_end_period_8,
	date_end_period_9, date_end_period_10, date_end_period_11,
	date_end_period_12, date_end_period_13, all_periods,
	number_of_periods, period_interval, intercompany_flag,
 nat_cur_code, document_1, rate_type_home,
 rate_type_oper )
SELECT
	@new_jour_num, recur_description, journal_type,
	tracked_balance_flag, percentage_flag, continuous_flag,
	year_end_type, recur_if_zero_flag, 0,
	0, tracked_balance_amount, base_amount,
	0, 0, 0,
	0, 0, 0,
	0, 0, 0,
	0, 0, 0,
	0, 		 0, 		 all_periods,
	number_of_periods, period_interval, intercompany_flag,
 nat_cur_code, document_1, rate_type_home,
 rate_type_oper
FROM	glrecur
WHERE	journal_ctrl_num = @e_jour_num

IF ( @@rowcount != 1 )
BEGIN
	EXEC @result =	glputerr_sp 	@client_id, 
					@e_user_id, 	
					@E_CANT_INSERT_GLRECUR,
					"glrecend.SP",
					NULL, 		
					NULL, 		
					NULL,		
					NULL,		
					NULL		

	RETURN @E_CANT_INSERT_GLRECUR
END


IF ( @e_year_end_type = 2 )
BEGIN
	
	UPDATE	glrecur
	SET	hold_flag = 1
	WHERE	journal_ctrl_num = @new_jour_num
	
	
	INSERT	glrecdet(
		sequence_id, journal_ctrl_num, account_code,
		document_1, amount_period_1, amount_period_2,
		amount_period_3, amount_period_4, amount_period_5,
		amount_period_6, amount_period_7, amount_period_8,
		amount_period_9, amount_period_10, amount_period_11,
		amount_period_12, amount_period_13, posted_flag,
		date_applied,	 rec_company_code, reference_code,
		document_2,	 nat_cur_code,	 offset_flag,
		seg1_code,	 seg2_code,	 seg3_code,
		seg4_code,	 seq_ref_id )
	SELECT	sequence_id, @new_jour_num, account_code,
		document_1, 0, 0,
		0, 0, 0,
		0, 0, 0,
		0, 0, 0,
		0, 0, 0,
		0,	 rec_company_code, reference_code,
		document_2,	 nat_cur_code,	 offset_flag,
		seg1_code,	 seg2_code,	 seg3_code,
		seg4_code,	 seq_ref_id
	FROM	glrecdet
	WHERE	journal_ctrl_num = @e_jour_num

	IF ( @@error != 0 )
	BEGIN
		EXEC @result =	glputerr_sp 	@client_id, 
						@e_user_id, 	
						@E_CANT_INSERT_GLRECDET,
						"glrecend.SP",
						NULL, 		
						NULL, 		
						NULL,		
						NULL,		
						NULL		

		RETURN @E_CANT_INSERT_GLRECDET
	END
END


ELSE IF ( @e_year_end_type = 3 )
BEGIN
	
	INSERT	glrecdet(
		sequence_id, journal_ctrl_num, account_code,
		document_1, amount_period_1, amount_period_2,
		amount_period_3, amount_period_4, amount_period_5,
		amount_period_6, amount_period_7, amount_period_8,
		amount_period_9, amount_period_10, amount_period_11,
		amount_period_12, amount_period_13, posted_flag,
		date_applied,	 rec_company_code, reference_code,
		document_2,	 nat_cur_code,	 offset_flag,
		seg1_code,	 seg2_code,	 seg3_code,
		seg4_code,	 seq_ref_id )
	SELECT	sequence_id, @new_jour_num, account_code,
		document_1, amount_period_1, amount_period_2,
		amount_period_3, amount_period_4, amount_period_5,
		amount_period_6, amount_period_7, amount_period_8,
		amount_period_9, amount_period_10, amount_period_11,
		amount_period_12, amount_period_13, 0,
		0,	 rec_company_code, reference_code,
		document_2,	 nat_cur_code,	 offset_flag,
		seg1_code,	 seg2_code,	 seg3_code,
		seg4_code,	 seq_ref_id
	FROM	glrecdet
	WHERE	journal_ctrl_num = @e_jour_num

	IF ( @@error != 0 )
	BEGIN
		EXEC @result =	glputerr_sp 	@client_id, 
						@e_user_id, 	
						@E_CANT_INSERT_GLRECDET,
						"glrecend.SP",
						NULL, 		
						NULL, 		
						NULL,		
						NULL,		
						NULL		

		RETURN @E_CANT_INSERT_GLRECDET
	END
END


UPDATE	glrecur
SET	posted_flag = 1,
	recur_description = @new_jour_num
WHERE	journal_ctrl_num = @e_jour_num

UPDATE	glrecdet
SET	posted_flag = 1
WHERE	journal_ctrl_num = @e_jour_num


EXEC @result = glrecprd_sp	@e_jour_num, 
				@new_jour_num, 
				@e_sys_date, 
				@e_period_end_date,
		 		@e_year_end_type, 
				@e_proc_key, 
				@e_user_id, 
				@e_orig_flag

RETURN @result
	




/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glrecend_sp] TO [public]
GO
