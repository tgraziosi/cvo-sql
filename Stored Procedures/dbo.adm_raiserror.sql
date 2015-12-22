SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create proc  [dbo].[adm_raiserror] @err_no int, @err_msg varchar(1000)
as
begin
declare @msg varchar(1000)
select @msg = '(#' + dbo.adm_localize_sqlmsg (@err_msg) + '#)'

raiserror @err_no @msg
end
GO
GRANT EXECUTE ON  [dbo].[adm_raiserror] TO [public]
GO
