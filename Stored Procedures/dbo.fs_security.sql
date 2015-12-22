SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_security] @username varchar(10), @userpass varchar(50) AS

declare @p varchar(50)
declare @irtn integer
select @p = password from sec_user where kys=@username









if @userpass = @p
   select @irtn = 1
else
   select @irtn = 0

select @irtn

GO
GRANT EXECUTE ON  [dbo].[fs_security] TO [public]
GO
