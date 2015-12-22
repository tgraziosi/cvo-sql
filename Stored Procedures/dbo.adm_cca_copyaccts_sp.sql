SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create proc [dbo].[adm_cca_copyaccts_sp] @order_no int, @order_ext int, @orig_no int, @orig_ext int, @online_call int = 1
as
begin
DECLARE @companycode varchar(8), @date_last_used int, @acct_masked varchar(30), @ccnumber varchar(30), @acct_encoded varchar(255)

SELECT @companycode = company_code from glco
SELECT @date_last_used = datediff( day, '01/01/1900', GetDate()) + 693596

select @acct_masked = prompt2_inp
from ord_payment (nolock)
where order_no = @orig_no and order_ext = @orig_ext

if @@rowcount = 0
begin
  if @online_call = 1  select ''
  return 0
end 

DELETE CVO_Control..ccacryptaccts
WHERE   ( order_no = @order_no
	  AND order_ext = @order_ext
          AND company_code = @companycode)
					
INSERT CVO_Control..ccacryptaccts
(company_code, order_no, order_ext, trx_ctrl_num, trx_type, customer_code, ccnumber, date_last_used)
SELECT company_code, @order_no, @order_ext, trx_ctrl_num, trx_type, customer_code, ccnumber, @date_last_used
from CVO_Control..ccacryptaccts
where order_no = @orig_no and order_ext = @orig_ext and company_code = @companycode

if @@rowcount = 0
begin
  if @online_call = 1  select ''
  return 0
end

select @acct_encoded = ccnumber 
from CVO_Control..ccacryptaccts
where order_no = @order_no and order_ext = @order_ext and company_code = @companycode

SELECT @ccnumber = dbo.CCADecryptAcct_fn(@acct_encoded)

if isnull(@ccnumber,'') = ''
begin
  if @online_call = 1  select ''
  return 0
end 

select @acct_masked = dbo.CCAMask_fn(@ccnumber)
if isnull(@acct_masked,'') = ''
begin
  if @online_call = 1  select ''
  return 0
end 

  if @online_call = 1  select @acct_masked
  return 1
end

GO
GRANT EXECUTE ON  [dbo].[adm_cca_copyaccts_sp] TO [public]
GO
