SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO








 

create procedure [dbo].[adm_ep_ins_order_dtl_validate] @cust_code varchar(10), @cust_po varchar(20),
@line_no int, @location varchar(10), @part_no varchar(30), @ordered decimal(20,8),
@uom char(2), @note varchar(255), @gl_rev_acct varchar(32), @reference_code varchar(32),
@error_description VARCHAR(8000) OUTPUT
as

SET @error_description = ''

declare @ord_no int,  @ord_ext int, @rc int, @ol_line int, 
  @conv_factor decimal(20,8), @std_uom char(2),
  @kit_ins int,
  @inv_org_id varchar(30),							-- mls 3/24/05
  @masked_gl_rev_acct varchar(32)
declare @chk_sku_ind int

select @ord_no = 0, @rc = 1, @ol_line = 0
select @inv_org_id = isnull((select value_str from config (nolock) where flag = 'INV_ORG_ID'),'')

select @location = isnull(@location,'')
if @location != ''
	begin
		if not exists (select 1 from locations where location = @location and isnull(void,'N') != 'V' and location not like 'DROP%')
			select @rc = 2, @location = ''
		end

		if @location = ''
		BEGIN
			SET @error_description = @error_description + '<ErrorCode>Detail Error Code -1</ErrorCode>'
		SET @error_description = @error_description + '<ErrorInfo>The location can not be empty</ErrorInfo>'

		GOTO EndProcedure
end 

if exists (select 1 from orders_all (nolock) where cust_po = @cust_po and cust_code = @cust_code
  and ext = 0 and (status = 'N' or status < 'L') and isnull(eprocurement_ind,0) = 1)
begin
  if isnull((select count(*) from orders_all (nolock) where cust_po = @cust_po and cust_code = @cust_code
    and ext = 0 and (status = 'N' or status < 'L') and isnull(eprocurement_ind,0) = 1), 0) != 1
  begin
	SET @error_description = @error_description + '<ErrorCode>Detail Error Code -2</ErrorCode>'
	SET @error_description = @error_description + '<ErrorInfo>Can not duplicate SO information</ErrorInfo>'

	GOTO EndProcedure
  end

  select @ord_no = order_no,  @ord_ext = 0
  from orders_all 
  where cust_po = @cust_po and cust_code = @cust_code and ext = 0 and (status = 'N' or status < 'L')
    and isnull(eprocurement_ind,0) = 1

  if @@rowcount = 0
  begin
	SET @error_description = @error_description + '<ErrorCode>Detail Error Code -3</ErrorCode>'
	SET @error_description = @error_description + '<ErrorInfo>Can not duplicate SO information</ErrorInfo>'

	GOTO EndProcedure
  end

  set @chk_sku_ind = 0
  while 1=1
  begin
    select @part_no = part_no, @location = location
    from inv_sales (nolock)
    where part_no = @part_no and location = @location

    if @@rowcount > 0 break

    if @chk_sku_ind > 0 
	  BEGIN
		SET @error_description = @error_description + '<ErrorCode>Detail Error Code -4</ErrorCode>'
		SET @error_description = @error_description + '<ErrorInfo>The chk sku index can not be different from 0</ErrorInfo>'

		GOTO EndProcedure
	  END

    set @chk_sku_ind = 1

    select @part_no = sku_no
    from vendor_sku (nolock)
    where vend_sku = @part_no and vendor_no = @cust_code

    if @@rowcount = 0 
	  BEGIN
		SET @error_description = @error_description + '<ErrorCode>Detail Error Code -4</ErrorCode>'
		SET @error_description = @error_description + '<ErrorInfo>There is not information related with the part number and customer code specified into vendor part table</ErrorInfo>'

		GOTO EndProcedure
	  END

   end

  select @masked_gl_rev_acct = dbo.IBAcctMask_fn(@gl_rev_acct,@inv_org_id)

  if not exists (select 1 FROM adm_glchart_all (nolock) 			-- mls 3/24/05 
    WHERE inactive_flag = 0 AND account_code = @masked_gl_rev_acct)
  begin
	SET @error_description = @error_description + '<ErrorCode>Detail Error Code -5</ErrorCode>'
	SET @error_description = @error_description + '<ErrorInfo>There is not information related with the account code specified into accounts table</ErrorInfo>'

	GOTO EndProcedure
  end

  if exists (select 1 from glrefact (nolock) where @masked_gl_rev_acct like account_mask and reference_flag > 1)
  begin
    if not exists (select 1 from glratyp t (nolock), glref r (nolock)
      where t.reference_type = r.reference_type and @masked_gl_rev_acct like t.account_mask and
              r.status_flag = 0 and r.reference_code  = @reference_code)
      select @reference_code = NULL, @rc = 3
  end
  else
    select @reference_code = NULL, @rc = 2

  select @conv_factor = 1
  select @std_uom = uom from inv_master where part_no = @part_no
  if isnull(@std_uom,'!!') != isnull(@uom,'@@')
  begin
    if @uom is null or @std_uom is null
    begin
		SET @error_description = @error_description + '<ErrorCode>Detail Error Code -6</ErrorCode>'
		SET @error_description = @error_description + '<ErrorInfo>The unit of measure can not be empty</ErrorInfo>'

		GOTO EndProcedure
    end

    select @conv_factor = isnull((select conv_factor
    from uom_table where item = @part_no and alt_uom = @uom and std_uom = @std_uom),NULL)

    if @conv_factor is null
      select @conv_factor = isnull((select conv_factor
      from uom_table where item = 'STD' and alt_uom = @uom and std_uom = @std_uom),NULL)

    if @conv_factor is null
    begin
		SET @error_description = @error_description + '<ErrorCode>Detail Error Code -7</ErrorCode>'
		SET @error_description = @error_description + '<ErrorInfo>The convertion factor can not be empty</ErrorInfo>'

		GOTO EndProcedure      
    end
  end

  select @ol_line = isnull((select line_no from ord_list (nolock) 
    where order_no = @ord_no and order_ext = 0 and line_no = @line_no),0)
end

EndProcedure:

GO
GRANT EXECUTE ON  [dbo].[adm_ep_ins_order_dtl_validate] TO [public]
GO
