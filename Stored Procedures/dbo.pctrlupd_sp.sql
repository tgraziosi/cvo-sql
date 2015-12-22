SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\APPCORE\PROCS\pctrlupd.SPv - e7.2.2 : 1.1
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                

 








 



					 










































 




























































































































































































































































CREATE PROCEDURE	[dbo].[pctrlupd_sp]	
			@process_ctrl_num	varchar(16),
			@process_state		smallint

AS

BEGIN
	DECLARE	@process_end_date	datetime
	
	IF NOT EXISTS(	SELECT	*
			FROM	pcontrol_vw
			WHERE	process_ctrl_num = @process_ctrl_num )
		RETURN	-1
	
	IF ( ( @process_state = 3 ) or
		( @process_state = 2 ) or
		( @process_state = 5 ) )
	BEGIN
		UPDATE	pcontrol_vw
		SET	process_state = @process_state,
			process_end_date = getdate()
		WHERE	process_ctrl_num = @process_ctrl_num
	END
	
	ELSE 
	BEGIN
		UPDATE	pcontrol_vw
		SET	process_state = @process_state
		WHERE	process_ctrl_num = @process_ctrl_num

	END
	
	RETURN	0
END
GO
GRANT EXECUTE ON  [dbo].[pctrlupd_sp] TO [public]
GO
