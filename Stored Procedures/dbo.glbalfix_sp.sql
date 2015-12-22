SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\GL\PROCS\glbalfix.SPv - e7.2.2 : 1.0
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                



CREATE PROCEDURE [dbo].[glbalfix_sp] 
			@juldate	int = 0
AS
BEGIN
DECLARE @tjuldate int

IF (@juldate = 0)
BEGIN 
	SELECT "Syntax : glbalfix_sp <julian period end date for period containing data corruption>"
	RETURN 
END

IF (@juldate < 726468 )
BEGIN
	SELECT "Please enter the valid date. Valid date range is 01/01/1990 - today's date."
	RETURN
END

exec appdate_sp @tjuldate OUTPUT

IF (@juldate > @tjuldate)
BEGIN
	SELECT "Please enter the valid date. Valid date range is 01/01/1990 - today's date."
	RETURN
END

DELETE glbal WHERE balance_date >= @juldate

UPDATE gltrx
SET	recurring_flag = 0, repeating_flag = 0, reversing_flag = 0,
	intercompany_flag = 0
WHERE	posted_flag = 1
AND	date_applied >= @juldate

UPDATE	batchctl
SET 	posted_flag = 0, date_posted = 0,
	time_posted = 0, posted_user = "",
	process_group_num = ""
WHERE	batch_ctrl_num IN (SELECT batch_code
			 FROM	gltrx
			 WHERE posted_flag = 1
			 AND	date_applied >= @juldate)

UPDATE	gltrxdet
SET	posted_flag = 0, date_posted = 0
WHERE	posted_flag = 1
AND	journal_ctrl_num IN (SELECT journal_ctrl_num 
			 FROM gltrx
			 WHERE posted_flag = 1
			 AND date_applied >= @juldate)

UPDATE	gltrx 
SET	posted_flag = 0, date_posted = 0, process_group_num = ""
WHERE	posted_flag = 1
AND	date_applied >= @juldate

EXEC	glbalchk_sp "repair"

END
GO
GRANT EXECUTE ON  [dbo].[glbalfix_sp] TO [public]
GO
