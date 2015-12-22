SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[scm_pb_set_dw_invm_mods_sp] 
@typ char(1), @part_no varchar(30), @timestamp varchar(20)
 AS
BEGIN
DECLARE @ts timestamp
exec adm_varchar_to_ts_sp @timestamp, @ts output
if @typ = 'I'
begin
Insert into mod_inv_master (part_no
)
values (@part_no
)
end
if @typ = 'U'
begin
update mod_inv_master set
part_no = @part_no
where mod_inv_master.part_no= @part_no
 and mod_inv_master.timestamp= @ts
if @@rowcount = 0
begin
  rollback tran
  RAISERROR 832115 'Row changed between retrieve and update'
  RETURN 
end

end
if @typ = 'D'
begin
delete from mod_inv_master
where mod_inv_master.part_no= @part_no
if @@rowcount = 0
begin
  rollback tran
  RAISERROR 832115 'Error Deleting Row'
  RETURN 
end

end

return
end
GO
GRANT EXECUTE ON  [dbo].[scm_pb_set_dw_invm_mods_sp] TO [public]
GO
