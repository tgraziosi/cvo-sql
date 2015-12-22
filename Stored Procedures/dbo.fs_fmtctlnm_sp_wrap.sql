SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[fs_fmtctlnm_sp_wrap]
	@num		int,
	@mask_str	varchar(16)
AS

DECLARE @ctrl_num 	varchar(16),
	@error_flag 	smallint


EXEC fs_fmtctlnm_sp @num, @mask_str, @ctrl_num OUT, @error_flag OUT

select @ctrl_num, @error_flag

GO
GRANT EXECUTE ON  [dbo].[fs_fmtctlnm_sp_wrap] TO [public]
GO
