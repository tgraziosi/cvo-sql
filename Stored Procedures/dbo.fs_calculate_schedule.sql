SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




--  Copyright (c) 2001 Epicor Software, Inc. All Right Reserved.
CREATE PROCEDURE [dbo].[fs_calculate_schedule]
	(
	@sched_id	INT,
	@debug_file	VARCHAR(255) = NULL
	)
AS
BEGIN
DECLARE	@object		INT,
	@ole_code	INT,
	@solver_code	INT,
	@debug_code	INT,
	@message	VARCHAR(255),
	@source		VARCHAR(255),
	@description	VARCHAR(255),
	@dbname		sysname,
        @server_name    VARCHAR(255)

DECLARE @ctime datetime, @cmode char(1), @msg varchar(255), @csched varchar(16), -- mls 6/3/02 SCR 29025
  @cuser varchar(30)								 -- mls 6/3/02 SCR 29025
declare @schedn varchar(16),@schedname varchar(16)

SELECT @server_name = NULL


begin tran							-- mls 6/3/02 SCR 29025 start

select @ctime = solver_start_time,				
@cmode = upper(solver_mode),
@cuser = isnull(solver_start_user,'Someone'),
@schedn = sched_name
from sched_model SM where SM.sched_id = @sched_id

IF @@Rowcount = 0
BEGIN
	Rollback tran
	RaisError 69010 'Invalid model specified'
	RETURN
END

if @ctime is NOT NULL
begin
	select @msg = @cuser + ' is currently calculating this scenario '
	select @msg = @msg + case @cmode when 'L' then 'locally.' else 'remotely.' end
	select @msg = @msg + '  The solver started ' + convert(varchar(40),@ctime,100)
	Rollback tran
	RaisError 69012 @msg
	RETURN
end

select @ctime = NULL
set rowcount 1
select @ctime = solver_start_time,
@csched = sched_name,
@cuser = solver_start_user
from sched_model
where isnull(solver_mode,'') = 'R'
set rowcount 0

if @ctime is NOT NULL
begin
	select @msg = 'Scenario ' + @csched + ' is being calculated remotely by ' 
	select @msg = @msg + isnull(@cuser,'someone') + '.'
	select @msg = @msg + '  The solver started ' + convert(varchar(40),@ctime,100)
	Rollback tran
	RaisError 69011 @msg
	RETURN
end		

select @ctime = getdate(), @cuser = isnull(solver_start_user,left(suser_sname(),30))
from sched_model
where sched_id = @sched_id

update sched_model
set solver_start_time = @ctime, solver_mode = 'R',
  solver_start_user = @cuser 
where sched_id = @sched_id

COMMIT TRAN							-- mls 6/3/02 SCR 29025 end					


EXECUTE @ole_code = master.dbo.sp_OACreate 'FocusSoft.Schedule',@object OUT

IF @ole_code <> 0
	BEGIN
	RaisError 69099 'OLE automation server not installed'

	Goto sched_clear
	END

IF isnull(@debug_file,'') != ''					-- mls 1/14/03 SCR 30518
	BEGIN
	if (charindex('<scenario>',@debug_file) > 0)
        begin
          select @schedname = REPLACE(@schedn,' ','_')            
	  select @debug_file = REPLACE(@debug_file,'<scenario>',convert(varchar(10),@sched_id) + @schedname)
        end
end

IF isnull(@debug_file,'') != ''					-- mls 1/14/03 SCR 30518
BEGIN

	EXECUTE @ole_code = master.dbo.sp_OAMethod @object, 'DebugOpen', @debug_code OUT,@debug_file

	IF @ole_code <> 0 OR @debug_code = 0
		BEGIN
		RaisError 69098 'Unable to open requested debug file'
		EXECUTE @ole_code = master.dbo.sp_OADestroy @object

		Goto sched_clear
		END
	END

IF @ole_code = 0
        BEGIN
	
        SELECT @server_name = @@servername

	IF @server_name IS NOT NULL
            EXECUTE @ole_code = master.dbo.sp_OASetProperty @object,'ServerName', @server_name
        END

IF @ole_code = 0
	BEGIN
	SELECT	@dbname=db_name()
	EXECUTE @ole_code = master.dbo.sp_OASetProperty @object, 'DatabaseName', @dbname
	END

IF @ole_code = 0
	EXECUTE @ole_code = master.dbo.sp_OAMethod @object, 'Analyze', @solver_code OUT,@sched_id

IF @ole_code <> 0
	BEGIN
	EXECUTE @ole_code = master.dbo.sp_OAGetErrorInfo @object, @source OUT, @description OUT

	IF @ole_code = 0
		BEGIN
		SELECT @message='Source:      '+@source+Char(13)+'Description: '+@description
		RaisError 69097 @message
		END
	ELSE
		RaisError 69096 'Non-recoverable error occurred in schedule solver'

	Goto sched_clear
	END

IF isnull(@debug_file,'') != ''					-- mls 1/14/03 SCR 30518
	EXECUTE @ole_code = master.dbo.sp_OAMethod @object, 'DebugClose', @debug_code OUT
  
EXECUTE @ole_code = master.dbo.sp_OADestroy @object

IF @solver_code <> 0
BEGIN
	SELECT	@message='Error returned from schedule solver ('+CONVERT(VARCHAR(255),@solver_code)+')'
	RaisError 69095 @message
	RETURN
	END

--EXECUTE fs_check_schedule_status @sched_id=@sched_id 		-- mls 7/26/01

sched_clear:
update sched_model
set solver_start_time = NULL, solver_mode = NULL, solver_start_user = NULL
where sched_id = @sched_id
and upper(isnull(solver_mode,'')) = 'R' 
and isnull(solver_start_time,'1/1/1900') = @ctime
and isnull(solver_start_user,'') = @cuser			-- mls 6/3/02 SCR 29025 

END

GO
GRANT EXECUTE ON  [dbo].[fs_calculate_schedule] TO [public]
GO
