SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create proc [dbo].[adm_email_send] @email_type varchar(50) = '', @msg_inst_uid uniqueidentifier = NULL
as
set nocount on

declare @dbuse varchar(255),
  @message varchar(7900),
  @width int,
  @recipients varchar(7900),
  @curr_dt datetime,
  @msg_uid uniqueidentifier,
  @subject varchar(7900),
  @no_header varchar(10), 
  @attach_results varchar(10),
  @dtl_value varchar(7900),
  @rc int,
  @cmd varchar(7900),
  @seq_id int

set @curr_dt = getdate()
set @email_type = isnull(@email_type,'') + '%'

select @dbuse = db_name
from ewcomp_vw e (nolock)
join arco a (nolock) on a.company_id = e.company_id

if @msg_inst_uid is null
  DECLARE msg_cursor CURSOR LOCAL STATIC FOR
  SELECT message_id,  subject, width, no_header, attach_results
  from adm_message (nolock)
  where isnull(remind_dt,'1/1/1900') < @curr_dt and sent_ind = 0
    and email_type like @email_type 
else
  DECLARE msg_cursor CURSOR LOCAL STATIC FOR
  SELECT message_id,  subject, width, no_header, attach_results
  from adm_message (nolock)
  where isnull(remind_dt,'1/1/1900') < @curr_dt and sent_ind = 0
    and message_instance_id = @msg_inst_uid

OPEN msg_cursor

if @@cursor_rows > 0
begin
  while 1=1
  begin
    FETCH NEXT FROM msg_cursor into 
      @msg_uid, @subject, @width, @no_header, @attach_results
    if @@FETCH_STATUS != 0 break
    
    select @message = ''
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
        select @message = @message + @dtl_value + '
'
        FETCH NEXT FROM t1cursor into @dtl_value
      end -- while
    end

    CLOSE t1cursor
    DEALLOCATE t1cursor

    set @cmd = 'SELECT left(dtl_value,' + convert(varchar,@width) + ') FROM 
      adm_message_dtl where message_id = ''' + convert(varchar(255),@msg_uid) + '''
      and dtl_typ = ''tx_msg'' order by dtl_typ_seq_id'

    set @width = @width + 1
    set @recipients = ''

    DECLARE t1cursor CURSOR LOCAL STATIC FOR
    SELECT dtl_value, dtl_typ_seq_id
    from adm_message_dtl (nolock)
    where message_id = @msg_uid and dtl_typ = 'email' and sent_ind = 0
    order by dtl_typ_seq_id

    OPEN t1cursor

    if @@cursor_rows > 0 
    begin
      While 1=1 
      begin
        FETCH NEXT FROM t1cursor into @recipients, @seq_id
        if @@fetch_status != 0 break

        exec @rc = msdb..xp_sendmail 
          @no_output = 'true',
          @recipients =@recipients,
          @width=@width ,
          @query = @cmd,
          @subject = @subject,
          @no_header=@no_header,
          @attach_results = @attach_results,
          @dbuse = @dbuse,
          @message = @message

        if @rc = 0
        begin
          update adm_message_dtl
          set sent_ind = 1
          where message_id = @msg_uid and dtl_typ = 'email' and dtl_typ_seq_id = @seq_id
        end
      end -- while
    end

    CLOSE t1cursor
    DEALLOCATE t1cursor

    update adm_message
    set sent_ind = isnull((select min(sent_ind) from adm_message_dtl 
      where message_id = @msg_uid and dtl_typ = 'email'),1)
    where message_id = @msg_uid
    
  end -- while
end

CLOSE msg_cursor
DEALLOCATE msg_cursor

delete dtl
from adm_message msg, adm_message_dtl dtl
where msg.message_id = dtl.message_id and isnull(msg.expire_dt, dateadd(d,1,getdate())) < getdate()

delete msg
from adm_message msg
where isnull(msg.expire_dt, dateadd(d,1,getdate())) < getdate()

GO
GRANT EXECUTE ON  [dbo].[adm_email_send] TO [public]
GO
