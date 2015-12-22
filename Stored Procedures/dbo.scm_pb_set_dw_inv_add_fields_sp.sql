SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[scm_pb_set_dw_inv_add_fields_sp] 
@typ char(1), @part_no varchar(30), @category_1 varchar(15)
, @category_2 varchar(15), @category_3 varchar(15), @category_4 varchar(15)
, @category_5 varchar(15), @datetime_1 datetime, @datetime_2 datetime
, @field_1 varchar(40), @field_2 varchar(40), @field_3 varchar(40)
, @field_4 varchar(40), @field_5 varchar(40), @field_6 varchar(40)
, @field_7 varchar(40), @field_8 varchar(40), @field_9 varchar(40)
, @field_10 varchar(40), @field_11 varchar(40), @field_12 varchar(40)
, @field_13 varchar(40), @field_14 varchar(255), @field_15 varchar(255)
, @field_16 varchar(255), @long_descr varchar(4099), @timestamp varchar(20)
 AS
BEGIN
DECLARE @ts timestamp
exec adm_varchar_to_ts_sp @timestamp, @ts output
if @typ = 'I'
begin
Insert into inv_master_add (inv_master_add.part_no, inv_master_add.category_1, inv_master_add.category_2
, inv_master_add.category_3, inv_master_add.category_4
, inv_master_add.category_5, inv_master_add.datetime_1
, inv_master_add.datetime_2, inv_master_add.field_1, inv_master_add.field_2
, inv_master_add.field_3, inv_master_add.field_4, inv_master_add.field_5
, inv_master_add.field_6, inv_master_add.field_7, inv_master_add.field_8
, inv_master_add.field_9, inv_master_add.field_10, inv_master_add.field_11
, inv_master_add.field_12, inv_master_add.field_13, inv_master_add.field_14
, inv_master_add.field_15, inv_master_add.field_16, inv_master_add.long_descr
)
values (@part_no, @category_1, @category_2, @category_3, @category_4, @category_5
, @datetime_1, @datetime_2, @field_1, @field_2, @field_3, @field_4, @field_5
, @field_6, @field_7, @field_8, @field_9, @field_10, @field_11, @field_12
, @field_13, @field_14, @field_15, @field_16, @long_descr
)
end
if @typ = 'U'
begin
update inv_master_add set
inv_master_add.category_1= @category_1, inv_master_add.category_2= @category_2
, inv_master_add.category_3= @category_3, inv_master_add.category_4= @category_4
, inv_master_add.category_5= @category_5, inv_master_add.datetime_1= @datetime_1
, inv_master_add.datetime_2= @datetime_2, inv_master_add.field_1= @field_1
, inv_master_add.field_2= @field_2, inv_master_add.field_3= @field_3
, inv_master_add.field_4= @field_4, inv_master_add.field_5= @field_5
, inv_master_add.field_6= @field_6, inv_master_add.field_7= @field_7
, inv_master_add.field_8= @field_8, inv_master_add.field_9= @field_9
, inv_master_add.field_10= @field_10, inv_master_add.field_11= @field_11
, inv_master_add.field_12= @field_12, inv_master_add.field_13= @field_13
, inv_master_add.field_14= @field_14, inv_master_add.field_15= @field_15
, inv_master_add.field_16= @field_16, inv_master_add.long_descr= @long_descr
where inv_master_add.part_no= @part_no
 and inv_master_add.timestamp= @ts
if @@rowcount = 0
begin
  rollback tran
  RAISERROR 832115 'Row changed between retrieve and update'
  RETURN 
end

end
if @typ = 'D'
begin
delete from inv_master_add
where inv_master_add.part_no= @part_no
if @@rowcount = 0
begin
  rollback tran
  RAISERROR 832115 'Error Deleting Row'
  RETURN 
end

end

return
end

grant execute on [scm_pb_set_dw_inv_add_fields_sp] to public
GO
GRANT EXECUTE ON  [dbo].[scm_pb_set_dw_inv_add_fields_sp] TO [public]
GO
