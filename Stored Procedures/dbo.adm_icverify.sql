SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[adm_icverify] @order_no int, @order_ext int, @module varchar(10), 
  @error_msg varchar(80) OUT as

-- mls 8/19/02 SCR 29329 - added credit memo processing to stored proc - module - CR

declare @icv_ship char(1), @retcode int, @icv_reject int,
@icv_credit char(1)

select @icv_reject = 0

-- Is CCA installed?
if not exists (select 1 from config (nolock) where upper(flag) = 'CCA' and upper(value_str) like 'Y%')
begin
  select @error_msg = 'CCA not installed', @retcode = 1
  goto return_processing
end

if @module not in ('CR','SHP')
begin
  select @error_msg = 'invalid module', @retcode = -20
  goto return_processing
end
-- Check CCA at shipping
if @module = 'SHP'
begin
  select @icv_ship = isnull((select upper(left(value_str,1)) from config (nolock) where upper(flag) = 'ICV_SHIP'),'') 
  if not @icv_ship in ('A','S','B')
  begin
    select @error_msg = 'CCA not set up to check when shipping', @retcode = 2
    goto return_processing
  end
end
-- Check CCA for credit returns
if @module = 'CR'
begin
  select @icv_credit = isnull((select 'Y' from config (nolock) where upper(flag) = 'ICV_CREDIT' and upper(value_str) = 'YES'),'N') 
  if @icv_credit != 'Y'
  begin
    select @error_msg = 'CCA not set up to check credit returns', @retcode = 2
    goto return_processing
  end
end

declare @is_stat char(1), @is_prt char(1), @ld_gross_sales decimal(20,8), @ld_tot_tax decimal(20,8),
	@ld_tot_disc decimal(20,8), @ld_tot_freight decimal(20,8), @ld_total decimal(20,8),@cust_key varchar(10),
	@icv_val_cd varchar(40), @ls_status char(1), @pay_code varchar(8), @name varchar(30), @transtype varchar(10),
	@acctno varchar(20), @expire varchar(30), @ld_disc decimal(20,8),@ll_orig_no int, @ll_orig_ext int,
	@ccexpmo varchar(2), @ccexpyr varchar(4), @response varchar(60), @icvrespflag char(1), @stop int,
	@rejectrsn varchar(60), @approvecode varchar(60), @tempstr varchar(60), @referenceno varchar(60),
	@avs_result varchar(60), @count int, @count2 int, @auth_sequence int, @ord_pmt_seq int,
  @orig_no int, @orig_ext int

select	@is_stat = status, @is_prt = printed,
  @ld_gross_sales = gross_sales, @ld_tot_disc = total_discount, 
  @ld_tot_tax = total_tax, @ld_tot_freight = freight, @cust_key = cust_code,
  @orig_no = orig_no, @orig_ext = orig_ext
from	orders_all
where	order_no = @order_no and ext = @order_ext

if @@rowcount = 0
begin
  select @error_msg = case when @module = 'SHP' then 'Order ' else 'Credit ' end + 
    convert(varchar(10), @order_no) + '-' +
    convert(varchar(10),@order_ext) + ' not found on orders table.', @retcode = -10
  goto return_processing
end 

if @module = 'SHP'
begin
  -- Verify order is at proper status
  if @is_stat < 'N' 
  begin
    select @error_msg = 'Order on hold!', @retcode = -4
    goto return_processing
  end
  if @is_stat > 'R' 
  begin
    select @error_msg = 'Order posted / closed!', @retcode = -4
    goto return_processing
  end
  if @is_stat = 'R' and @is_prt > 'R'
  begin
    select @error_msg = 'Order being posted!', @retcode = -4
    goto return_processing
  end 
  if @is_stat < 'R' and @is_stat <> @is_prt 
  begin
    select @error_msg = 'Order being processed!', @retcode = -4
    goto return_processing
  end
end 

-- Get order total
select @ld_total = @ld_gross_sales - @ld_tot_disc + @ld_tot_tax + @ld_tot_freight

-- Ensure validation code has been entered
select @icv_val_cd = isnull((select value_str from config (nolock) where flag = 'ICV_VAL_CODE'),'')

if @icv_val_cd = ''
begin
  select @error_msg = 'There is no validation code defined on config table'
  select @retcode = -2, @icv_reject = 1
  goto return_processing
end 

-- Verify status not already shipped
if exists (select 1 from icv_orders (nolock) where order_no = @order_no and ext = @order_ext 
  and cc_status = 'S')
begin
  select @error_msg = 'Card already shipped', @retcode = 3
  goto return_processing
end 

