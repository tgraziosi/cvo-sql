SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[scm_pb_set_dw_uom_id_code_sp] 
@typ char(1), @part_no varchar(30), @uom_description varchar(2)
, @upc varchar(12), @gtin varchar(14), @ean_8 varchar(8), @ean_13 varchar(13)
, @ean_14 varchar(14), @inv_master_description varchar(255), @csort integer
, @timestamp varchar(20)
 AS
BEGIN
DECLARE @ts timestamp
exec adm_varchar_to_ts_sp @timestamp, @ts output
if @typ = 'I'
begin
Insert into uom_id_code (uom_id_code.part_no, uom_id_code.UOM, uom_id_code.UPC, uom_id_code.GTIN
, uom_id_code.EAN_8, uom_id_code.EAN_13, uom_id_code.EAN_14
)
values (@part_no, @uom_description, @upc, @gtin, @ean_8, @ean_13, @ean_14
)
end
if @typ = 'U'
begin
update uom_id_code set
uom_id_code.UPC= @upc, uom_id_code.GTIN= @gtin, uom_id_code.EAN_8= @ean_8
, uom_id_code.EAN_13= @ean_13, uom_id_code.EAN_14= @ean_14
where uom_id_code.part_no= @part_no and uom_id_code.UOM= @uom_description
 and uom_id_code.timestamp= @ts
if @@rowcount = 0
begin
  rollback tran
  RAISERROR 832115 'Row changed between retrieve and update'
  RETURN 
end

end
if @typ = 'D'
begin
delete from uom_id_code
where uom_id_code.part_no= @part_no and uom_id_code.UOM= @uom_description
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
GRANT EXECUTE ON  [dbo].[scm_pb_set_dw_uom_id_code_sp] TO [public]
GO
