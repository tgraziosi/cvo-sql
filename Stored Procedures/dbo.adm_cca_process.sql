SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create proc [dbo].[adm_cca_process] 
@module varchar(10), 
@order_no int, @order_ext int, @ord_total decimal(20,8) = 0, 
@select_ind int = 0,
@processor int = NULL,
@icv_val_cd varchar(20) = NULL,
@ls_status char(1) = NULL,
@icv_type char(1) = NULL,
@cust_key varchar(10) = NULL,
@ll_orig_no int = NULL, 
@ll_orig_ext int = NULL,
@pay_code varchar(8) = NULL,
@name varchar(30) = NULL,
@acctno varchar(30) = NULL,
@expire varchar(30) = NULL,
@ld_disc decimal(20,8) = 0 ,
@icv_cust_dflts char(1) = NULL,
@nat_cur_code varchar(8) = NULL,
@csc_number varchar(5) = ''
as
begin

declare @ld_total decimal(20,8), @message varchar(255)
declare @cc_prefix int					-- mls 3/3/05 SCR 32670
declare @doc_ctrl_num varchar(16)			-- mls 3/24/05 SCR 34444

-- Ensure that a validation code has been entered into the database
if @icv_val_cd is null
  select @icv_val_cd = isnull((select value_str from config (nolock) where flag = 'ICV_VAL_CODE'),'')
if @icv_val_cd = '' 
begin
  if @select_ind = 1
  begin
    select -2, 0, dbo.adm_localize_sqlmsg('ICV_VAL_CODE is not defined on config table.')
  end
  return -2
end

-- Verify status not already shipped
if @ls_status is null
  select @ls_status = isnull((select cc_status from icv_orders (nolock) where order_no = @order_no and ext = @order_ext),'')

if @ls_status = 'S' 
begin
  if @select_ind = 1
  begin
    select -3, 1, dbo.adm_localize_sqlmsg ('Order Already Processed.')
  end
  return 1
end

if @ord_total != 0
  select @ld_total = @ord_total

if @ord_total = 0 or @cust_key is NULL or @nat_cur_code is NULL
begin
  SELECT @ld_total = 
  case when @module = 'CSV' then total_amt_order - tot_ord_disc + tot_ord_tax + tot_ord_freight
    else gross_sales - total_discount + total_tax + freight end,
  @cust_key = cust_code,
  @nat_cur_code = curr_key
  FROM orders_all (nolock)
  WHERE order_no = @order_no AND ext = @order_ext

  if @@error <> 0
  begin
    if @select_ind = 1
    begin
      select -2, 0, dbo.adm_localize_sqlmsg ( 'Error retrieving sales order information')
    end
    return -2
  end 

  if @ord_total != 0
    select @ld_total = @ord_total
end

declare @t_ord int, @t_ext int

-- Obtain payment data
if @module = 'CR'
begin
  if @ll_orig_no is null or @ll_orig_ext is null
  begin
    select @ll_orig_no = orig_no,
      @ll_orig_ext = orig_ext
    from orders_all (nolock)
    where order_no = @order_no and ext = @order_ext

    if isnull(@ll_orig_no,0) <= 0 
    begin
      if @select_ind = 1
      begin
        select -1, 1, dbo.adm_localize_sqlmsg ('Order not a credit card order.')
      end
      return 1
    end
  end

  select @t_ord = @ll_orig_no, @t_ext = @ll_orig_ext
end
else
  select @t_ord = @order_no, @t_ext = @order_ext