select @pay_code = '', @name = '', @acctno = '', @expire = '', @ld_disc = 0

-- Obtain payment data
if @module = 'SHP'
begin
  select @pay_code = payment_code, @name = prompt1_inp, @acctno = left(prompt2_inp,20), 
    @expire = prompt3_inp, @ld_disc = amt_disc_taken
  from ord_payment
  where order_no = @order_no and order_ext = @order_ext and seq_no = 1

  if @@rowcount = 0 select @pay_code = ''
end
else if @module = 'CR'
begin
  if isnull(@orig_no,0) <= 0 
  begin
    select @error_msg = 'Original order not referenced on credit return', @retcode = 11
    goto return_processing
  end

  select @pay_code = payment_code, @name = prompt1_inp, @acctno = left(prompt2_inp,20), 
    @expire = prompt3_inp, @ld_disc = amt_disc_taken
  from ord_payment
  where order_no = @orig_no and order_ext = @orig_ext and seq_no = 1

  if @@rowcount = 0 select @pay_code = ''
end
else
begin
  select @error_msg = 'Module (' + isnull(@module,'') + ') currently not handled by this routine', @retcode = -15
  goto return_processing
end

if @pay_code = ''
begin
  update icv_orders
  set cc_status = 'N'
  where order_no = @order_no and ext = @order_ext

  select @error_msg = 'No payment information found', @retcode = -1
  goto return_processing
end

-- Confirm credit card type
if isnull((select creditcard_prefix from icv_cctype where payment_code = @pay_code),0) = 0
begin
  update icv_orders
  set cc_status = 'N'
  where order_no = @order_no and ext = @order_ext

  select @error_msg = 'Not a valid credit card', @retcode = -1
  goto return_processing
end

-- Reduce by discount & verify order total
if @ld_disc > 0.0 select @ld_total = @ld_total - @ld_disc
if @ld_total < 0.01 
begin
  select @error_msg = 'Order total is less than $0.01 and will not be processed.', @retcode = -2, @icv_reject = 1
  goto return_processing
end	

-- Set transaction type

if @module = 'SHP'
begin
  select @ls_status = cc_status from icv_orders where order_no = @order_no and ext = @order_ext

  select @transtype = ''
  if @icv_ship = 'A' and @ls_status not in ('S','B') select @transtype = 'C6'
  if @icv_ship = 'B' and @ls_status not in ('S','B') select @transtype = 'C4'
  if @icv_ship = 'S' and @ls_status = 'B' select @transtype = 'CO'
  if @icv_ship = 'S' and @ls_status not in ('S','B') select @transtype = 'C1'

  if @transtype = ''
  begin
    select @error_msg = 'Transaction does not need processing', @retcode = 3
    goto return_processing
  end
end 
if @module = 'CR'
begin
  select @transtype = 'C3'
end

select @ccexpmo = Left( @expire, 2 ), @ccexpyr = Right( @expire, 2 ), @response = ''

-- Perform authorization
exec icv_fs_trans @transtype, @acctno, @ccexpmo, @ccexpyr, @ld_total, @response OUT, @order_no, @order_ext
if isnull(@response,'') = ''
begin
  select @error_msg = 'Transaction does not need processing', @retcode = 3
  goto return_processing
end

-- Process response
select @icvrespflag = Left( Right( @response, ( datalength( @response ) - 1 )), 1 )
if @icvrespflag = 'N'
begin
  select @response = right(@response,(datalength(@response) - 1))
  while left(@response,1) = 'N'
	select @response = right(@response,(datalength(@response) - 1))
  select @stop = charindex('"',@response,1) - 1
  select @rejectrsn = substring(@response,1, @stop)
  select @error_msg = 'Transaction declined: ' + @rejectrsn
  select @response = @rejectrsn
end
else if @icvrespflag = 'T'
begin
  select @rejectrsn = 'Timed Out'
  select @response = 'Verification request timed out'
  select @error_msg = @response
end
else if @icvrespflag = 'Y'
begin
  select @approvecode= Right( Left( @response, 8 ), 6 )
  if datalength( @response ) > 11 
  begin
    select @tempstr = Right( Left( @response, 15 ),8 )

    if @tempstr is not NULL select @referenceno = @tempstr
    select @tempstr = Right( Left( @response, 17 ), 1 )
		
    if @tempstr is not null select @avs_result = @tempstr
  end
  else
  begin
    select @avs_result = NULL
    select @referenceno = NULL
  end

  if @transtype = 'C6' select @response = 'Approved: ' + @approvecode, @icvrespflag = 'A'
  if @transtype = 'C4' select @response = 'Booked: ' + @approvecode, @icvrespflag = 'B'
  if @transtype in ('CO','C1') select @response = 'Shipped: ' + @approvecode, @icvrespflag = 'S'
  if @transtype = 'C3' select @response = 'Credited: ' + @approvecode, @icvrespflag = 'C'

  select @error_msg = @response
