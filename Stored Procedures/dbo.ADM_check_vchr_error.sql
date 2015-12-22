SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[ADM_check_vchr_error]  @process_ctrl_num varchar(16), @err int AS

begin

        select isnull(a.err_code,#ewerror.err_code),
          a.refer_to,#ewerror.info1,a.field_desc,
          isnull(a.err_desc,#ewerror.info2),
          isnull(h.po_ctrl_num,#ewerror.source_ctrl_num),
          @err
        from #ewerror
        left outer join apedterr a on a.err_code = #ewerror.err_code
        left outer join #apvovchg h on h.trx_ctrl_num = #ewerror.trx_ctrl_num
	UNION
        select isnull(a.err_code,#ewerror.err_code),
          a.refer_to,#ewerror.info1,a.field_desc,
		  isnull(a.err_desc,#ewerror.info2),
          isnull(h.po_ctrl_num,#ewerror.source_ctrl_num),
          @err
        from #ewerror
        left outer join apedterr a on a.err_code = #ewerror.err_code
        left outer join #apdmvchg h on h.trx_ctrl_num = #ewerror.trx_ctrl_num
end 

GO
GRANT EXECUTE ON  [dbo].[ADM_check_vchr_error] TO [public]
GO