if @pay_code is null
begin
  select @pay_code = payment_code,
    @name = prompt1_inp,
    @acctno = prompt2_inp,
    @expire = prompt3_inp,
    @ld_disc = case when @module = 'CR' then 0 else amt_disc_taken end
  from ord_payment (nolock)
  where order_no = @t_ord and order_ext = @t_ext and seq_no = 1

  select @cc_prefix = isnull((select creditcard_prefix from icv_cctype (nolock) where payment_code = @pay_code),NULL)	-- mls 3/3/05 SCR 32670
  if isnull(@cc_prefix,0) = 0					-- mls 3/3/05 SCR 32670
  begin
    update icv_orders
    set cc_status = 'N'
    where order_no = @order_no and ext = @order_ext
	
    delete from icv_ord_payment_dtl where order_no = @order_no and ext = @order_ext
	
    if @select_ind = 1
    begin
      select -1, 1, dbo.adm_localize_sqlmsg ('Order not a credit card order.')
    end
    return 1
  end

  if isnull(@acctno,'') = ''
  begin

    if @select_ind = 1
    begin
      select -2, 1, dbo.adm_localize_sqlmsg ('Account number is not Entered.')
    end
    return -2
  end

  if @acctno not like convert(varchar,@cc_prefix) + '%'		-- mls 3/3/05 SCR 32670
  begin
    if @select_ind = 1
    begin
      select -2, 0, dbo.adm_localize_sqlmsg ('Account Number Prefix is invalid.')
    end
    return -2
  end
end

if isnull(@acctno,'') = ''
begin
  if @select_ind = 1
  begin
    select -1, 1, dbo.adm_localize_sqlmsg ('Order not a credit card order.')
  end
  return 1
end
 	
 -- Confirm CC type
if isnull(@pay_code,'') = ''
begin
  update icv_orders
  set cc_status = 'N'
  where order_no = @order_no and ext = @order_ext
	
  if @select_ind = 1
  begin
    select -1, 1, dbo.adm_localize_sqlmsg ('Order not a credit card order.')
  end
  return 1
end

-- Reduce by discount & verify order total
if isnull(@ld_disc,0) > 0.0 
  select @ld_total = @ld_total - @ld_disc

if @ld_total < .01 
begin
  if @select_ind = 1
  begin
    select -1, 1, dbo.adm_localize_sqlmsg ('Order total less than .01 will not be processed.')
  end
  return 1
end 

-------------------------------------------------------------------------
declare @ccexpmo varchar(2), @ccexpyr varchar(4)
declare @max_seq int, @transtype varchar(2)

select @transtype = ''
if @module = 'CSV'
begin
  if @icv_type is null
    select @icv_type = isnull((select value_str from config(nolock) where flag = 'ICV_ORDER'),'')
  select @transtype = case @icv_type
     when 'A' then 'C6'
     when 'B' then 'C4'
     end
end
if @module = 'SHP'
begin
  if @icv_type is null
    select @icv_type = isnull((select value_str from config(nolock) where flag = 'ICV_SHIP'),'')
  select @transtype = case @icv_type
     when 'A' then case when @ls_status in ('S','B') then '' else 'C6' end
     when 'B' then case when @ls_status in ('S','B') then '' else 'C4' end
     when 'S' then case @ls_status  when 'S' then ''
       when 'B' then 'C0' else 'C1' end
     end
end

if @module = 'PST'
begin
  if @icv_type is null
    select @icv_type = isnull((select value_str from config(nolock) where flag = 'ICV_POST'),'')
  if @icv_type = 'S'
  begin
    if @ls_status = 'N'
    begin
	select @max_seq = isnull((select max(auth_sequence) from icv_ord_payment_dtl (nolock) 
          where order_no = @order_no and ext = @order_ext and response_flag <> 'N'),NULL)
	if @max_seq is not null
	  select @ls_status = response_flag from icv_ord_payment_dtl (nolock) 
            where order_no = @order_no and ext = @order_ext and auth_sequence = @max_seq
    end

    select @transtype = 
      case when @ls_status = 'S' then ''
        when @ls_status = 'B' then 'C0'
        else 'C1'
      end
  end
end
if @module = 'CR'
  select @transtype = 'C3'

if @transtype = ''
begin
  if @select_ind = 1
  begin
    select -3, 1, dbo.adm_localize_sqlmsg ('Trans type not defined.  Order does not need to be processed.')
  end
  return 1
end

if @processor is null
  select @processor = isnull((select configuration_int_value
  from icv_config (nolock) where configuration_item_name = 'Processor Interface'),0)

