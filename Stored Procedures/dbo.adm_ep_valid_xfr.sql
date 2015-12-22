SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_ep_valid_xfr]
  @part_no varchar(30),						-- REQUIRED
  @from_loc varchar(30),					-- REQUIRED
  @to_loc varchar(30)						-- REQUIRED
as

if isnull(@part_no,'') = ''  return 0
if isnull(@from_loc,'') = ''  return 0
if isnull(@to_loc,'') = ''  return 0

if not exists (select 1 from inv_list (nolock) where part_no = @part_no
  and location = @from_loc)  return 0

if not exists (select 1 from inv_list (nolock) where part_no = @part_no
  and location = @to_loc)  return 0


return 1
GO
GRANT EXECUTE ON  [dbo].[adm_ep_valid_xfr] TO [public]
GO
