SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                


























































































  



					  

























































 

































































































































































































































































































CREATE  PROCEDURE       [dbo].[batupdst_grp_sp]
			@batch_code             varchar(16),
			@batch_state            smallint

AS 
BEGIN
	DECLARE @rows                   int,
		@err                    int,
		@process_user_name      varchar( 30 ),
		@process_date           int,
		@process_time           int
		
	IF ( @batch_state NOT IN (      0,
					-1,
					1,
					3,
					2,
					4,
					5 ) )
		RETURN  -1
		
	IF ( @batch_state = 5 )
	BEGIN
		UPDATE  BAT
		SET     BAT.hold_flag = 1,
			BAT.posted_flag = 0,
			BAT.completed_user = " ",
			BAT.completed_date = 0,
			BAT.completed_time = 0,
			BAT.selected_flag = 0,
			BAT.selected_user_id = 0
		FROM batchctl BAT
			INNER JOIN #Group_batch GRP ON BAT.batch_ctrl_num = GRP.batch_ctrl_num
		WHERE GRP.batch_ctrl_num_group = @batch_code	


		SELECT  @err = @@error,
			@rows = @@rowcount

		IF ( @rows != 1 OR @err != 0 )
			RETURN -1
		
	END
	ELSE IF ( @batch_state = 1 )
	BEGIN

		CREATE TABLE #TEMP(
			key_table INTEGER IDENTITY (1,1),
			batch_ctrl_num_group char(16), 
			process_group_num varchar(16), 
			batch_ctrl_num char(16))

		INSERT INTO #TEMP (batch_ctrl_num_group, process_group_num, batch_ctrl_num)
		SELECT batch_ctrl_num_group, process_group_num, batch_ctrl_num
		FROM #Group_batch
		WHERE batch_ctrl_num_group = @batch_code

		
		DECLARE @key_table INT
		SET @key_table = 0

		SELECT  @key_table = MIN(key_table)
		FROM    #TEMP
		WHERE   key_table > @key_table

		WHILE @key_table IS NOT NULL
		BEGIN
			SELECT  @process_date = datediff(dd,'1/1/80',p.process_start_date)+722815,
				@process_time = datepart( hh, p.process_start_date ) * 360 +
						datepart( mm, p.process_start_date ) * 60 +
						datepart( ss, p.process_start_date ),
				@process_user_name = u.user_name
			FROM    pcontrol_vw p
				INNER JOIN batchctl b ON p.process_ctrl_num = b.process_group_num
				INNER JOIN #TEMP GRP ON b.batch_ctrl_num = GRP.batch_ctrl_num
				INNER JOIN CVO_Control..smusers u ON p.process_user_id = u.user_id
			WHERE   GRP.key_table = @key_table

			IF ( @process_time IS NULL OR @process_date IS NULL OR @process_user_name IS NULL )
				RETURN  -1
			
			UPDATE BAT
			SET BAT.hold_flag = 0,
				BAT.posted_flag = 1,
				BAT.posted_user = @process_user_name,
				BAT.date_posted = @process_date,
				BAT.time_posted = @process_time
			FROM batchctl BAT
				INNER JOIN #TEMP GRP ON BAT.batch_ctrl_num = GRP.batch_ctrl_num
			WHERE   GRP.key_table = @key_table	

			SELECT  @err = @@error,
				@rows = @@rowcount

			IF ( @rows != 1 OR @err != 0 )
				BREAK

			SELECT  @key_table = MIN(key_table)
			FROM    #TEMP
			WHERE   key_table > @key_table

		END
		
		DROP TABLE #TEMP

	END
	
	ELSE
	BEGIN
		UPDATE BAT
		SET BAT.posted_flag = @batch_state
		FROM batchctl BAT
			INNER JOIN #Group_batch GRP ON BAT.batch_ctrl_num = GRP.batch_ctrl_num
		WHERE GRP.batch_ctrl_num_group = @batch_code

		SELECT  @err = @@error,
			@rows = @@rowcount

		IF ( @rows != 1 OR @err != 0 )
			RETURN -1
	END             

	RETURN 0
END
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[batupdst_grp_sp] TO [public]
GO
