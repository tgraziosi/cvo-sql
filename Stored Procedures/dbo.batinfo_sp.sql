SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\APPCORE\PROCS\batinfo.SPv - e7.2.2 : 1.1
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                















 



					 










































 







































































































































































































































































 




























CREATE PROCEDURE [dbo].[batinfo_sp]
		@batch_code varchar(16),
		@process_ctrl_num varchar(16) OUTPUT,
		@process_user_id smallint OUTPUT,
		@process_date int OUTPUT,
		@period_end int OUTPUT,
		@batch_type smallint OUTPUT

AS 
BEGIN
	DECLARE @start_date datetime,
		@date_applied int
	
	SELECT @process_ctrl_num = NULL,
		@process_user_id = NULL,
		@process_date = NULL,
		@period_end = NULL,
		@batch_type = NULL
	
	SELECT @process_ctrl_num = p.process_ctrl_num,
		@process_user_id = p.process_user_id,
		@start_date = p.process_start_date,
		@date_applied = b.date_applied,
		@batch_type = b.batch_type
	FROM batchctl b, pcontrol_vw p
	WHERE b.process_group_num = p.process_ctrl_num
	AND b.batch_ctrl_num = @batch_code
	
	IF ( @process_ctrl_num IS NULL )
		RETURN -1
	
	SELECT @process_date = datediff(dd,"1/1/80",@start_date)+722815
	
	SELECT @period_end = period_end_date
	FROM glprd
	WHERE @date_applied BETWEEN period_start_date AND period_end_date
	
	IF ( @period_end IS NULL )
	BEGIN
		SELECT @process_ctrl_num = NULL
		RETURN -1
	END
	
	RETURN 0
END


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[batinfo_sp] TO [public]
GO
