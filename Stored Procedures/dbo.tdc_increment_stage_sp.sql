SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_increment_stage_sp] 
@stage_no char(11) OUTPUT 
AS

DECLARE 
@tmp_date_str 	VARCHAR(255),  
@tmp_stage_no 	VARCHAR(11), 
@counter_str 	VARCHAR(3),
@record_cnt 	INT,
@ctr		INT 

	--Get the current date (formatted)
	SELECT @tmp_date_str=convert(char,GETDATE(),112)

	--Build the counter string eg: '001'
	SELECT @ctr = 1
	SELECT @counter_str = CAST(@ctr AS varchar(3))
	WHILE LEN(@counter_str) < 3
		SELECT @counter_str = '0' + @counter_str

	--Build the first stage number
	SELECT @tmp_stage_no = LTRIM(RTRIM(@tmp_date_str)) + LTRIM(RTRIM(@counter_str))

	--Check to see if there are any records existing with this stage number
	SELECT @record_cnt = COUNT(*) FROM tdc_stage_numbers_tbl (NOLOCK)
		      WHERE stage_no = @tmp_stage_no

	--If records, loop incrementing the counter string
	WHILE @record_cnt > 0
	BEGIN
		--Build the counter string
		SELECT @ctr = @ctr + 1
		SELECT @counter_str = CAST(@ctr AS varchar(3))
		WHILE LEN(@counter_str) < 3
			SELECT @counter_str = '0' + @counter_str
		
		--Build the stage number
		SELECT @tmp_stage_no = LTRIM(RTRIM(@tmp_date_str)) + LTRIM(RTRIM(@counter_str))

		--Get the record count
		SELECT @record_cnt = COUNT(*) FROM tdc_stage_numbers_tbl (NOLOCK)
			      WHERE stage_no = @tmp_stage_no
	END

	--Insert the record
	INSERT INTO tdc_stage_numbers_tbl
		(stage_no,active,creation_date)
	VALUES
	  	(@tmp_stage_no,'Y',GETDATE())

	SELECT @stage_no = @tmp_stage_no
GO
GRANT EXECUTE ON  [dbo].[tdc_increment_stage_sp] TO [public]
GO
