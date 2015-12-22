SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_ep_ins_xfr_line_validate]
@proc_po_no		varchar(20),		 --	REQUIRED
@vendor_cd		varchar(12),		 --	REQUIERD
@part_no		varchar(30),		 --	REQUIRED
@ordered		decimal(20,8),		 --	REQUIRED
@line_no		integer = NULL,		 --	default NULL (get max + 1 line)
@time_entered	datetime = NULL,	 --	default getdate()
@comment		varchar(255) = NULL, -- default NULL
@who_entered	varchar(20) = NULL,	 -- default user_name()
@uom			char(2) = NULL,		 -- default inv_master.uom (must have valid
									 --conversion to stocking UOM)
@error_description VARCHAR(8000) OUTPUT
as

SET @error_description = ''

declare @status char(1), @xfer_no int,
@from_loc varchar(10), @to_loc varchar(10), @i_uom char(2),
@conv_factor decimal(20,8), @new_line int,
@x_part_no varchar(30)
declare @chk_sku_ind int

IF @proc_po_no is NULL OR @part_no is NULL OR isnull(@ordered,0) <= 0 
BEGIN
	if @proc_po_no is NULL  
	BEGIN
		SET @error_description = @error_description + '<ErrorCode>Detail Error Code -10</ErrorCode>'
		SET @error_description = @error_description + '<ErrorInfo>The procurement po number can not be empty</ErrorInfo>'
	END

	if @part_no is NULL 
	BEGIN
		SET @error_description = @error_description + '<ErrorCode>Detail Error Code -20</ErrorCode>'
		SET @error_description = @error_description + '<ErrorInfo>The part number can not be empty</ErrorInfo>'
	END

	if isnull(@ordered,0) <= 0 
	BEGIN
		SET @error_description = @error_description + '<ErrorCode>Detail Error Code -30</ErrorCode>'
		SET @error_description = @error_description + '<ErrorInfo>The quantity ordered can not be empty</ErrorInfo>'
	END

	GOTO EndProcedure
END

if @time_entered is null set @time_entered = getdate()
if @who_entered is null  set @who_entered = suser_name()


set @chk_sku_ind = 0
while 1=1
begin
  select @i_uom = uom
    from inv_master (nolock) 
  where part_no = @part_no

  if @@rowcount > 0 break

  if @chk_sku_ind > 0 
	BEGIN
		SET @error_description = @error_description + '<ErrorCode>Detail Error Code -21</ErrorCode>'
		SET @error_description = @error_description + '<ErrorInfo>The chk sku ind can not be different from 0</ErrorInfo>'

		GOTO EndProcedure
	END

end

set @conv_factor = 1

if @uom is null set @uom = @i_uom
if @i_uom != @uom
begin
  select @conv_factor = conv_factor
  from uom_table (nolock)
  where item = @part_no and std_uom = @i_uom and alt_uom = @uom

  if @@rowcount = 0
  begin
    select @conv_factor = conv_factor
    from uom_table (nolock)
    where item = 'STD' and std_uom = @i_uom and alt_uom = @uom

    if @@rowcount = 0  
	BEGIN
		SET @error_description = @error_description + '<ErrorCode>Detail Error Code -40</ErrorCode>'
		SET @error_description = @error_description + '<ErrorInfo>There is no information related with the unit of measure into uom table</ErrorInfo>'

		GOTO EndProcedure
	END
  end
end

if isnull(@line_no,0) =0
begin
  select @new_line = 1
  select @line_no = isnull((select max(line_no) from xfer_list (nolock)
    where xfer_no = @xfer_no),0) + 1
end
else
begin
  select @x_part_no from xfer_list (nolock)
    where xfer_no = @xfer_no and line_no = @line_no

  if @@rowcount > 0
  begin
    if @x_part_no <> @part_no  
	BEGIN
		SET @error_description = @error_description + '<ErrorCode>Detail Error Code -100</ErrorCode>'
		SET @error_description = @error_description + '<ErrorInfo>Can not duplicate order information</ErrorInfo>'

		GOTO EndProcedure
	END

	SET @error_description = @error_description + '<ErrorCode>Detail Error Code 100</ErrorCode>'
	SET @error_description = @error_description + '<ErrorInfo>Can not duplicate order information</ErrorInfo>'

	GOTO EndProcedure
  end
end

EndProcedure:
GO
GRANT EXECUTE ON  [dbo].[adm_ep_ins_xfr_line_validate] TO [public]
GO
