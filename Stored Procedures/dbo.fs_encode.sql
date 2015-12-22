SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_encode] @arg1 varchar(50), @arg2 varchar(50), @mode char(1) AS

declare @irtn integer
if @mode is null begin
   select @mode = 'E'
end
if @mode = 'E' begin
   select @arg2 = pwdencrypt( @arg1 )
end
if @mode <> 'E' begin
   select @irtn = pwdcompare( @arg1, @arg2 )
   if @irtn is null begin
      select @irtn = 0
   end
   select @arg2 = convert( varchar(50), @irtn )
end
select @arg2

GO
GRANT EXECUTE ON  [dbo].[fs_encode] TO [public]
GO