end
else
begin
  if Datalength( @response ) > 0 
    select @rejectrsn = @response
  else
    select @rejectrsn = 'Unknown reason'

  select @error_msg =  'Transaction not completed successfully. ' + @rejectrsn
end

-- Determine if record exists in icv_orders
select @count = isnull((select count(*) from icv_orders where order_no = @order_no and ext = @order_ext),0)

-- Determine if record exists in icv_ccinfo
select @count2 = isnull((select count(*) from icv_ccinfo
			 where customer_code = @cust_key and ship_to_code = '' and address_type = 0 and payment_code = @pay_code),0)

-- Get maximum sequence number for order
select @auth_sequence = isnull((select max( auth_sequence )
				from icv_ord_payment_dtl
				where order_no = @order_no and ext = @order_ext),0) + 1

-- Update payment header
if @count > 0
  update icv_orders
  set cc_status = @icvrespflag
  where order_no = @order_no and ext = @order_ext
else
  insert into icv_orders( order_no, ext, cc_status )
  values( @order_no, @order_ext, @icvrespflag )

-- Update payment detail history
insert into icv_ord_payment_dtl
(order_no, ext, sequence, auth_sequence,response_flag, rej_reason, approval_code,reference_no,avs_result, proc_date, ord_amt, trans_type)
values( @order_no, @order_ext, 1, @auth_sequence, @icvrespflag, @rejectrsn, @approvecode,
	@referenceno, @avs_result, getdate(), @ld_total, @transtype )

-- Update payment info for order
select @count = isnull((select count(*)
			from ord_payment
			where order_no = @order_no and order_ext = @order_ext),0)
if @count > 0 
begin
  select @ord_pmt_seq = isnull((select max( seq_no )
				from ord_payment
				where order_no = @order_no and order_ext = @order_ext),0)

  if @icvrespflag = 'S' 
    update ord_payment
    set amt_payment = @ld_total, prompt4_inp = left(@response,30)
    where order_no = @order_no and order_ext = @order_ext and seq_no = @ord_pmt_seq 
  else
    update ord_payment
    set prompt4_inp = left(@response, 30)
    where order_no = @order_no and order_ext = @order_ext and seq_no = @ord_pmt_seq
end

if @icvrespflag in ('A','B','S')
begin
  -- Set customer defaults for orders
  if exists (select 1 from config (nolock) where flag = 'ICV_CUST_DFLTS' and upper(left(value_str,1)) = 'Y')
  begin
    if @count2 > 0
      update icv_ccinfo
      set payment_code = @pay_code, prompt1 = @name, prompt2 = @acctno, prompt3 = @expire
      where customer_code = @cust_key and ship_to_code = '' and address_type = 0
    else
      insert into icv_ccinfo( customer_code, ship_to_code, address_type, payment_code, sequence_id, prompt1,
			      prompt2, prompt3, prompt4, preload )
      values( @cust_key, '', 0, @pay_code, 0, @name, @acctno, @expire, '', 1 )
  end
  select @retcode = 1
end
-- Credit return
else if @icvrespflag = 'C'
  select @retcode = 1
-- Rejected
else if @icvrespflag = 'N'
begin
  select @retcode = 0
  if exists (select 1 from config (nolock) where upper(flag) = 'ICV_AUTO_SHIP' and upper(left(value_str,1)) = 'N')
  begin
    if exists (select 1 from config (nolock) where upper(flag) = 'ICV_FAIL_SHIP' and upper(left(value_str,1)) = 'Y')
    begin
      update ord_payment
      set amt_payment = 0
      where order_no = @order_no and order_ext = @order_ext
    end
  end
  else
    select @icv_reject = 1
end
-- Unspecific error
else
  select @retcode = -2, @icv_reject = 1

return_processing:

if isnull(@is_stat,'') = 'N' and @icv_reject = 1
begin
  if @module = 'SHP'
  begin
    update orders_all
    set status = 'A', printed = 'N', hold_reason = isnull((select value_str from config (nolock) where flag = 'ICV_HLD_CODE'),NULL)
    where order_no = @order_no and ext = @order_ext
  end
  if @module = 'CR'
  begin
    update orders_all
    set status = 'N', printed = 'N'
    where order_no = @order_no and ext = @order_ext
  end
end

return @retcode
GO
GRANT EXECUTE ON  [dbo].[adm_icverify] TO [public]
GO
