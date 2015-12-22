SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE procedure [dbo].[imGenErr_sp] (
	@p_tablename		varchar(255),
    @p_errors_only_flag int = 0,
    @p_batchno          int = null,
    @p_start_rec        int = null,
    @p_end_rec          int = null,
    @p_debug_level      int = 0 )
as

declare @w_dnn          varchar(64)
declare @w_dControl     varchar(64)
declare @w_start         int
declare @w_end           int

select @w_dControl = 'CVO_Control'

select @w_dnn = DB_NAME(dbid) from master..sysprocesses where spid = @@SPID

if @p_batchno is not null
begin
    select @w_start = min(record_id_num) from iminvmast_vw where batch_no = @p_batchno
    if @w_start is null
    begin
        -- batch does not exist just get and empty record set
        exec master..xp_aeg_errors @p_tablename ,@w_dnn ,@w_dControl,@p_errors_only_flag,2,1
    end
    else
    begin
        -- get the end of the batch
        select @w_end = max(record_id_num) from iminvmast_vw where batch_no = @p_batchno

        if @p_start_rec is not null
        -- user has qualified a series of record within the batch
        begin
            if @p_start_rec > @w_start
            begin
                select @w_start = @p_start_rec
            end

            if @p_end_rec is not null
            -- has the user specified and end record
            begin
                if @p_end_rec < @w_end
                begin
                    select @w_end = @p_end_rec
                end
                exec master..xp_aeg_errors @p_tablename ,@w_dnn ,@w_dControl,@p_errors_only_flag,@w_start,@w_end
            end
            else
            begin
                -- user did not qualify an end record
                exec master..xp_aeg_errors @p_tablename ,@w_dnn ,@w_dControl,@p_errors_only_flag,@w_start
            end
        end
        else
        begin
            -- the start is null, user the start and end of the batch
            exec master..xp_aeg_errors @p_tablename ,@w_dnn ,@w_dControl,@p_errors_only_flag,@w_start,@w_end
        end

    end

end
else
begin
    if @p_end_rec is null
    begin
        if @p_start_rec is null
        begin
            exec master..xp_aeg_errors @p_tablename ,@w_dnn ,@w_dControl,@p_errors_only_flag
        end
        else
        begin
            exec master..xp_aeg_errors @p_tablename ,@w_dnn ,@w_dControl,@p_errors_only_flag,@p_start_rec
            --select @p_tablename,@w_dnn,@w_dControl,@p_errors_only_flag,@w_start,@w_end,@p_tablename,@p_batchno,@p_start_rec
        end
    end
    else
    begin
        -- end rec is not null
        if @p_start_rec is null
        begin
            -- problem, return an empty row set
            exec master..xp_aeg_errors @p_tablename ,@w_dnn ,@w_dControl,@p_errors_only_flag,2,1
        end
        else
        begin
            exec master..xp_aeg_errors @p_tablename ,@w_dnn ,@w_dControl,@p_errors_only_flag,@p_start_rec,@p_end_rec
        end
    end
end



if @p_debug_level > 0
begin
    select @p_tablename as tablename,
            @w_dnn      as companydatabase,
            @w_dControl as controldatabase,
            @p_errors_only_flag as errors_flag,
            @p_batchno  as batchno,
            @p_start_rec as startrec,
            @p_end_rec as endrec,
            @p_debug_level as debug
end



GO
GRANT EXECUTE ON  [dbo].[imGenErr_sp] TO [public]
GO
