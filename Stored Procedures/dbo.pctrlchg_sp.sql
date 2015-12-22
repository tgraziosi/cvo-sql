SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\APPCORE\PROCS\pctrlchg.SPv - e7.2.2 : 1.1
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                










 



					 










































 




























































































































































































































































CREATE PROCEDURE	[dbo].[pctrlchg_sp]	
(
	@process_ctrl_num	varchar(16),	
	@process_type		smallint = NULL					
)
AS

BEGIN
	DECLARE	@process_server_id 	int,
			@process_kpid	 	int,
			@process_host_id	varchar(8)
					
	
	SELECT	@process_server_id 	= @@spid
	
	SELECT	@process_host_id 	= hostprocess,
			@process_kpid 		= kpid
	FROM	master..sysprocesses
	WHERE	spid 				= @@spid


	IF @process_type IS NULL
	BEGIN
		
		UPDATE	pcontrol_vw
		SET		process_server_id 	= @process_server_id,
				process_host_id	 	= @process_host_id,
				process_kpid 		= @process_kpid
		WHERE	process_ctrl_num 	= @process_ctrl_num
		
		RETURN	@@error
	END
	ELSE
	BEGIN
		
		UPDATE	pcontrol_vw
		SET		process_server_id 	= @process_server_id,
				process_host_id	 	= @process_host_id,
				process_kpid 		= @process_kpid,
				process_type		= @process_type
		WHERE	process_ctrl_num 	= @process_ctrl_num
		
		RETURN	@@error
	END

END
GO
GRANT EXECUTE ON  [dbo].[pctrlchg_sp] TO [public]
GO
