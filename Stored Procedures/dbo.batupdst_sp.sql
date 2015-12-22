SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\APPCORE\PROCS\batupdst.SPv - e7.2.2 : 1.4
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                









 



					 










































 




























































































































































































































































CREATE PROCEDURE [dbo].[batupdst_sp]
			@batch_code varchar(16),
			@batch_state smallint

AS 
BEGIN
	DECLARE @rows int,
		@err int,
		@process_user_name varchar( 30 ),
		@process_date int,
		@process_time int
		
	IF ( @batch_state NOT IN ( 0,
					-1,
					1,
					3,
					2,
					4,
					5 ) )
		RETURN -1
		
	IF ( @batch_state = 5 )
	BEGIN
		UPDATE batchctl
		SET hold_flag = 1,
			posted_flag = 0,
			completed_user = " ",
			completed_date = 0,
			completed_time = 0,
			selected_flag = 0,
			selected_user_id = 0
		WHERE batch_ctrl_num = @batch_code

		SELECT @err = @@error,
			@rows = @@rowcount

		IF ( @rows != 1 OR @err != 0 )
			RETURN -1
		
	END
	ELSE IF ( @batch_state = 1 )
	BEGIN
		SELECT @process_date = datediff(dd,'1/1/80',p.process_start_date)+722815,
			@process_time = datepart( hh, p.process_start_date ) * 360 +
					datepart( mm, p.process_start_date ) * 60 +
					datepart( ss, p.process_start_date ),
			@process_user_name = u.user_name
		FROM pcontrol_vw p, batchctl b, CVO_Control..smusers u
		WHERE b.batch_ctrl_num = @batch_code
		AND b.process_group_num = p.process_ctrl_num
		AND u.user_id = p.process_user_id
		
		IF ( @process_time IS NULL OR @process_date IS NULL OR @process_user_name IS NULL )
			RETURN -1
		
		UPDATE batchctl
		SET hold_flag = 0,
			posted_flag = 1,
			posted_user = @process_user_name,
			date_posted = @process_date,
			time_posted = @process_time
		WHERE batch_ctrl_num = @batch_code

		SELECT @err = @@error,
			@rows = @@rowcount

		IF ( @rows != 1 OR @err != 0 )
			RETURN -1
		
	END
	
	ELSE
	BEGIN
		UPDATE batchctl
		SET posted_flag = @batch_state
		WHERE batch_ctrl_num = @batch_code
		
		SELECT @err = @@error,
			@rows = @@rowcount

		IF ( @rows != 1 OR @err != 0 )
			RETURN -1
	END 

	RETURN 0
END


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[batupdst_sp] TO [public]
GO