if @processor not in (1,2)
begin
  if @select_ind = 1
  begin
    select -1, 1, dbo.adm_localize_sqlmsg ('Not a valid Processor Interface.')
  end
  return -1
end

select @ccexpmo = Left( @expire, 2 ),  @ccexpyr = '20' + Right( @expire, 2 )
       
declare @ret int, @response varchar(60), @prompt4_inp varchar(30)


exec @ret = icv_fs_trans @transtype, @acctno, @ccexpmo, @ccexpyr, @ld_total, @response OUT,
  @order_no, @order_ext, '', '', '', @nat_cur_code, 0, @csc_number

select @response = isnull(@response,'')
set @prompt4_inp = ''

if @response = '' 
begin
  if @select_ind = 1
  begin
    select -3, 1, dbo.adm_localize_sqlmsg ('Order does not need to be processed.')
  end
  return 1
end

declare @icvrespflag char(1), @stop int, @rejectrsn varchar(60)
declare @approvecode varchar(30), @avs_result varchar(30),@tempstr varchar(30),@referenceno varchar(30),
  @lpos int

select @icvrespflag = Left( Right( @response, ( Len( @response ) - 1 )), 1 )

if @icvrespflag not in ('N','T','Y')
begin
  if Len( @response ) > 0 
    select @rejectrsn = @response
  else
    select @rejectrsn = dbo.adm_localize_sqlmsg ('Unknown reason')

  select @message = dbo.adm_localize_sqlmsg ('Transaction not completed successfully.  [' + @rejectrsn + ']')
  select @icvrespflag = '?'
end 

if @icvrespflag = 'N'
begin
  While (0=0)
  begin 
    select @response = Right( @response, ( Len( @response ) -1 ))
    if left( @response, 1 ) != 'N'  break
  end
  select @stop = charindex( '"',@response) - 1
  if @stop > -1
    select @rejectrsn = substring( @response, 1, @stop )
  else
    set @rejectrsn = @response
  select @response = @rejectrsn
  select @message = dbo.adm_localize_sqlmsg ('Transaction declined:  [' + @rejectrsn + ']')
  select @prompt4_inp = isnull(@response,'')
end

if @icvrespflag = 'T'
begin
  select @rejectrsn = 'Timed Out',
      @response = dbo.adm_localize_sqlmsg ('Verification request timed out')
  select @message = @response
  select @prompt4_inp = isnull(@response,'')
end

if @icvrespflag = 'Y'
begin
  if @processor = 1 		-- Trustmarque
  begin
    select @approvecode= Right( Left( @response, 8 ), 6 ),
      @avs_result = NULL, @referenceno = NULL

    if len( @response ) > 11
      select @tempstr = Right( Left( @response, 16 ),8 )

    if IsNull( @tempstr,'' ) != '' 
      select @referenceno = @tempstr

    select @tempstr = Right( Left( @response, 17 ), 1 )
    if IsNull( @tempstr,'' ) != ''
      select @avs_result = @tempstr
  end
  if @processor = 2  		-- Verisign
  begin
    select @lpos = charindex('"',@response,2),
      @avs_result = NULL, @referenceno = NULL, @approvecode = NULL
    if @lpos > 0 
    begin

      select @approvecode= substring(@response,3,@lpos - 3)
      select @tempstr = substring(@response,(@lpos + 1),len(@response))
	
      if IsNull( @tempstr,'' ) != ''
        select @referenceno = @tempstr
    end
  end

  select @response = 
    case @transtype
      when 'C6' then 'Approved: '
      when 'C4' then 'Booked: ' 
      when 'C0' then 'Shipped: ' 
      when 'C1' then 'Shipped: ' 
      when 'C3' then 'Credited: ' 
    end + '[' + @approvecode + ']'

  select @icvrespflag = 
    case @transtype
      when 'C6' then 'A'
      when 'C4' then 'B'
      when 'C0' then 'S'
      when 'C1' then 'S'
      when 'C3' then 'C'
    end
  select @message = dbo.adm_localize_sqlmsg (@response)

  select @prompt4_inp = isnull(@approvecode ,'')
