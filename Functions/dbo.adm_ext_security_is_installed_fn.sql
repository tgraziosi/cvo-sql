SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE FUNCTION [dbo].[adm_ext_security_is_installed_fn] ()
RETURNS smallint
BEGIN		
        declare @ib_flag int, @adm_flag int
        select @ib_flag = dbo.sm_ext_security_is_installed_fn()
        select @adm_flag = isnull((select loc_security_flag from dmco (nolock)),0)
	select @ib_flag = @ib_flag + case when @adm_flag = 0 then -1 else 1 end
        return @ib_flag
END
GO
GRANT REFERENCES ON  [dbo].[adm_ext_security_is_installed_fn] TO [public]
GO
GRANT EXECUTE ON  [dbo].[adm_ext_security_is_installed_fn] TO [public]
GO
