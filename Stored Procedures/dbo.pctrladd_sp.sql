SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\APPCORE\PROCS\pctrladd.SPv - e7.2.2 : 1.5
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                










 



					 










































 




























































































































































































































































CREATE PROCEDURE [dbo].[pctrladd_sp] 
			@process_ctrl_num varchar(16) OUTPUT,
			@process_description varchar(40),
			@process_user_id smallint,
			@process_parent_app int,
			@process_parent_company varchar(8),
			@process_type smallint = 0

AS
-- 05/10/2004 Cyanez To support Extende AppIDs, @process_parent_app parameter type changed from  smallint to int, 

BEGIN
	DECLARE @process_server_id int,
		@process_kpid int,
		@process_host_id varchar(8),
		@process_start_date datetime,
		@process_num int,
		@process_mask varchar(16),
		@result int
		
	SELECT @process_server_id = @@spid
	
	SELECT @process_host_id = hostprocess,
		@process_kpid = kpid,
		@process_start_date = login_time
	FROM master..sysprocesses
	WHERE spid = @@spid
					
	BEGIN TRAN

	WHILE 1=1
	BEGIN
		
		UPDATE pctrlnum_vw
		SET process_num = process_num + 1
		
		IF ( @@error != 0 )
		BEGIN
			SELECT @result = -1
			goto ROLLBACK_TRAN
		END

		SELECT @process_num = process_num - 1,
			@process_mask = process_mask
		FROM pctrlnum_vw
		
		IF ( @process_num IS NULL OR @process_mask IS NULL )
		BEGIN
			SELECT @result = -1
			goto ROLLBACK_TRAN
		END

		EXEC fmtctlnm_sp @process_num, 
					@process_mask, 
					@process_ctrl_num OUTPUT, 
					@result OUTPUT
		IF ( @result != 0 )
		BEGIN
			SELECT @result = -1
			goto ROLLBACK_TRAN
		END

		
		IF EXISTS( SELECT *
				FROM pcontrol_vw
				WHERE process_ctrl_num = @process_ctrl_num )
		BEGIN
			CONTINUE
		END

		ELSE
		BEGIN

			INSERT pcontrol_vw (
				process_ctrl_num,
				process_parent_app,
				process_parent_company,
				process_description,
				process_user_id,
				process_server_id,
				process_host_id,
				process_kpid,
				process_start_date,
				process_end_date,
				process_state,
				process_type )
			SELECT @process_ctrl_num,
				@process_parent_app,
				@process_parent_company,
				@process_description,
				@process_user_id,
				@process_server_id,
				@process_host_id,
				@process_kpid,
				@process_start_date,
				NULL,
				1,
				@process_type

			break
		END
	END

	COMMIT TRAN
	
	RETURN 0

	ROLLBACK_TRAN:
	ROLLBACK TRAN
	RETURN @result
END
GO
GRANT EXECUTE ON  [dbo].[pctrladd_sp] TO [public]
GO
