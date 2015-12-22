SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



create procedure [dbo].[fs_check_icverify] as
begin
if exists(select * from config where flag = 'CCA' and value_str = 'Y')
BEGIN
	select 'Y' 'return_val'
	return
end
select 'N' 'return_val'
end
GO
GRANT EXECUTE ON  [dbo].[fs_check_icverify] TO [public]
GO
