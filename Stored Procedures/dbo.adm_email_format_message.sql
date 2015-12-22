SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create proc [dbo].[adm_email_format_message] @msg_uid uniqueidentifier, @width int OUT, @tbl_name varchar(100)
as
declare @email_type varchar(50)
declare @dtl_typ_seq_id int
declare @msg_txt varchar(7900)
declare @msg_line varchar(3000)
declare @end_of_msg int
declare @cmd varchar(7900)
--set @email_type = 'Procurement Transfer'
declare @TwipPerInch decimal(20,8), @CharPerInch decimal(20,8),
  @pg_w decimal(20,8), @pg_h decimal(20,8), @pg_ml decimal(20,8), 
  @pg_mr decimal(20,8), @pg_mt decimal(20,8), @pg_mb decimal(20,8), 
  @pg_tab decimal(20,8), @p_align char(1), @p_li decimal(20,8), 
  @p_fi decimal(20,8), @p_ri decimal(20,8),@p_tb varchar(1000),
  @p_w int, @line varchar(200),
  @atab char(1), @atab_pos int

set @TwipPerInch = 1440
set @CharPerInch = 12

declare @ntab char(255), @rc int
declare @lcnt int , @sec_st_pos int
declare @sec varchar(7900), @cnt int, @txt_section int
declare @cword varchar(255)
declare @lpos int, @epos int, @tpos int, @spos int, @level int
declare @skip_lf int, @typ char(1)

set @line = ''
set @lcnt = 0
set @end_of_msg = 0
set @txt_section = 0
set @msg_txt = ''
set @sec_st_pos = 1
set @level = 0
set @skip_lf = 0
select @p_align = 'L', @p_li = 0, @p_fi = 0, @p_ri = 0, @p_tb = '',
  @p_w = @pg_w - @pg_ml - @pg_mr
set @atab = ''
set @ntab = 'L'
set @typ = ''

set @dtl_typ_seq_id = 0

DECLARE t3cursor CURSOR LOCAL STATIC FOR
select dtl_value, dtl_typ_seq_id
from adm_message_dtl 
where message_id = @msg_uid 
and dtl_typ = 'rtf_msg'
order by dtl_typ_seq_id

OPEN t3cursor

if @@cursor_rows > 0
begin
  while 1=1
  begin
    if @end_of_msg = 1 and @msg_txt = '' break
    if @end_of_msg = 0 and datalength(@msg_txt) < 4000
    begin
      FETCH NEXT FROM t3cursor into @msg_line, @dtl_typ_seq_id
      if @@FETCH_STATUS != 0 
        set @end_of_msg = 1
      else
      begin
        if left(@msg_line,8) in ('_header_','_detail_','_footer_')
          select @msg_line = ' ' + @msg_line
        if left(@msg_line,9) in ('_message_')
          select @msg_line = ' ' + @msg_line
        set @msg_txt = @msg_txt + @msg_line
      end
    end

  if @msg_txt = '' continue

  select @sec_st_pos = charindex('{',@msg_txt)
  if @sec_st_pos != 1 and @level > 1  break

  if @sec_st_pos = 1
  begin
    set @level = @level + 1
    select @msg_txt = substring(@msg_txt,2,datalength(@msg_txt))
  end
  exec @rc = adm_email_get_next_cword @email_type, @dtl_typ_seq_id,
    @msg_txt OUT, @cword OUT

  while @rc = 1
  begin
    if @cword like '\paperw%' 
    begin 
      set @pg_w = convert(dec,substring(@cword,8,datalength(@cword))) / @TwipPerInch * @CharPerInch
      if @pg_w > @width set @width = @pg_w
    end
    if @cword like '\paperh%' set @pg_h = convert(int,substring(@cword,8,datalength(@cword)))
    if @cword like '\margl%' set @pg_ml = convert(int,substring(@cword,7,datalength(@cword))) / @TwipPerInch * @CharPerInch
    if @cword like '\margr%' set @pg_mr = convert(int,substring(@cword,7,datalength(@cword)))
    if @cword like '\margt%' set @pg_mt = convert(int,substring(@cword,7,datalength(@cword)))
    if @cword like '\margb%' set @pg_mb = convert(int,substring(@cword,7,datalength(@cword)))
    if @cword like '\deftab%' set @pg_tab = convert(int,substring(@cword,8,datalength(@cword)))/ @TwipPerInch * @CharPerInch
    if @cword like '\pard' 
    begin
      select @txt_section = 1
      select @p_align = 'L', @p_li = 0, @p_fi = 0, @p_ri = 0, @p_tb = '',
        @p_w = @pg_w - @pg_ml - @pg_mr
      select @atab = '', @ntab = 'L'
      set @skip_lf = 0
    end
    if @cword like '\ql' set @p_align = 'L'
    if @cword like '\li%' set @p_li = convert(int,substring(@cword,4,datalength(@cword))) / @TwipPerInch * @CharPerInch
    if @cword like '\fi%' set @p_fi = convert(int,substring(@cword,4,datalength(@cword))) / @TwipPerInch * @CharPerInch
    if @cword like '\tql' set @ntab = 'L'
    if @cword like '\tqc' set @ntab = 'C'
    if @cword like '\tqr' set @ntab = 'R'
    if @cword like '\tx%' 
    begin
      set @tpos = convert(int,substring(@cword,4,datalength(@cword))) /@TwipPerInch * @CharPerInch
      if datalength(@p_tb) < @tpos select @p_tb = @p_tb + replicate(' ', @tpos - datalength(@p_tb))
      select @p_tb = substring(@p_tb,1,@tpos -1) + @ntab + substring(@p_tb, @tpos + 1, datalength(@tpos))     
      set @ntab = 'L'
    end
    if @cword like '\ri%' set @p_ri = convert(int,substring(@cword,4,datalength(@cword)))  / @TwipPerInch * @CharPerInch
    if @cword = '\par'
    begin
        set @cmd = 'insert ' + @tbl_name + '(c1,final_ind, typ)
        values (left(''' + @line + ''',' + convert(varchar,@width) + '),2,''' + @typ + ''')'
        exec (@cmd)
