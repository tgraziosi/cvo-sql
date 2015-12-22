SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create proc [dbo].[adm_email_process] @from_user varchar(100),@email_type varchar(50), @parms varchar(1000)
as
set nocount on

declare @msg_dt datetime, @rc int
declare @parm_cnt int, @cnt int, @begin int, @parm_value varchar(255)

set @msg_dt = getdate()

if isnull(@parms,'') != ''
  if right(@parms,1) != ';'  set @parms = @parms + ';'

declare @cmd varchar(8000), @col_cnt int, @col_nm varchar(255)
declare @dtl_value varchar(7900)
declare @msg_inst_uid uniqueidentifier
declare @msg_uid uniqueidentifier

declare @dtl_flags varchar(10)
declare @fetch_data varchar(4000)
declare @tbl_name varchar(100)
declare @email_template_nm varchar(50)
declare @query varchar(7900)
declare @message1 varchar(8000)
declare @recipients1 varchar(7900)
declare @subject1 varchar(255)
declare @no_header1 varchar(10)
declare @attach_results1 varchar(10)
declare @width int, @sub_cnt int
declare @dbuse1 varchar(255)
declare @exp_days int

set @tbl_name = '##' + user_name() + '__'+ convert(varchar,@@spid) + '__mail_body'
set @cmd = 'if exists (select 1 from tempdb..sysobjects where name = ''' 
  + @tbl_name + ''') drop table ' + @tbl_name
exec (@cmd)

CREATE TABLE #local_data (c1 NVARCHAR(4000), msg_sect char(1), 
  row_id int identity(1,1)) 

set @cmd = 'CREATE TABLE ' + @tbl_name + '(c1 NVARCHAR(4000), 
msg_sect char(10), final_ind int, typ char(1), row_id int identity(1,1)) '
exec (@cmd)

DECLARE templ_cursor CURSOR LOCAL STATIC FOR
select email_template_nm, subject, 
  case when attach_results = 0 then 'false' else 'true' end 'attach_results',
  isnull(exp_days,30)
from adm_email_template (nolock)
where email_type = @email_type

OPEN templ_cursor

if @@cursor_rows > 0
begin
  set @msg_inst_uid = NEWID()

  FETCH NEXT FROM templ_cursor into @email_template_nm, @subject1, @attach_results1, @exp_days
  While @@FETCH_STATUS = 0
  begin

    set @width = 1
    set @no_header1 = 'true'
    set @msg_uid = NEWID()
    exec adm_email_insert_parm @parms, @subject1 OUT, @width

    select @query = dtl_value
    from adm_email_template_dtl 
    where email_template_nm = @email_template_nm and dtl_typ = 'query'

    truncate table #local_data

    set @cmd = 'truncate table ' + @tbl_name 
    exec (@cmd)

    exec @col_cnt = adm_email_setup_message '', @email_template_nm, @parms, @tbl_name, @width

    if exists (select 1 from adm_email_template_dtl 
    where email_template_nm =  @email_template_nm and 
      dtl_typ = 'query' and isnull(dtl_value,'') != '') and @col_cnt > 0
    begin
      set @fetch_data = ''
      select @fetch_data = @fetch_data + c1
      from #local_data where msg_sect = 'F'

      if exists (select 1 from #local_data where msg_sect = 'D')
        select @cmd = 'declare '
      select @cmd = @cmd + c1  
      from #local_data where msg_sect = 'D'
      if @cmd = 'declare ' select @cmd = ''

      select @cmd = @cmd + '
        declare @line varchar(7900), @sect varchar(10), @typ char(1)
        DECLARE t1cursor CURSOR LOCAL STATIC FOR'

      if exists (select 1 from #local_data where msg_sect = 'S')
        select @cmd = @cmd + ' SELECT ' 
        select @cmd = @cmd + c1
        from #local_data where msg_sect = 'S'

      DECLARE t1cursor CURSOR LOCAL STATIC FOR
      SELECT dtl_value
        from adm_email_template_dtl (nolock)
        where email_template_nm = @email_template_nm
        and dtl_typ = 'query' and isnull(dtl_value,'') != ''
        order by dtl_typ_seq_id

      OPEN t1cursor
 
      if @@cursor_rows > 0
      begin
        FETCH NEXT FROM t1cursor into @dtl_value
        While @@FETCH_STATUS = 0
        begin
          exec adm_email_insert_parm @parms, @dtl_value OUT, @width
          select @cmd = @cmd + '
	        ' + @dtl_value
          FETCH NEXT FROM t1cursor into @dtl_value
        end -- while
      end

      CLOSE t1cursor
      DEALLOCATE t1cursor

      select @cmd = @cmd + '
        OPEN t1cursor
 
        if @@cursor_rows > 0
        begin
          declare @first int
          set @first = 1

          FETCH NEXT FROM t1cursor into ' + @fetch_data + '
          While @@FETCH_STATUS = 0
          begin
            DECLARE t2cursor CURSOR LOCAL STATIC FOR
            select c1, convert(int,substring(msg_sect,1,1)), typ
            from ' + @tbl_name + ' where final_ind = 0 and
            (lower(msg_sect) like ''%detail%'' or msg_sect = '''' or @first = 1)
            order by row_id
            OPEN t2cursor

            if @@cursor_rows > 0
            begin
              FETCH NEXT FROM t2cursor into @line, @sect, @typ
              While @@FETCH_STATUS = 0
              begin
            ' 

                DECLARE t3cursor CURSOR LOCAL STATIC FOR
                SELECT c1
                from #local_data where msg_sect = 'R'
                order by row_id

                OPEN t3cursor

                if @@cursor_rows > 0
                begin
                  FETCH NEXT FROM t3cursor into @dtl_value
                  While @@FETCH_STATUS = 0
                  begin
                    select @cmd = @cmd + @dtl_value + '
	                  '
                    FETCH NEXT FROM t3cursor into @dtl_value
                  end -- while
                end

                CLOSE t3cursor
                DEALLOCATE t3cursor

                select @cmd = @cmd + '
   
                INSERT ' + @tbl_name + '(c1,msg_sect,final_ind,typ)
                select @line,@sect,1, @typ
              FETCH NEXT FROM t2cursor into @line,@sect, @typ
            end
          end
          close t2cursor
          deallocate t2cursor

          set @first = 0

          FETCH NEXT FROM t1cursor into ' + @fetch_data + '
        end -- while
      end

      CLOSE t1cursor
      DEALLOCATE t1cursor'

      exec (@cmd)
    end

    select @cmd = 'insert adm_message_dtl (message_id, dtl_typ, dtl_typ_seq_id, dtl_value)
      select ''' + convert(varchar(255),@msg_uid) + ''',''rtf_msg'',msg_sect * 100000 + row_id, c1
      from ' + @tbl_name + ' where final_ind = 1
      order by msg_sect,row_id'
    exec (@cmd)

    exec adm_email_format_message @msg_uid, @width OUT, @tbl_name


    select @cmd = 'insert adm_message_dtl (message_id, dtl_typ, dtl_typ_seq_id, dtl_value)
      select ''' + convert(varchar(255),@msg_uid) + ''',''tx_msg'',row_id, 
        left(c1,' + convert(varchar,@width) + ') 
      from ' + @tbl_name + ' where final_ind = 2 and typ = ''B'' order by row_id'
    exec (@cmd)

    if @width < 20 set @width = 20
    insert adm_message (message_id, message_instance_id, message_dt,
      email_template_nm, email_type, from_user, sent_ind, subject,
      link_tx, remind_dt, expire_dt, width, no_header, attach_results)
    select @msg_uid, @msg_inst_uid, @msg_dt,
      @email_template_nm, @email_type, @from_user, 0, @subject1, NULL, NULL, 
      case when @exp_days < 0 then NULL else dateadd(d, @exp_days, getdate()) end,
      @width, @no_header1, @attach_results1

    select @dbuse1 = db_name
    from ewcomp_vw e (nolock)
      join arco a (nolock) on a.company_id = e.company_id

    select @message1 = ''
    DECLARE t1cursor CURSOR LOCAL STATIC FOR
    SELECT dtl_value
      from adm_message_dtl (nolock)
      where message_id = @msg_uid and dtl_typ = 'message' 
    order by dtl_typ_seq_id

    OPEN t1cursor

    if @@cursor_rows > 0
    begin
      FETCH NEXT FROM t1cursor into @dtl_value
      While @@FETCH_STATUS = 0
      begin
        select @message1 = @message1 + @dtl_value + '
