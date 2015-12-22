SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create proc [dbo].[adm_cca_saveaccts_sp] @order_no int, @order_ext int, @customer_code varchar(10), @payment_code varchar (10),@acc varchar(255)
as
begin

exec ccasaveaccts_sp  @order_no, @order_ext, '', 0, @customer_code, @payment_code, @acc, 0
end

GO
GRANT EXECUTE ON  [dbo].[adm_cca_saveaccts_sp] TO [public]
GO
