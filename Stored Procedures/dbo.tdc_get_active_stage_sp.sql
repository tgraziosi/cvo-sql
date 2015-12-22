SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*                        					  */
/* This Stored Procedure will:					  */
/* 								  */
/*	1) Check to see if a stage record exists.  Should only be */
/*	   1 at all times in the table 'tdc_active_stage'. If */
/*	   a record does not exist, then go ahead and create it.  */
/* 	2) If a record does exist, compare the current date with  */
/*	   the first 8 characters of the stage_no. If different,  */
/*	   then update with the current date (i.e. 19981118001).  */
/*								  */
/* 11/18/1998	Initial		CAC				  */
/*								  */

CREATE PROCEDURE [dbo].[tdc_get_active_stage_sp] (@stage_no char(11) OUTPUT) AS

	/* Declare local variables */
	DECLARE @tmp_stage_no 		char(11)
	DECLARE @current_date_str 	char(8)   -- YYYYMMDD
	DECLARE @tmp_date_str		char(10)  -- YYYY.MM.DD
	DECLARE @counter_str 		char(3)
	DECLARE @tmp			char(8)   -- YYYYMMDD
	DECLARE @cnt 			int
		
	SELECT @cnt = 0
	
	/*
	* Check if a stage record exists.  This should only return 0 the very
	* first time this stored procedure is ever called.
	*/
	SELECT @cnt=count(*)
	FROM tdc_active_stage
	
	IF (@cnt = 0) 
	BEGIN
		SELECT @tmp_date_str=CONVERT(char(10), getdate(), 102)
		SELECT @current_date_str = CONVERT(char(8), 
			(CONVERT(char(4),@tmp_date_str) + 
			CONVERT(char(2),right(@tmp_date_str,5)) +
			CONVERT(char(2),right(@tmp_date_str,2))))
		SELECT @tmp_stage_no=(@current_date_str + '001')

		INSERT INTO tdc_active_stage
		(stage_no)
		VALUES
		(@tmp_stage_no)
	END
	ELSE 
	BEGIN
		SELECT @tmp_date_str=CONVERT(char(10), getdate(), 102)
		SELECT @current_date_str = CONVERT(char(8), 
			(CONVERT(char(4),@tmp_date_str) + 
			CONVERT(char(2),right(@tmp_date_str,5)) +
			CONVERT(char(2),right(@tmp_date_str,2))))

		SELECT @tmp=CONVERT(char(8), stage_no) 
		FROM tdc_active_stage
		
		SELECT @tmp_stage_no = CONVERT(char(11), @current_date_str + '001')	

		/*
		* Check if stage number matches current date.  If not, then 
		* we need to update, otherwise we simply return the stage_no.
		*/
		IF (@tmp <> @current_date_str) 
		BEGIN				
			UPDATE tdc_active_stage SET stage_no = @tmp_stage_no  
		END
	END

	IF NOT EXISTS(SELECT * FROM tdc_stage_numbers_tbl WHERE stage_no = @tmp_stage_no)
		INSERT INTO tdc_stage_numbers_tbl (stage_no, active, creation_date) VALUES(@tmp_stage_no, 'Y', GETDATE())
	ELSE
		UPDATE tdc_stage_numbers_tbl SET active = 'Y'
		 WHERE stage_no = @tmp_stage_no
	
	SELECT @stage_no = stage_no
	FROM tdc_active_stage
GO
GRANT EXECUTE ON  [dbo].[tdc_get_active_stage_sp] TO [public]
GO
