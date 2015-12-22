SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\PROCS\apstlget.SPv - e7.2.2 : 1.0
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                









 



					 










































 



























































































































































































































































CREATE PROC [dbo].[apstlget_sp]
	@trx_ctrl_num	varchar(16)
AS
BEGIN

SELECT	ISNULL(settlement_ctrl_num,"")
FROM	apinppyt
WHERE	trx_ctrl_num = @trx_ctrl_num

END
GO
GRANT EXECUTE ON  [dbo].[apstlget_sp] TO [public]
GO
