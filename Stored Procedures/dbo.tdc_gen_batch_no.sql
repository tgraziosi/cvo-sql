SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/************************************************************************/
/* Name:	tdc_gen_next_batch_no		      	      		*/
/*									*/
/* Module:	WMS							*/
/*						      			*/
/* Input:						      		*/
/*	prefix    - 	Batch Preifx			      		*/
/* Output:        					     	 	*/
/*	@batch_no -	Generated Batch Number		     	 	*/
/*									*/
/* Description:								*/
/*	This SP generate new batch_no for the prefix+current_date	*/
/*	combination						 	*/
/* Revision History:							*/
/* 	Date		Who	Description				*/
/*	----		---	-----------				*/
/* 	07/17/2000	IA	Initial					*/
/************************************************************************/

CREATE PROC [dbo].[tdc_gen_batch_no]	@batch_no varchar(13) OUTPUT, 
				@prefix varchar(4)

AS
	

/* make sure passed prefix is valid */		--don't know yet how to check it
/*if not exists (select * from tdc_batch_no_prefix where prefix = @prefix)
BEGIN
	return (-101)
END
*/

declare @cur_year 	varchar(2)	
declare @issue_date 	varchar(8)
declare @batch_seq_no 	int
declare @seq_no 	varchar(3)

SELECT @batch_seq_no = 0
SELECT @seq_no = ''
SELECT @batch_no = ''


-- get current date and modify into <mmddyy> format
SELECT @issue_date = CONVERT(varchar(8), getdate(), 12)
SELECT @cur_year = SUBSTRING(@issue_date, 1, 2)
SELECT @issue_date = SUBSTRING(@issue_date, 3, 4)
SELECT @issue_date = @issue_date + @cur_year


BEGIN TRAN

-- get last batch_no for this prefix+current_date 
IF EXISTS (SELECT * FROM tdc_next_batch_no
	WHERE issue_date = CONVERT(varchar(10), getdate(), 110) AND prefix = @prefix)
BEGIN 
	SELECT @batch_seq_no = max(batch_seq_no) FROM tdc_next_batch_no
		WHERE issue_date = CONVERT(varchar(10), getdate(), 110) AND prefix = @prefix
END

-- will starts from 1 if Prefix+current_date combination doesn't exists
SELECT @batch_seq_no = @batch_seq_no + 1

IF (@batch_seq_no < 10)
	SELECT @seq_no = '00' + CONVERT(varchar(1), @batch_seq_no)
ELSE IF (@batch_seq_no < 100)
	SELECT @seq_no = '0' + CONVERT(varchar(2), @batch_seq_no)
ELSE
	SELECT @seq_no =  CONVERT(varchar(3), @batch_seq_no)

SELECT @batch_no = @prefix + @issue_date + @seq_no

INSERT INTO tdc_next_batch_no (prefix, issue_date, batch_seq_no, batch_no)
VALUES (@prefix, CONVERT(varchar(10), getdate(), 110), @batch_seq_no, @batch_no)

COMMIT TRAN

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_gen_batch_no] TO [public]
GO
