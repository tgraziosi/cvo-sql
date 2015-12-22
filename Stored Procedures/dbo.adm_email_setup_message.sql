SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_email_setup_message]
@source varchar(10),
@email_nm varchar(50),
@parms varchar(1000),
@tbl_name varchar(1000),
@width int
as
begin
declare
 @declare_data varchar(4000),
 @fetch_data varchar(4000),
 @select_data varchar(4000),
 @replace_data varchar(4000),
 @sub_data varchar(4000)
declare @dtl_value varchar(7900)
declare @dtl_flags varchar(10)
declare @st_pos int, @en_pos int, @col_nm varchar(255),
  @sub_cnt int, @col_cnt int, @cmd varchar(8000)

select @select_data = '', @col_cnt = 0, @declare_data = '', @fetch_data = ''
select @replace_data = '', @sub_data = ''

if @source = 'Type'
begin
  DECLARE t1cursor CURSOR LOCAL STATIC FOR
  SELECT dtl_value, dtl_flags
  from adm_email_type_dtl (nolock)
  where email_type = @email_nm
  and dtl_typ like 'msg%'
  order by dtl_typ,dtl_typ_seq_id
end
else
begin
  DECLARE t1cursor CURSOR LOCAL STATIC FOR
  SELECT dtl_value, dtl_flags
  from adm_email_template_dtl (nolock)
  where email_template_nm = @email_nm
  and dtl_typ like 'msg%'
  order by dtl_typ,dtl_typ_seq_id
end

OPEN t1cursor
if @@cursor_rows > 0
begin
  FETCH NEXT FROM t1cursor into @dtl_value, @dtl_flags
  While @@FETCH_STATUS = 0
  begin
    exec adm_email_insert_parm @parms, @dtl_value OUT, @width

    set @st_pos = charindex('<',@dtl_value)
    while @st_pos > 0
    begin
      if @st_pos > 1
      begin
        while substring(@dtl_value,@st_pos -1,1) = '~'
        begin
          set @dtl_value = left(@dtl_value,@st_pos -2) + 
            substring(@dtl_value,@st_pos,datalength(@dtl_value))
          set @st_pos = charindex('<',@dtl_value,@st_pos)
          if @st_pos = 0 break
        end
      end
      if @st_pos > 0
      begin
        set @en_pos = charindex('>',@dtl_value,@st_pos)
        while substring(@dtl_value,@en_pos -1,1) = '~'
        begin
          set @dtl_value = left(@dtl_value,@en_pos -2) + 
            substring(@dtl_value,@en_pos,datalength(@dtl_value))
          set @en_pos = charindex('>',@dtl_value,@en_pos)
          if @en_pos = 0 break
        end
        if @en_pos > 0 and @en_pos > (@st_pos + 1)
        begin
          set @col_nm = substring(@dtl_value,@st_pos +1, (@en_pos - @st_pos) -1)
          set @col_nm = ltrim(rtrim(@col_nm))
          if @col_nm != ''
          begin
            set @sub_cnt = charindex('<' + @col_nm + '>',@sub_data)
            if @sub_cnt = 0
            begin
              set @sub_data = '<' + @col_nm + '>'
              select @select_data = @select_data + @col_nm + ','
              set @col_cnt = @col_cnt + 1
              set @col_nm = '@c' + convert(varchar,@col_cnt)
              set @sub_data = @sub_data + '<' + @col_nm + '>'
              select @fetch_data = case when @col_cnt > '1' then ',' else '' end +
                @col_nm
              select @declare_data = case when @col_cnt > '1' then ',' else '' end +
                @col_nm + ' varchar(255)'
              insert #local_data (c1, msg_sect)
              select ' set @line = replace (@line,''<' + @col_nm + 
                '>'', isnull(' + @col_nm + ',''''))', 'R'
              insert #local_data (c1, msg_sect)
              select ' set @line = replace (@line,''<' + @col_nm + 
                '>'', isnull(' + @col_nm + ',''''))', 'R'
              insert #local_data (c1, msg_sect) select @fetch_data, 'F'
              insert #local_data (c1, msg_sect) select @declare_data, 'D'
              insert #local_data (c1, msg_sect) select @sub_data, 'U'
              end
            else
            begin
              set @col_nm = substring(@sub_data,@sub_cnt + datalength(@col_nm) + 3,
                charindex('>',@sub_data,@sub_cnt + datalength(@col_nm) + 3) - 
                (@sub_cnt + datalength(@col_nm) + 3))
            end
            select @dtl_value = left(@dtl_value, @st_pos) + @col_nm + 
              substring(@dtl_value,@en_pos,datalength(@dtl_value))      
            set @en_pos = charindex('>',@dtl_value,@st_pos)
		  end
        end
        set @st_pos = charindex('<',@dtl_value,@en_pos)
      end

    end  
    set @cmd = 'INSERT ' + @tbl_name + '(c1, msg_sect, final_ind)
    select ''' + @dtl_value + ''',''' + isnull(@dtl_flags,'_detail_') + ''', 0 ' 
    exec (@cmd)

    FETCH NEXT FROM t1cursor into @dtl_value, @dtl_flags
  end -- while
end
else
begin
    set @cmd = 'INSERT ' + @tbl_name + '(c1, msg_sect, final_ind)
    select ''No Message'',''D'', 1 ' 
    exec (@cmd)
end
CLOSE t1cursor
DEALLOCATE t1cursor

if @select_data > ''  set @select_data = left(@select_data, datalength(@select_data) -1)

insert #local_data (c1,msg_sect) select @select_data, 'S'

return @col_cnt
end
GO
GRANT EXECUTE ON  [dbo].[adm_email_setup_message] TO [public]
GO
