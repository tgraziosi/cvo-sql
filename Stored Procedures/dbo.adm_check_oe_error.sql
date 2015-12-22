SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_check_oe_error] @process_ctrl_num varchar(16) AS

begin

        select a.e_code,a.refer_to,e.info1,a.field_desc,a.err_desc,h.order_ctrl_num
          from aredterr a
	  join #ewerror e on  a.e_code = e.err_code
	  join #arvalchg h on h.trx_ctrl_num = e.trx_ctrl_num

end 

GO
GRANT EXECUTE ON  [dbo].[adm_check_oe_error] TO [public]
GO
