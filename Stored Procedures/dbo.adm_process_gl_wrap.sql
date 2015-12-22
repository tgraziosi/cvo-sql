SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[adm_process_gl_wrap] @user varchar(30),
 @meth int = 1, 
 @p_trx_type char(1) = '', 
 @p_tran_no int = 0,
 @p_tran_ext int = 0 AS


BEGIN
	DECLARE @err int

	EXEC adm_process_gl @user, @meth, @p_trx_type, @p_tran_no, @p_tran_ext, @err OUT
	
	Select @err

END

GO
GRANT EXECUTE ON  [dbo].[adm_process_gl_wrap] TO [public]
GO
