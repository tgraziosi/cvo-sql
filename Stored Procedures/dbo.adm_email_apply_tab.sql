SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create proc [dbo].[adm_email_apply_tab] @atab char(1) out, @atab_pos int, @sec varchar(7900),
@line varchar(7900) out
as
begin
declare @tpos int

      if @atab = 'C'
      begin
        set @tpos = datalength(@sec) /2.0
        if datalength(@line) < (@atab_pos - @tpos)
          select @line = @line + replicate(' ',(@atab_pos -1 - @tpos) - datalength(@line)) + @sec
        else
          select @line = substring(@line,1,(@atab_pos - @tpos)) + @sec
      end
      else if @atab = 'R'
      begin
        set @tpos = datalength(@sec)
        if datalength(@line) < (@atab_pos - @tpos)
          select @line = @line + replicate(' ',(@atab_pos - @tpos) - datalength(@line)) + @sec
        else
          select @line = substring(@line,1,(@atab_pos - @tpos)) + @sec
      end
      else if @atab = 'L'
      begin
        set @tpos = datalength(@sec) -1
        if datalength(@line) < (@atab_pos -1)
          select @line = @line + replicate(' ',(@atab_pos -1) - datalength(@line)) + @sec
        else
          select @line = substring(@line,1,(@atab_pos -1)) + @sec
      end
     else 
       select @line = @line + @sec

set @atab = ''
end
GO
GRANT EXECUTE ON  [dbo].[adm_email_apply_tab] TO [public]
GO