'
        FETCH NEXT FROM t1cursor into @dtl_value
      end -- while
    end

    CLOSE t1cursor
    DEALLOCATE t1cursor


    set @width = @width + 1
    set @recipients1 = ''
    set @cnt = 0
    DECLARE t1cursor CURSOR LOCAL STATIC FOR
    SELECT dtl_value
      from adm_email_template_dtl (nolock)
      where email_template_nm = @email_template_nm
      and dtl_typ = 'email' and isnull(dtl_value,'') != ''
      order by dtl_typ_seq_id

    OPEN t1cursor

    if @@cursor_rows > 0 
    begin
      While 1=1 
      begin
        FETCH NEXT FROM t1cursor into @dtl_value
        if @@fetch_status != 0 or
          datalength(@recipients1) + datalength(isnull(@dtl_value,'')) > 5000
        begin
          set @cnt = @cnt + 1
          insert adm_message_dtl (message_id, dtl_typ, dtl_typ_seq_id, dtl_value, sent_ind)
          select @msg_uid, 'email',@cnt, @dtl_value, 0

          set @recipients1 = ''

          if @@fetch_status != 0 break
        end

        set @recipients1 = @recipients1 + ';' + @dtl_value
      end -- while
    end

    CLOSE t1cursor
    DEALLOCATE t1cursor

    FETCH NEXT FROM templ_cursor into @email_template_nm, @subject1, @attach_results1, @exp_days
  end -- while
end

CLOSE templ_cursor
DEALLOCATE templ_cursor

exec adm_email_send '', @msg_inst_uid

set @cmd = 'if exists (select 1 from sysobjects where name = ''' + 
  @tbl_name + ''') drop table ' + @tbl_name
exec (@cmd)
GO
GRANT EXECUTE ON  [dbo].[adm_email_process] TO [public]
GO
