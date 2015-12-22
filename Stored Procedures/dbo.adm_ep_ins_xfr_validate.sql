SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_ep_ins_xfr_validate]
@proc_po_no		varchar(20), --			REQUIRED
@from_loc		varchar(10), --			REQUIRED
@to_loc			varchar(10), --			REQUIRED
@req_ship_date	datetime = NULL, --		default getdate()
@sch_ship_date	datetime = NULL, --		default getdate()
@date_entered	datetime = NULL, --		default getdate()
@who_entered	varchar(20) = NULL, --	default	user_name()
@attention		varchar(15) = NULL, --	default NULL
@phone			varchar(20) = NULL, --	default NULL
@routing		varchar(20) = NULL, --	default NULL (apshipv.ship_via_code)
@special_instr	varchar(255) = NULL, --	default NULL
@freight		decimal(20,8) = 0,	 --	default 0
@freight_type	varchar(10) = NULL,	 --	default NULL (freight_type.kys)
@note			varchar(255) = NULL,	 --	default NULL
@error_description VARCHAR(8000) OUTPUT
as

SET @error_description = ''

declare @xfer_no int, @x_to_loc varchar(10), @x_from_loc varchar(10)

IF @proc_po_no is null OR @from_loc is NULL OR @to_loc is NULL 
BEGIN
	if @proc_po_no is null 
	BEGIN
		SET @error_description = @error_description + '<ErrorCode>Header Error Code -10</ErrorCode>'
		SET @error_description = @error_description + '<ErrorInfo>The procurement po number can not be empty</ErrorInfo>'
	END

	if @from_loc is NULL 
	BEGIN
		SET @error_description = @error_description + '<ErrorCode>Header Error Code -20</ErrorCode>'
		SET @error_description = @error_description + '<ErrorInfo>The form location can not be empty</ErrorInfo>'
	END

	if @to_loc is NULL 
	BEGIN
		SET @error_description = @error_description + '<ErrorCode>Header Error Code -30</ErrorCode>'
		SET @error_description = @error_description + '<ErrorInfo>The to location can not be empty</ErrorInfo>'
	END

	GOTO EndProcedure
END

if not exists (select 1 from locations_all (nolock)
  where location = @from_loc and void = 'N')  
BEGIN
	SET @error_description = @error_description + '<ErrorCode>Header Error Code -21</ErrorCode>'
	SET @error_description = @error_description + '<ErrorInfo>There is no information related with the from location specified into the locations table</ErrorInfo>'

	GOTO EndProcedure
END

if not exists (select 1 from locations_all (nolock)
  where location = @to_loc and void = 'N')  
BEGIN
	SET @error_description = @error_description + '<ErrorCode>Header Error Code -31</ErrorCode>'
	SET @error_description = @error_description + '<ErrorInfo>There is no information related with the to location specified into the locations table</ErrorInfo>'

	GOTO EndProcedure
END

if @req_ship_date is NULL  set @req_ship_date = getdate()
if @sch_ship_date is NULL  set @sch_ship_date = getdate()
if @date_entered is NULL   set @date_entered = getdate()
if @who_entered is NULL    set @who_entered = suser_name()

select @xfer_no = xfer_no,
@x_to_loc = to_loc,
@x_from_loc = from_loc
from xfers_all (nolock)
where proc_po_no = @proc_po_no

if isnull(@xfer_no,'') != ''
begin
  if @to_loc != @x_to_loc  
	BEGIN
		SET @error_description = @error_description + '<ErrorCode>Header Error Code -100</ErrorCode>'
		SET @error_description = @error_description + '<ErrorInfo>Can not duplicate order information</ErrorInfo>'

		GOTO EndProcedure
	END

  if @from_loc != @x_from_loc 
	BEGIN
		SET @error_description = @error_description + '<ErrorCode>Header Error Code -100</ErrorCode>'
		SET @error_description = @error_description + '<ErrorInfo>Can not duplicate order information</ErrorInfo>'

		GOTO EndProcedure
	END

	
	SET @error_description = @error_description + '<ErrorCode>Header Error Code 100</ErrorCode>'
	SET @error_description = @error_description + '<ErrorInfo>Can not duplicate order information</ErrorInfo>'

	GOTO EndProcedure
end

EndProcedure:
GO
GRANT EXECUTE ON  [dbo].[adm_ep_ins_xfr_validate] TO [public]
GO
