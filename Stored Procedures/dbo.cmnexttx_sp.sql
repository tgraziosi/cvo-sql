SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO




 

CREATE PROC [dbo].[cmnexttx_sp] AS 

declare @float_holder float, @int_holder int, 
 @char_holder char(80), @trx_len int,
			@trx_ctrl_int int,				 @trx_ctrl_num 	 char(20)

begin transaction

update cmnumber
 set next_trx_ctrl_num = next_trx_ctrl_num + 1

select @float_holder = null 
select @float_holder = next_trx_ctrl_num - 1, @char_holder = trx_ctrl_num_mask,
 @trx_ctrl_int = next_trx_ctrl_num - 1
 from cmnumber

select @int_holder = charindex( "#", @char_holder ) 

if @int_holder = 0 
 select @int_holder = charindex( "0", @char_holder ) 

select @trx_len = datalength( rtrim( @char_holder ) ) - @int_holder + 1 

select @trx_ctrl_num = substring( @char_holder, 1, @int_holder - 1 ) + 
 right("0000000000000000" + rtrim(ltrim(str( @float_holder, 16, 0))), @trx_len) 

commit transaction
select @trx_ctrl_int, @trx_ctrl_num 
GO
GRANT EXECUTE ON  [dbo].[cmnexttx_sp] TO [public]
GO
