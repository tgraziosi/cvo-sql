SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\PROCS\arglvco.SPv - e7.2.2 : 1.9
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                



CREATE PROC [dbo].[arglvco_sp] 
 @c_proc_key int,
 @posting_code char(8),
 @sub_account_code char(32),
 @apply_date int,
 @save_info smallint
AS
DECLARE	
 @account_code char(32),
 @test char(80),
 @active_date int,
 @inactive_date int,
 @inactive_flag int,
 @not_exist_flag smallint,
 @not_active_flag smallint,
 @not_valid_on_date_flag smallint


SELECT
 @not_exist_flag = 0,
 @not_active_flag = 0,
 @not_valid_on_date_flag = 0



SELECT @not_active_flag=inactive_flag,
 @not_valid_on_date_flag=invalid_flag
FROM aractst
WHERE posting_code=@posting_code 
 AND account_code=@sub_account_code
 AND date=@apply_date
 AND proc_key = @c_proc_key

IF (@@rowcount=1)
 RETURN @not_active_flag+@not_valid_on_date_flag
ELSE
BEGIN

 SELECT @not_active_flag=inactive_flag,
 @not_valid_on_date_flag=invalid_flag
 FROM aractst
 WHERE account_code=@sub_account_code
 AND date=@apply_date
 AND proc_key = @c_proc_key

 IF (@@rowcount=1)
 BEGIN
 INSERT aractst(proc_key, posting_code,account_code,inactive_flag,invalid_flag,date)
 VALUES (@c_proc_key, @posting_code,@sub_account_code,@not_active_flag,@not_valid_on_date_flag,@apply_date)
 RETURN @not_active_flag+@not_valid_on_date_flag
 END
END

WHILE ( 1 = 1 )
BEGIN

 SELECT
 @account_code = account_code,
 @active_date = active_date,
 @inactive_date = inactive_date,
 @inactive_flag = inactive_flag
 FROM glchart
 WHERE account_code = @sub_account_code

 IF (@@rowcount=0)
 BEGIN
 SELECT @not_exist_flag = 1
 BREAK
 END


 IF (@inactive_flag=1) 
 BEGIN
 SELECT @not_active_flag=1
 BREAK
 END

 IF ((@active_date=0) AND (@inactive_date=0)) BREAK


 IF ((@active_date !=0) AND (@inactive_date = 0))
 BEGIN
 IF (@apply_date >= @active_date)
 BREAK
 ELSE
 BEGIN
 SELECT @not_valid_on_date_flag = 1
 BREAK
 END
 END

 IF (@inactive_date != 0)
 BEGIN
 IF (@apply_date BETWEEN @active_date AND @inactive_date)
 BREAK
 ELSE
 BEGIN
 SELECT @not_valid_on_date_flag = 1
 BREAK
 END
 END

 BREAK

END

IF (@save_info=1) AND (@not_exist_flag=0)
 INSERT aractst(proc_key, posting_code,account_code,inactive_flag,invalid_flag,date)
 VALUES ( @c_proc_key, @posting_code,@sub_account_code,@not_active_flag,@not_valid_on_date_flag,@apply_date)

RETURN @not_exist_flag+@not_active_flag+@not_valid_on_date_flag



/**/                                              
GO
GRANT EXECUTE ON  [dbo].[arglvco_sp] TO [public]
GO
