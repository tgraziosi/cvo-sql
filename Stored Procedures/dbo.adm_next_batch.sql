SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[adm_next_batch] 
  @process_description	varchar(40),
  @user			varchar(255) OUT,
  @process_parent_app	smallint,
  @online_call int = 0,
  @process_user_id int = NULL OUT,
  @company_code varchar(8) = NULL OUT,
  @process_ctrl_num varchar(16) OUT
AS
   declare @result 		int,
	   @process_type 	smallint,
	   @company_id		int

  select @process_type = 0

  if @company_code is NULL
  begin
    if @process_description like '% AR %'							-- mls 8/14/01 SCR 25959
      SELECT @company_id     = (SELECT company_id FROM arco (nolock) )
    else
      SELECT @company_id     = (SELECT company_id FROM apco (nolock) )				-- mls 2/16/01 SCR 25959

    SELECT @company_code = company_code 
      FROM glcomp_vw (nolock) WHERE company_id = @company_id
  end

  if @process_user_id is NULL
  begin
    SELECT @process_user_id  = user_id,
      @user = user_name
    FROM  glusers_vw (nolock) 
    WHERE lower(user_name) = lower(@user)

    IF @process_user_id is NULL  
      Select @process_user_id  = 1, @user = 'sa'
  END

  select @result = 1
  exec @result = pctrladd_sp	@process_ctrl_num OUTPUT,
				@process_description,
				@process_user_id,
				@process_parent_app,	
				@company_code,
				@process_type


  if @online_call = 1 
    select @result 'err_code', @process_ctrl_num 'batch'
  else
    return @result
GO
GRANT EXECUTE ON  [dbo].[adm_next_batch] TO [public]
GO