end 

------------------------------------------------------------------------------------------------------
--int    count, count2, sequence, auth_sequence, ord_pmt_seq, li_preload
--double retval
--string cust_key
--string cc_status
declare @cc_status char(1)

-- Get maximum sequence number for order
declare @auth_sequence int

select @auth_sequence = isnull((select max( auth_sequence )
from icv_ord_payment_dtl where order_no = @order_no and ext = @order_ext),0) + 1

select @cc_status = case @icvrespflag when 'A' then 'B' else @icvrespflag end

-- Write record to orders
  update icv_orders
  set cc_status = @cc_status 				
  where order_no = @order_no and ext = @order_ext

  if @@rowcount = 0
  begin
    insert into icv_orders( order_no, ext, cc_status )
    values( @order_no, @order_ext, @cc_status )
  end

-- Insert record into payment detail history
insert into icv_ord_payment_dtl
(order_no, ext, sequence, auth_sequence,response_flag, rej_reason, approval_code,reference_no,avs_result, proc_date, ord_amt, trans_type)
values( @order_no, @order_ext, 1, @auth_sequence, @cc_status, left(@rejectrsn,50), @approvecode,
  @referenceno, @avs_result, getdate(), @ld_total, @transtype )


declare @ord_pmt_seq int

select @ord_pmt_seq = isnull((select max( seq_no )
  from ord_payment
  where order_no = @order_no and order_ext = @order_ext),-1)

if @ord_pmt_seq >= 0
begin
  select @doc_ctrl_num = isnull((select reference_no		-- mls 3/24/05 SCR 34444
  from icv_ord_payment_dtl where order_no = @order_no and ext = @order_ext
  and auth_sequence = 0),NULL)

  select @prompt4_inp = @prompt4_inp + case when @referenceno is not null then ':' + @referenceno else '' end	-- mls 12/7/05
  if @icvrespflag = 'S' 
    update ord_payment
    set amt_payment = @ld_total, prompt4_inp = @prompt4_inp,
      doc_ctrl_num = @referenceno				-- mls 3/24/05 SCR 34444
    where order_no = @order_no and order_ext = @order_ext and seq_no = @ord_pmt_seq 
  else
    update ord_payment
    set prompt4_inp = @prompt4_inp,
      doc_ctrl_num = @referenceno				-- mls 3/24/05 SCR 34444
    where order_no = @order_no and order_ext = @order_ext and seq_no = @ord_pmt_seq 
end

declare @retval int
select @retval = -2
if @icvrespflag in ('A','B','S')
begin
  -- Set customer defaults for orders
  if @icv_cust_dflts is null
    select @icv_cust_dflts = isnull((select upper(left(value_str,1)) from config (nolock) where flag = 'ICV_CUST_DFLTS'),'N')

  if @icv_cust_dflts = 'Y'
  begin
    update icv_ccinfo
    set payment_code = @pay_code, prompt1 = @name,
      prompt2 = @acctno, prompt3 = @expire
    where customer_code = @cust_key and ship_to_code = '' and address_type = 0 

    if @@rowcount = 0
    begin

      insert into icv_ccinfo( customer_code, ship_to_code, address_type, payment_code, sequence_id, prompt1,
        prompt2, prompt3, prompt4, preload, trx_ctrl_num, trx_type, order_no, order_ext )
      values( @cust_key, '', 0, @pay_code, 0, @name, @acctno, @expire, '', 1 ,
		'','',0,0 )
    end
  end

  select @retval = 1
end

-- Credit return
if @icvrespflag = 'C'
  select @retval = 1

-- Rejected
if @icvrespflag = 'N'
  select @retval = 0
	

if @select_ind = 1
begin
  select @retval, @ret, @message
end

return @retval
end

GO
GRANT EXECUTE ON  [dbo].[adm_cca_process] TO [public]
GO
