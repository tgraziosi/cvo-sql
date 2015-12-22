SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_zoom] @mode varchar(10),@sqltext varchar(1000), @key_col varchar(255),
@key_type int, @last_key varchar(255), @void_col varchar(255)
AS
declare @key_char char(1)

select @sqltext = replace(@sqltext,'"','''')

select @key_char = 
  case 
  when @key_type in (13,2,12,1) then 'N'
  when @key_type in (5,14) then 'T'
  when @key_type in (3,4) then 'D'
  else 'S' end

if lower(@mode) = 'first'
  exec fs_zoom_first @sqltext, @key_col,@void_col

if lower(@mode) = 'last'
  exec fs_zoom_last @sqltext, @key_col,@void_col

if lower(@mode) = 'next'
  exec fs_zoom_next @sqltext,@key_col, @key_char, @last_key,@void_col

if lower(@mode) = 'prev'
  exec fs_zoom_prev @sqltext, @key_col, @key_char, @last_key,@void_col

if lower(@mode) = 'get'
  exec fs_zoom_get @sqltext, @key_col, @key_char, @last_key,@void_col

GO
GRANT EXECUTE ON  [dbo].[fs_zoom] TO [public]
GO