--        print @line
        select @line = ''
    end
    if @cword = '\tab'
    begin
      if @atab != ''
        exec adm_email_apply_tab @atab out, @atab_pos, @sec, @line out

      select @ntab = rtrim(ltrim(substring(@p_tb,datalength(@line) +1,datalength(@p_tb))))
	  if @ntab != ''
      begin
        select @atab = left(@ntab,1)
        select @atab_pos = charindex(@atab,@p_tb,datalength(@line)+1)
      end
      else
      begin
        select @atab = 'L'
        select @atab_pos = ceiling(convert(decimal(20,8),datalength(@line)) / @pg_tab) * @pg_tab
        if @atab_pos <= (datalength(@line) + 1)
          select @atab_pos = @atab_pos + @pg_tab
      end
    end
    exec @rc = adm_email_get_next_cword @email_type, @dtl_typ_seq_id,
      @msg_txt OUT, @cword OUT

    if @rc != 1
    begin
      if left(@msg_txt,9) in ('_header_}','_detail_}','_footer_}')
        or left(@msg_txt,10) in ('_message_}')
      begin
        if left(@msg_txt,9) in ('_header_}','_detail_}','_footer_}')
          set @typ = 'B'
        else
          set @typ = 'M'
        set @msg_txt = substring(@msg_txt,10,datalength(@msg_txt))
        set @level = @level - 1
        if left(@msg_txt,6) = '{\par}'
          set @msg_txt = substring(@msg_txt,7,datalength(@msg_txt))
        exec @rc = adm_email_get_next_cword @email_type, @dtl_typ_seq_id,
          @msg_txt OUT, @cword OUT
      end
    end
  end -- getting command words

  if @p_fi > @p_w set @p_fi = (@p_fi * @TwipPerInch / @CharPerInch - 65536) / @TwipPerInch * @CharPerInch

  if left(@msg_txt,1) != '{'
  begin
    while 1 = 1
    begin
      set @epos = 0
      while 1 = 1
      begin
        set @epos = charindex('}',@msg_txt,@epos)
        if @epos = 0 break
    
        if substring(@msg_txt,@epos -1, 1) != '\'  break
        set @epos = @epos + 1
      end
  
      select @sec = ' '
      if @txt_section = 1 and @epos > 1
      begin
        if @line = ''
          select @line = replicate(' ',@p_li + @p_fi)

        if @epos = 0
          select @sec = @msg_txt 
        else
          select @sec = left(@msg_txt,@epos -1)
        set @sec = replace(@sec,'\{','{')
        set @sec = replace(@sec,'\}','}')
        set @sec = replace(@sec,'\\','\')
--	  end
--      if @txt_section = 1
 --     begin
      exec adm_email_apply_tab @atab out, @atab_pos, @sec, @line out
      end
      set @msg_txt = substring(@msg_txt,@epos +1,datalength(@msg_txt))
      set @level = @level -1
      if left(@msg_txt,1) != '}' break    
    end
  end

  end -- while
end

CLOSE t3cursor
DEALLOCATE t3cursor

set @cmd = 'insert ' + @tbl_name + '(c1,final_ind,typ)
        values (left(''' + @line + ''',' + convert(varchar,@width) + '),2,''' + @typ + ''')'
exec (@cmd)

set @cmd = 'insert adm_message_dtl (message_id,dtl_typ_seq_id,dtl_typ,dtl_value)
select ''' + convert(varchar(255),@msg_uid) + ''', row_id, ''message'', c1
from ' + @tbl_name + ' where typ = ''M''
order by row_id'
exec (@cmd)

GO
GRANT EXECUTE ON  [dbo].[adm_email_format_message] TO [public]
GO
