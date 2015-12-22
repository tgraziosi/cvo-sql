SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\PROCS\apvouexp.SPv - e7.2.2 : 1.9
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                











 



					 










































 




























































































































































































































































CREATE PROC [dbo].[apvouexp_sp]	@item_code		varchar(30),
						@posting_code	varchar(8),
						@vendor_code	varchar(12),
						@location_code	varchar(8),
						@dr_memo_flag	smallint
AS

DECLARE	@exp_acct	varchar(32)
DECLARE  @current_org varchar(30)

SELECT	@exp_acct = NULL
SELECT @current_org =org_id 
	FROM smspiduser_vw
 WHERE spid = @@SPID

IF	@dr_memo_flag = 1
	BEGIN
		SELECT	@exp_acct = dbo.IBAcctMask_fn (purc_ret_acct_code,@current_org )
		FROM	apaccts
		WHERE	posting_code = @posting_code
	END
ELSE
	BEGIN
		SELECT	@exp_acct =  dbo.IBAcctMask_fn (exp_acct_code, @current_org)
		FROM	apvend
		WHERE	vendor_code = @vendor_code
	END


IF	(@exp_acct IS NULL OR @exp_acct NOT IN (SELECT account_code FROM InterBranchAccts))
	SELECT	'',''
ELSE
	SELECT	@exp_acct,(SELECT account_description FROM glchart where account_code = @exp_acct ) 


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[apvouexp_sp] TO [public]
GO
