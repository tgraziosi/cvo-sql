SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\APPCORE\PROCS\status.SPv - e7.2.2 : 1.4
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                

			
CREATE PROC [dbo].[status_sp]	@st_spname	char(20),
			@st_prckey	smallint,
			@st_userid	smallint,
			@st_message	char(255),
			@st_complete int,
			@st_origin	smallint,
			@st_error	smallint
AS



declare @message char(80)

SELECT	@message = @st_message

IF	@st_origin = 0 and @st_error = 0
	return

IF	( @st_origin = 0 and @st_error = 1 ) OR 
	( @st_origin = 1 and @st_error = 1)
BEGIN
	UPDATE	status
	SET	error_flag = 1, status = isnull(@message,'Null Message')
	WHERE	process_key = @st_prckey
	AND	user_id	 = @st_userid
	RETURN
END

IF	@st_origin = 1 and @st_error = 0
BEGIN
	UPDATE	status
	SET	completion = @st_complete, status = isnull(@message,'Null Message')
	WHERE	process_key = @st_prckey
	AND	user_id	 = @st_userid
END

RETURN





/**/                                              
GO
GRANT EXECUTE ON  [dbo].[status_sp] TO [public]
GO
