SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\APPCORE\PROCS\pctrlget.SPv - e7.2.2 : 1.1
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                

 








 



					 










































 




























































































































































































































































CREATE PROCEDURE [dbo].[pctrlget_sp] 
			@process_ctrl_num varchar(16),
			@process_state smallint OUTPUT,
			@process_user_id smallint OUTPUT,
			@process_parent_app integer OUTPUT,
			@process_parent_company varchar(8) OUTPUT
AS

BEGIN
	SELECT @process_state = NULL

	SELECT @process_state = process_state,
		@process_user_id = process_user_id,
		@process_parent_app = process_parent_app,
		@process_parent_company = process_parent_company
	FROM pcontrol_vw
	WHERE process_ctrl_num = @process_ctrl_num

	IF ( @process_state = NULL )
		RETURN -1

	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[pctrlget_sp] TO [public]
GO
