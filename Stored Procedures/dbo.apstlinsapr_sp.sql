SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\PROCS\apstlinsapr.SPv - e7.2.3 : 1.0
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                









 



					 










































 





















































































































































































































































































CREATE PROC [dbo].[apstlinsapr_sp] (
	@settlement_ctrl_num 		varchar(16),
	@current_date			int,
	@debug_level			smallint = 0
)
AS
DECLARE	
	@trx_ctrl_num varchar(16)


CREATE TABLE #payments (
	trx_ctrl_num	varchar(16),
	processed	smallint)

INSERT 	#payments (
	trx_ctrl_num,
	processed)
SELECT 	trx_ctrl_num, 0
FROM	apinppyt
WHERE	trx_type=4111
AND	settlement_ctrl_num = @settlement_ctrl_num

WHILE (1=1)
BEGIN
	SET ROWCOUNT 1
	SELECT @trx_ctrl_num = trx_ctrl_num
	FROM	#payments
	WHERE	processed=0
	
	IF (@@ROWCOUNT = 0) BREAK

	SET ROWCOUNT 0

	EXEC apaprmk_sp 4111, @trx_ctrl_num, @current_date

	UPDATE #payments
	SET	processed=1
	WHERE	trx_ctrl_num = @trx_ctrl_num
	
END
SET ROWCOUNT 0
GO
GRANT EXECUTE ON  [dbo].[apstlinsapr_sp] TO [public]
GO
