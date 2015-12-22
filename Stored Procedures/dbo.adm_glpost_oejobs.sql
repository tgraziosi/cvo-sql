SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



create procedure [dbo].[adm_glpost_oejobs] @process_ctrl_num varchar(32),@user varchar(32), @err int OUT AS

BEGIN

Declare @xlp int, @order int, @ext int,@line_no int, @jobno int, @errcode int, @glmethod int

select @xlp = isnull((select min(invoice_no) from orders_all where process_ctrl_num = @process_ctrl_num),0)

if @xlp = 0
begin
 select @err = 1
 return 1 --Nothing Found to Process
end

SELECT @glmethod = indirect_flag FROM dbo.glco (nolock)

WHILE @xlp != 0
 BEGIN

 --Get Order Number for Ord List Processing
 select @order = order_no,
 @ext = ext 
 from orders_all (nolock)
 where invoice_no = @xlp


 --Get Ord list Line No for Looping Thru Ord List Records
 select @line_no = (select min(line_no) from ord_list where order_no = @order and order_ext = @ext and part_type = 'J')

 WHILE @line_no != 0 
 BEGIN

 select @jobno=0
 select @jobno=isnull((select convert(int,ord_list.part_no)
 from ord_list (nolock)
 where ord_list.order_no = @order and
 ord_list.order_ext = @ext and
 ord_list.line_no = @line_no),0)

-- select @jobno

 if @jobno != 0 
 BEGIN
	 --Post GL Transaction's
 exec adm_process_gl @user,@glmethod,'P',@jobno,0,@errcode OUT

--select @errcode

 if @errcode != 1 
 begin 
 select @err = -100
 return
 end 
 END 

 select @line_no = isnull((select min(line_no) from ord_list where order_no = @order and order_ext = @ext and part_type = 'J' and line_no > @line_no),0)
 END --WHile @line_no != 0
 select @xlp = isnull((select min(invoice_no) from orders_all where process_ctrl_num = @process_ctrl_num and invoice_no > @xlp),0)
 END--While @xlp !=0

-- select @err = 1								   mls 4/21/99 EPR08022

exec adm_glpost_oeautokits @process_ctrl_num, @user, @err OUT			-- mls 4/21/99 EPR08022

END --EOP
GO
GRANT EXECUTE ON  [dbo].[adm_glpost_oejobs] TO [public]
GO
