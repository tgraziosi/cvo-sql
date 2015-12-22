SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO





create procedure [dbo].[adm_glpost_oeautokits] @process_ctrl_num varchar(32),@user varchar(32), @err int OUT AS

BEGIN

Declare @xlp int, @order int, @ext int,@part_no varchar(30), @jobno int, @errcode int, @glmethod int

select @xlp = isnull((select min(invoice_no) from orders_all where process_ctrl_num = @process_ctrl_num),NULL)

if @xlp = NULL
begin
 select @err = 1
 return 1 --Nothing Found to Process
end

SELECT @glmethod = indirect_flag FROM dbo.glco (nolock)

WHILE @xlp IS NOT NULL
 BEGIN

 --Get Order Number for Ord List Processing
 select @order = order_no,
	@ext = ext 
 from orders_all (nolock)
 where invoice_no = @xlp and process_ctrl_num = @process_ctrl_num


 --Get Ord list Line No for Looping Thru Ord List Records
 select @part_no = isnull((select min(l.part_no) from ord_list l, inv_master i (nolock) 
	where order_no = @order and order_ext = @ext and l.part_type = 'P' and
	l.part_no = i.part_no and i.status = 'K'),NULL)

 WHILE @part_no is not NULL
 BEGIN

  select @jobno=isnull((select min(tran_no) 
	from in_gltrxdet
	where part_no = @part_no and trx_type = 'P' and posted_flag = 'N'),0)

  WHILE @jobno != 0
  BEGIN
 	 --Post GL Transaction's
    exec adm_process_gl @user,@glmethod,'P',@jobno,0,@errcode OUT

    if @errcode != 1 
    begin 
    select @err = -200
    return
    end 

  select @jobno=isnull((select min(tran_no) 
	from in_gltrxdet
	where part_no = @part_no and trx_type = 'P' and posted_flag = 'N'),0)
  END --While jobno != 0

 select @part_no = isnull((select min(l.part_no) from ord_list l, inv_master i (nolock) 
	where order_no = @order and order_ext = @ext and l.part_type = 'P' and
	l.part_no = i.part_no and i.status = 'K' and l.part_no > @part_no),NULL)
 END --WHile @part_no is not NULL

 select @xlp = isnull((select min(invoice_no) from orders_all where process_ctrl_num = @process_ctrl_num and invoice_no > @xlp),NULL)
 END--While @xlp is not NULL

select @err = 1
END --EOP

GO
GRANT EXECUTE ON  [dbo].[adm_glpost_oeautokits] TO [public]
GO
