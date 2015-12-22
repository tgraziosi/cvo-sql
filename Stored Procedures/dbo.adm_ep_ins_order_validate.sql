SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_ep_ins_order_validate]
@cust_code varchar(10),  @req_ship_date datetime,  @cust_po varchar(20),  
@attention varchar(40),  @note varchar(255), @location varchar(10), 
@sold_to_addr1 varchar(40),  @sold_to_addr2 varchar(40),  @sold_to_addr3 varchar(40),  @sold_to_addr4 varchar(40), 
@sold_to_addr5 varchar(40),  @sold_to_addr6 varchar(40), @void_ind int = 0,
@error_description VARCHAR(8000) OUTPUT
as

SET @error_description = ''

declare @ord_no int,  @ord_ext int, @rc int
select @ord_no = 0, @rc = 1

select @location = isnull(@location,'')
if @location != ''
begin
  if not exists (select 1 from locations_all where location = @location and isnull(void,'N') != 'V' and location not like 'DROP%')
    select @rc = 2, @location = ''
end

if @location = ''
BEGIN
	SET @error_description = @error_description + '<ErrorCode>Header Error Code -4</ErrorCode>'
	SET @error_description = @error_description + '<ErrorInfo>The location can not be empty</ErrorInfo>'

	GOTO EndProcedure
END

if exists (select 1 from orders_all (nolock) where cust_po = @cust_po and cust_code = @cust_code
  and ext = 0 and isnull(eprocurement_ind,0) = 1)
begin
  if isnull((select count(*) from orders_all (nolock) where cust_po = @cust_po and cust_code = @cust_code
    and ext = 0 and (status = 'N' or status < 'L') and isnull(eprocurement_ind,0) = 1), 0) > 1
  begin
	SET @error_description = @error_description + '<ErrorCode>Header Error Code -2</ErrorCode>'
	SET @error_description = @error_description + '<ErrorInfo>Can not duplicate a Sales Order</ErrorInfo>'

	GOTO EndProcedure
  end

  select @ord_no = order_no,  @ord_ext = 0
  from orders_all 
  where cust_po = @cust_po and cust_code = @cust_code and ext = 0 and (status = 'N' or status < 'L')
    and isnull(eprocurement_ind,0) = 1

  if @@rowcount = 0
  begin
    if exists (select 1 from orders_all (nolock) where cust_po = @cust_po and cust_code = @cust_code
      and ext = 0 and status in ('P','Q','R') and isnull(eprocurement_ind,0) = 1)
	  BEGIN
		SET @error_description = @error_description + '<ErrorCode>Header Error Code -10</ErrorCode>'
		SET @error_description = @error_description + '<ErrorInfo>Can not duplicate a Sales Order</ErrorInfo>'

		GOTO EndProcedure
	  END

    if exists (select 1 from orders_all (nolock) where cust_po = @cust_po and cust_code = @cust_code
      and ext = 0 and status in ('S','T') and isnull(eprocurement_ind,0) = 1)
	  BEGIN
		SET @error_description = @error_description + '<ErrorCode>Header Error Code -11</ErrorCode>'
		SET @error_description = @error_description + '<ErrorInfo>Can not duplicate a Sales Order</ErrorInfo>'

		GOTO EndProcedure
	  END
     
    if exists (select 1 from orders_all (nolock) where cust_po = @cust_po and cust_code = @cust_code
      and ext = 0 and status = 'V' and isnull(eprocurement_ind,0) = 1)
	  BEGIN
		SET @error_description = @error_description + '<ErrorCode>Header Error Code -12</ErrorCode>'
		SET @error_description = @error_description + '<ErrorInfo>Can not duplicate a Sales Order</ErrorInfo>'

		GOTO EndProcedure
	  END

	SET @error_description = @error_description + '<ErrorCode>Header Error Code -13</ErrorCode>'
	SET @error_description = @error_description + '<ErrorInfo>Can not duplicate a Sales Order</ErrorInfo>'

	GOTO EndProcedure
  end
end

EndProcedure:

GO
GRANT EXECUTE ON  [dbo].[adm_ep_ins_order_validate] TO [public]
GO
