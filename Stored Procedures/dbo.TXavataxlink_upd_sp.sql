SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[TXavataxlink_upd_sp] @trx_ctrl_num varchar(16), @trx_type int, 
@upd_mode varchar(10), @err_msg varchar(255) output, @debug int = 0
as 
set nocount on

-- Scratch variables used in the script
DECLARE @retVal 	INT,
  @comHandle 		INT,
  @errorSource 		VARCHAR(8000),
  @errorDescription 	VARCHAR(8000),
  @retString 		VARCHAR(100),
  @l_url 		varchar(900), 
  @l_viaurl 		varchar(900), 
  @l_username 		varchar(50), 
  @l_password 		varchar(50),
  @l_company_id 	int,
  @l_requesttimeout 	int,
  @result_code 		int,
  @docId 		bigint,
  @docState 		int,
  @cancelCode 		int

  select @docId = remote_doc_id,
    @docState = remote_state
  from gltcrecon (nolock)
  where trx_ctrl_num = @trx_ctrl_num and trx_type = @trx_type

  if @@rowcount = 0
  begin
    set @err_msg = 'Could not find record on gltcrecon table.'
    return 100
  end

if upper(@upd_mode) = 'DELETE'
begin
  if @docState > 1
  begin
    set @err_msg = 'Cannot delete tax transaction because it is already posted.'
    return -10
  end
end

-- Initialize the COM component. fsavataxlink.TaxStatus
EXEC @retVal = sp_OACreate '{6F6333B1-E000-4C0F-BD2A-02AA04A8BB1D}', @comHandle OUTPUT, 4
IF (@retVal <> 0) goto Exit_Bad

select @l_company_id = company_id from arco (nolock)

-- get the tax configuration data
select @l_url = url, 
  @l_viaurl = viaurl,
  @l_username = username,
  @l_password = password,
  @l_requesttimeout = requesttimeout
from gltcconfig (nolock)
where company_id = @l_company_id

-- Initialize the COM component.
EXEC @retVal = sp_OAMethod @comHandle, 'fSetConfig', @retString OUTPUT, 
  @a_url = @l_url, @a_viaurl = @l_viaurl, @a_username = @l_username, 
  @a_password = @l_password, @a_requesttimeout = @l_requesttimeout
IF (@retVal <> 0) goto Exit_Bad

if upper(@upd_mode) in ( 'CANCEL', 'DELETE')
begin
  -- Call a method into the component
  select @cancelCode = case @docState 
    when 1 then 2 -- save state - docdeleted cancel code
    when 2 then 1 -- post state - postfailed cancel code
    when 3 then 2 -- committed state - docdeleted cancel code
    else 0
  end 

  if @cancelCode = 0
  begin
    set @err_msg = 'Remote State not saved, posted or committed'
    return 101
  end

  if @debug > 0 print 'CancelTaxByDocId'
  EXEC @retVal = sp_OAMethod @comHandle, 'CancelTaxByDocId',  @retString OUTPUT,
    @DocId = @docId, @intCancelCode = @cancelCode
  IF (@retVal <> 0) goto Exit_Bad

  -- Call a method into the component
  if @debug > 0 print 'getresultcode'
  EXEC @retVal = sp_OAMethod @comHandle, 'get_ResultCode', @retString OUTPUT

  IF (@retVal <> 0) goto Exit_Bad
  select @result_code = convert(int, @retString)

  EXEC @retVal = sp_OAMethod @comHandle, 'get_ResultCodeDesc', @retString OUTPUT

  IF (@retVal <> 0) goto Exit_Bad

  -- Print the value returned from the method call
  if @debug > 0 SELECT 'Return Code '+ @retString

  IF @retString in ( 'Error','Exception') or @result_code in (2,3)
  begin
    -- Call a method into the component
    EXEC @retVal = sp_OAMethod @comHandle, 'get_ResultMessages', @retString OUTPUT
    IF (@retVal <> 0) goto Exit_Bad

    if @debug > 0
    SELECT 'Error Message: '+@retString

    While ascii(left(@retString,1)) < 32 and datalength(@retString) > 0
    begin
      select @retString = substring(@retString,2,255)
    end
    select @err_msg = @retString
    return -1
  end
end

  -- Release the reference to the COM object
EXEC sp_OADestroy @comHandle

  if @docState = 1	-- saved
  begin
    delete from gltcrecon
    where trx_ctrl_num = @trx_ctrl_num and trx_type = @trx_type
    and remote_doc_id = @docId
  end
  if @docState = 2	-- posted
  begin
    update gltcrecon
    set remote_state = 1 -- saved
    where trx_ctrl_num = @trx_ctrl_num and trx_type = @trx_type
    and remote_doc_id = @docId
  end
  if @docState = 3	-- committed
  begin
    update gltcrecon
    set remote_state = 4 -- cancelled
    where trx_ctrl_num = @trx_ctrl_num and trx_type = @trx_type
    and remote_doc_id = @docId
  end

set @retVal = 1
set @err_msg = 'Tax cancelled successfully.'
goto Exit_Good

Exit_Bad:
	-- Trap errors if any
	EXEC sp_OAGetErrorInfo @comHandle, @errorSource OUTPUT, @errorDescription OUTPUT
	if @debug > 0
	SELECT [Error Source] = @errorSource, [Description] = @errorDescription

	select @err_msg = @errorSource
    set @retVal = -1

Exit_Good:
	RETURN @retVal

GO
GRANT EXECUTE ON  [dbo].[TXavataxlink_upd_sp] TO [public]
GO
