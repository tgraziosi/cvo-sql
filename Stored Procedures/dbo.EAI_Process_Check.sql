SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


create procedure [dbo].[EAI_Process_Check]
as
begin

declare	@proc_vb_script varchar(100),
	@proc_data varchar(500),
	@proc_source_platform varchar(100),
	@proc_action integer,
	@entered_time datetime,
	@proc_deleted_flag char(1),
	@now_time datetime,
	@result integer,
	@aging_interval integer,
	@key_id decimal(20,9),
	@Sender varchar(32),
        @Process_OK integer

	if exists(select name from sysobjects where name = 'smcomp_vw')
		select @Sender = ddid from smcomp_vw
	else 
		select @Sender = ''

	select @now_time = current_timestamp

	select @aging_interval = convert(int, config_value) 
	from EAI_config where config_item = 'EAI_WAIT'
	select @aging_interval = IsNull(@aging_interval, 2)	-- if not set, wait for 2 minutes

	-- Select all EAI_process rows that are older than a given interval.
	-- Order them by ID
	DECLARE c_process_list CURSOR FOR
	Select 	vb_script,
		data,
		source_platform,
		action,
		deleted_flag,
		entered_time,
		key_id
	from EAI_process
	where (Datediff(mi, entered_time, @now_time) > @aging_interval)
	order by key_id

 
	OPEN c_process_list

	FETCH c_process_list INTO @proc_vb_script, @proc_data, @proc_source_platform, @proc_action, @proc_deleted_flag,
		@entered_time, @key_id

        WHILE @@Fetch_Status = 0 BEGIN

		select @proc_data = ltrim(rtrim(@proc_data))

		select @result = 0

		select @Process_OK = 1
		if @proc_vb_script = 'PartPrice' BEGIN
  			if exists(select data from EAI_process (nolock) where vb_script = 'Part' and left(data, charindex('|',data)-1) = substring(@proc_data, charindex('|',@proc_data)+1, len(@proc_data)-charindex('|',@proc_data)-(len(@proc_data)-charindex('|',@proc_data,charindex('|',@proc_data)+1)+1))) BEGIN
				select @Process_OK = 0
			END
		END

                if @Process_OK = 1  BEGIN
			if not @proc_data is NULL BEGIN
				exec @result = EAI_Send_sp @type = @proc_vb_script, @data = @proc_data, @source = @proc_source_platform,
					@action = @proc_action, @SenderID = @Sender
			END

			if @result = 0
				delete EAI_process where key_id = @key_id
		END

		fetch c_process_list INTO @proc_vb_script, @proc_data, @proc_source_platform, @proc_action,
			@proc_deleted_flag, @entered_time, @key_id

	END -- end of while loop

	CLOSE c_process_list

	DEALLOCATE c_process_list

end
GO
GRANT EXECUTE ON  [dbo].[EAI_Process_Check] TO [public]
GO
