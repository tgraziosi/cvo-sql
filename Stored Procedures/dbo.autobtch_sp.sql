SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[autobtch_sp] @description varchar(40)

AS
DECLARE @today integer,
	@cur_time integer,
	@min_date_applied integer,
	@last_date_applied integer,
	@new_bcn varchar(16),
	@ret_status integer,
	@num integer,
	@batch_code varchar(16),
	@company_code varchar(8),
	@result integer,
	@actual_number integer,
	@actual_total float,
	@user_name varchar(10)


/* Get today's date */
EXEC appdate_sp @today OUTPUT

/* Get the current time */
SELECT 	@cur_time = datepart(hour,getdate())*3600+ datepart(minute,getdate())*60+  datepart(second,getdate())

/* Get the company code */
SELECT	@company_code = company_code 
FROM 	arco a, glcomp_vw b
WHERE 	a.company_id=b.company_id

SELECT 	@min_date_applied = 0,
	@last_date_applied = 0

WHILE 1=1
BEGIN
	SELECT 	@min_date_applied = min(date_applied)
	FROM	#arinppyt_work
	WHERE	date_applied > @last_date_applied

	IF @min_date_applied IS NULL BREAK

	SELECT 	@last_date_applied = @min_date_applied


	/* Get the next AR to GL batch number */
	EXEC @ret_status = ARGetNextControl_SP 2100,  @new_bcn OUTPUT, @num OUTPUT  
	IF @ret_status != 0
	BEGIN
		ROLLBACK TRANSACTION AUTOCASH_LOAD
		RETURN 1
	END
	

	/* Update the cash receipts with the AR to GL batch number */
	UPDATE  #arinppyt_work  
	SET 	batch_code = RTRIM(@new_bcn)  
	WHERE 	date_applied = @min_date_applied
	IF @@error != 0
	BEGIN
		ROLLBACK TRANSACTION AUTOCASH_LOAD
		RETURN 1
	END


	/* Set the actual totals of the batch */
	SELECT	@actual_number = count(*) 
	FROM	#arinppyt_work 
	WHERE	batch_code = @new_bcn

	SELECT	@actual_total = sum(amt_payment)
	FROM	#arinppyt_work 
	WHERE	batch_code = @new_bcn
	
	SELECT 	@user_name = current_user
	
	/* Create the AR to GL batch record */
	INSERT batchctl	(timestamp,  
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
		page_fill_8  )  
	VALUES 	(NULL, 
		RTRIM(@new_bcn), 
		@description, 
		@today, 
 		@cur_time, 
		@today, 
		@cur_time, 
		0, 
		0, 
		@actual_number, 
		@actual_total,  
		2050, 
		@description, 
		0, 
		0, 
		0, 
		0, 
 		0, 
		@min_date_applied, 
		0, 
		0, 
		@user_name, 
		@user_name, 
		'', 
		@company_code, 
		NULL,  
		NULL, 
		NULL, 
		NULL, 
		NULL, 
		NULL, 
		NULL, 
		NULL, 
		NULL) 
	IF @@error != 0
	BEGIN
		ROLLBACK TRANSACTION AUTOCASH_LOAD
		RETURN 1
	END
END

RETURN 0

GO
GRANT EXECUTE ON  [dbo].[autobtch_sp] TO [public]
GO
