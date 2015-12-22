SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                


























































  



					  

























































 






















































































































































































































































































































CREATE PROC  [dbo].[arinvbat_sp]	@cur_bat_code	varchar( 16 ),
							@r_user_id		int,
							@debug_level	smallint = 0
AS

DECLARE	
	@cur_bat_desc	varchar( 30 ),
	@cur_doc_name	varchar( 30 ),
	@cur_bat_type	int,
	@new_bcn		varchar( 16 ), 
	@num			int, 
	@mask			varchar( 16 ), 
	@err_rtn		int, 
	@cur_date		int, 
	@cur_time		int, 
	@count			int, 
	@sum_amt_net	int, 
	@user_name		varchar(16), 
	@num_held		int, 
	@last_rec_code	varchar( 8 ),  
	@rec_code		varchar( 8 ), 
	@apply_date		int, 
	@ret_status		int,
	@company_code	varchar( 8 ),
	@org_id		varchar(30)

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinvbat.cpp" + ", line " + STR( 63, 5 ) + " -- ENTRY: "

	


	EXEC appdate_sp @cur_date OUTPUT

	SELECT	@cur_time = datepart(hour,getdate())*3600+
								datepart(minute,getdate())*60+
								datepart(second,getdate())

	



	SELECT	@company_code = company_code
	FROM glco

	


	SELECT	@user_name = user_name 
	FROM CVO_Control..smusers a
	WHERE a.user_id = @r_user_id 

	SELECT @rec_code = " "

	WHILE ( 1=1)
	BEGIN

		











		SELECT	@rec_code = MIN(recurring_code),
			@apply_date = MIN(date_applied),
			@org_id = MIN(org_id)
		FROM arinpchg
		WHERE batch_code = @cur_bat_code

		IF ( @@rowcount = 0 )
			break

		


	
		EXEC @ret_status = ARGetNextControl_SP	2100,
											@new_bcn OUTPUT,
											@num OUTPUT

		IF (@ret_status != 0)
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinvbat.cpp" + ", line " + STR( 124, 5 ) + " -- EXIT: "
			RETURN @ret_status
		END

		


		UPDATE arinpchg
		SET    batch_code = @new_bcn
		WHERE  batch_code = @cur_bat_code
		AND  recurring_flag = 1
		AND  recurring_code = @rec_code
		AND  org_id = @org_id

		


		SELECT	@count = count(*),
				@sum_amt_net = sum(amt_net)
		FROM   arinpchg
		WHERE  batch_code = @new_bcn
	
		SELECT	@num_held = count(*)
		FROM   arinpchg
		WHERE  batch_code = @new_bcn
		AND  hold_flag = 1


		SELECT	@cur_bat_type = batch_type,
				@cur_doc_name = document_name,
				@cur_bat_desc = batch_description
		FROM   batchctl
		WHERE  batch_ctrl_num = @cur_bat_code

		







		INSERT batchctl
		(
			timestamp,
			batch_ctrl_num,
			batch_description,
			start_date,
			start_time,
			completed_date,
			completed_time,
			control_number,
			control_total,
			actual_number,
			actual_total,
			batch_type,
			document_name,
			hold_flag,
			posted_flag,
			void_flag,
			selected_flag,
			number_held,
			date_applied,
			date_posted,
			time_posted,
			start_user,
			completed_user,
			posted_user,
			company_code,
			selected_user_id,
			page_fill_1,
			page_fill_2,
			page_fill_3,
			page_fill_4,
			page_fill_5,
			page_fill_6,
			page_fill_7,
			page_fill_8,
			org_id
		)                               
		VALUES (NULL, @new_bcn, @cur_bat_desc, @cur_date, 
				@cur_time, 0, 0, @count, @sum_amt_net, @count, @sum_amt_net, 
				@cur_bat_type, @cur_doc_name, 1, 0, 0, 0, 
				@num_held, @apply_date, 0, 0, @user_name, '', '', '', NULL, 
				NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
				@org_id) 
	END

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinvbat.cpp" + ", line " + STR( 212, 5 ) + " -- EXIT: "
	RETURN 0

/**/                                              
GO
GRANT EXECUTE ON  [dbo].[arinvbat_sp] TO [public]
GO
