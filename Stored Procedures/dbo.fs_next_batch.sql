SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_next_batch] @process_description	varchar(40),
			@user			varchar(30),
			@process_parent_app	smallint

AS
   declare @result 		int,
	   @process_type 	smallint,
	   @process_ctrl_num	varchar(16),
	   @process_user_id	int,
	   @company_code	varchar(8),
	   @company_id		int

   select @process_type = 0

   if @process_description like '% AR %'							-- mls 8/14/01 SCR 25959
   begin
     SELECT @company_id     = (SELECT company_id FROM arco (nolock) )
   end
   else
   begin
     SELECT @company_id     = (SELECT company_id FROM apco (nolock) )				-- mls 2/16/01 SCR 25959
   end

   SELECT @company_code   = (SELECT company_code 
				FROM glcomp_vw (nolock) 
				WHERE company_id = @company_id)
   SELECT @process_user_id  = user_id
    FROM  glusers_vw (nolock) 
    WHERE lower(user_name) = lower(@user)


   IF @process_user_id is NULL  
    BEGIN
      
      Select @process_user_id  = 1
      END

   select @result = 1

   exec @result = pctrladd_sp	@process_ctrl_num OUTPUT,
				@process_description,
				@process_user_id,
				@process_parent_app,	
				@company_code,
				@process_type


select @result 'err_code', @process_ctrl_num 'batch'
GO
GRANT EXECUTE ON  [dbo].[fs_next_batch] TO [public]
GO
