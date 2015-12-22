SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[appobatch_sp]
AS

DECLARE	@batch_loop	VARCHAR(16),
	@new_batch	VARCHAR(16),
	@batch_flag	SMALLINT,
	@result		INT,
	@org_id VARCHAR(30)	--Rev 1.0
	
	SELECT @result = 0




CREATE TABLE #batch_pivot
(
	match_batch	VARCHAR(16),
	vouch_batch	VARCHAR(16),
	org_id VARCHAR(30)			--SCR 36988 
)



	INSERT #batch_pivot(match_batch, vouch_batch, org_id)	--Rev 1.0	
	SELECT DISTINCT batch_code, " ", org_id	--Rev 1.0
	FROM #apinpchg

	
	SELECT @batch_loop = MIN(match_batch)
	FROM #batch_pivot
	
	
	SELECT @org_id = org_id 
	FROM #batch_pivot   
	WHERE match_batch = @batch_loop

	WHILE @batch_loop IS NOT NULL
	BEGIN

		SELECT @new_batch = ''

		EXEC @result = apbatnum_sp @batch_flag, @new_batch OUTPUT

		IF @result <> 0
		BEGIN
	       		RETURN 100
		END
		
		
		INSERT batchctl (
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
			process_group_num,
			page_fill_1,
			page_fill_2,
			page_fill_3,
			page_fill_4,
			page_fill_5,
			page_fill_6,
			page_fill_7,
			page_fill_8,
			org_id			--Rev 1.0	
		)
		SELECT @new_batch,
			a.batch_description,
			a.start_date,
			a.start_time,
			0,
			0,
			0,
			0,
			a.actual_number,
			a.actual_total,
			4010,
			b.document_name,
                  	0,
			0,
			0,
			0,
			0,
			a.date_applied,
			0,
			0,
			a.start_user,
			0,
			0,
                    	a.company_code,
			0,
			" ",
			a.page_fill_1,
			a.page_fill_2,
			a.page_fill_3,
			a.page_fill_4,
			a.page_fill_5,
			a.page_fill_6,
			a.page_fill_7,
			a.page_fill_8,
			@org_id			--Rev 1.0
		FROM batchctl a, batchtyp b
		WHERE a.batch_ctrl_num = @batch_loop
		AND b.batch_type = 4010

		IF @@error <> 0  
		BEGIN 
			DROP TABLE #batch_pivot
			RETURN 100
		END 
			
		
		UPDATE #batch_pivot
			SET vouch_batch = @new_batch
		WHERE match_batch = @batch_loop

		IF @@error <> 0  
		BEGIN 
			DROP TABLE #batch_pivot
			RETURN 100
		END 

		SELECT @batch_loop = MIN(match_batch)
		FROM #batch_pivot
		WHERE match_batch > @batch_loop
		
		/* Rev. 2.0*/
		SELECT @org_id = org_id 
		FROM #batch_pivot   
		WHERE match_batch = @batch_loop
	END

	UPDATE #apinpchg
		SET batch_code = b.vouch_batch
	FROM #apinpchg a, #batch_pivot b
	WHERE a.batch_code = b.match_batch

	IF @@error <> 0  
	BEGIN 
		DROP TABLE #batch_pivot
		RETURN 100
	END 	

	DROP TABLE #batch_pivot
RETURN @result
GO
GRANT EXECUTE ON  [dbo].[appobatch_sp] TO [public]
GO
