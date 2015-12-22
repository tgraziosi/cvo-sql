SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE	[dbo].[tdc_get_next_master_pack_number_sp]
(
	@next_num	INT	OUTPUT
)
AS

DECLARE
	@temp INT
	IF  EXISTS(SELECT * FROM tdc_next_master_pack_tbl)
		BEGIN
			select @temp = (select next_num from tdc_next_master_pack_tbl)
			update tdc_next_master_pack_tbl set next_num = @temp + 1
		END
	ELSE
		BEGIN
			insert tdc_next_master_pack_tbl values (1)
		END
	select @next_num = (select next_num from tdc_next_master_pack_tbl (nolock))
	return @next_num
GO
GRANT EXECUTE ON  [dbo].[tdc_get_next_master_pack_number_sp] TO [public]
GO
