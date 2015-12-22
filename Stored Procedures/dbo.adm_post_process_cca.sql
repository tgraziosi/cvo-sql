SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE  [dbo].[adm_post_process_cca]
  @order_no int,
  @order_ext int,
  @ord_type char(1),
  @cca_amt decimal(20,8), 
  @cust_key varchar(10),
  @ll_orig_no int,
  @ll_orig_ext int,
  @ls_icv_stat varchar(10) = NULL OUT,
  @icv_val_code varchar(10) = NULL OUT,
  @icv_credit varchar(10) = NULL OUT,
  @icv_type varchar(10) = NULL OUT,
  @icv_cust_dflts char(1)= NULL OUT,
  @processor int = NULL OUT,
  @nat_cur_code varchar(8) = NULL OUT,
  @err_msg varchar(255) OUT
AS
BEGIN
  declare @payment_code varchar(8), @amt_disc_taken decimal(20,8), @cc_prefix int, @ret_code int,
    @name varchar(30), @acctno varchar(30), @expire varchar(30), @ls_status char(1)

  select @err_msg = ''

  if @ls_icv_stat is null
    select @ls_icv_stat = isnull((select upper(value_str) from config (nolock) where flag = 'ICV_POST'),'')

  if @icv_val_code is null
    select @icv_val_code = isnull((select value_str from config (nolock) where flag = 'ICV_VAL_CODE'),'')

  if @icv_credit is NULL
    select @icv_credit = isnull((select upper(value_str) from config (nolock) where flag = 'ICV_CREDIT'),'')

  if @icv_cust_dflts is NULL
    select @icv_cust_dflts = isnull((select upper(left(value_str,1)) from config (nolock) where flag = 'ICV_CUST_DFLTS'),'N')

  if @processor is null
    select @processor = isnull((select configuration_int_value
    from icv_config (nolock) where configuration_item_name = 'Processor Interface'),0)

  if (@ord_type = 'I' and @ls_icv_stat in ('A','S','B')) or
     (@icv_credit like 'Y%' and @ord_type = 'C')
  begin 
    if @icv_val_code = ''
    begin
      select @err_msg = 'ICV_VAL_CODE must be defined'
      return -1
    end

    select @ls_status = isnull((select cc_status from icv_orders (nolock) where order_no = @order_no and ext = @order_ext),'')

    if @ls_status = 'S'
      return 1
  end

  if @ord_type = 'I' and @ls_icv_stat in ('A','S','B')
  begin
    if @icv_type is NULL
      select @icv_type = isnull((select value_str from config(nolock) where flag = 'ICV_POST'),'')

    select @payment_code = payment_code, 
      @name = prompt1_inp,
      @acctno = prompt2_inp,
      @expire = prompt3_inp,
      @amt_disc_taken = amt_disc_taken
    from ord_payment (nolock) where order_no = @order_no and order_ext = @order_ext and seq_no = 1

    if @@rowcount = 0 
      return 1

    if isnull(@payment_code,'') = ''
    begin
      update icv_orders
      set cc_status = 'N'
      where order_no = @order_no and ext = @order_ext

      return 1
    end

    SELECT @cc_prefix = isnull((select creditcard_prefix from icv_cctype (nolock)
    WHERE payment_code = @payment_code),0)

    if @cc_prefix = 0
    begin
      update icv_orders
      set cc_status = 'N'
      where order_no = @order_no and ext = @order_ext

      return 1
    end

    if (@cca_amt - @amt_disc_taken) < .01 
    begin
      select @err_msg = 'After discount taken, the cca order amount is less than .01'
      return -1
    end

    exec @ret_code = adm_cca_process 'PST', @order_no, @order_ext, @cca_amt, 0,
      @processor, @icv_val_code, @ls_status, @icv_type, @cust_key, @ll_orig_no,
      @ll_orig_ext, @payment_code, @name, @acctno, @expire, @amt_disc_taken,
      @icv_cust_dflts, @nat_cur_code

    if @ret_code != 1
    begin
      select @err_msg = 'Error processing credit card info.'
      return @ret_code
    end

    return 1
  end

  if @icv_credit like 'Y%' and @ord_type = 'C'
  begin
    exec @ret_code = adm_cca_process 'CR', @order_no, @order_ext, @cca_amt, 0,
      @processor, @icv_val_code, @ls_status, @icv_type, @cust_key, @ll_orig_no,
      @ll_orig_ext, NULL, NULL, NULL, NULL, NULL, @icv_cust_dflts, @nat_cur_code

    if @ret_code in (0,-2)
    begin
      select @err_msg = 'Error processing credit for credit card info.'
      return @ret_code
    end
  end

  return 1
end 
GO
GRANT EXECUTE ON  [dbo].[adm_post_process_cca] TO [public]
GO
