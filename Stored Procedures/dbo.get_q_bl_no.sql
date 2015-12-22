SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[get_q_bl_no] @strsort varchar(30), @sort char(1), @blno int, @btype char(1)  AS

set rowcount 100
declare @x int, @dt datetime

if (@strsort is not null) begin
  	
  if @sort='C' begin
    select distinct bol.bl_no, bill_to_code, bill_to_name, 
           bol_list.order_no, bol_list.order_ext,
           bol.date_entered, bol.date_shipped, bol.bl_type
    from   bol, bol_list
    where  (bol.bl_no = bol_list.bl_no) and
           (bol.bill_to_code >= @strsort) AND (bol.bl_no >= @blno) and
           bol.bl_type like @btype
   order by bol.bill_to_code,bol.bl_no
  end		
  	
  if @sort='D' begin
    select @dt=convert(datetime,@strsort)
    select distinct bol.bl_no, bill_to_code, bill_to_name, 
           bol_list.order_no, bol_list.order_ext,
           bol.date_entered, bol.date_shipped, bol.bl_type
    from   bol, bol_list
    where  (bol.bl_no = bol_list.bl_no) and
           (bol.date_shipped >= @dt) AND (bol.bl_no >= @blno) and
           bol.bl_type like @btype
   order by bol.date_shipped,bol.bl_no
  end		
  	
  if @sort='N' begin
    select @x=convert(int,@strsort)
    select distinct bol.bl_no, bill_to_code, bill_to_name, 
           bol_list.order_no, bol_list.order_ext,
           bol.date_entered, bol.date_shipped, bol.bl_type
    from   bol, bol_list
    where  (bol.bl_no = bol_list.bl_no) and
           (bol.bl_no >= @x)  and bol.bl_type like @btype
    order by bol.bl_no
  end		
  	
  if @sort='O' begin
    select @x=convert(int,@strsort)
    select distinct bol.bl_no, bill_to_code, bill_to_name, 
           bol_list.order_no, bol_list.order_ext,
           bol.date_entered, bol.date_shipped, bol.bl_type
    from   bol, bol_list
    where  (bol.bl_no = bol_list.bl_no) and
           (bol_list.order_no >= @x) and bol.bl_type like @btype
    order by bol_list.order_no,bol.bl_no
  end		
  	
  if @sort='S' begin
    select distinct bol.bl_no, bill_to_code, bill_to_name, 
           bol_list.order_no, bol_list.order_ext,
           bol.date_entered, bol.date_shipped, bol.bl_type
    from   bol, bol_list
    where  (bol.bl_no = bol_list.bl_no) and
           (bill_to_name >= @strsort) AND (bol.bl_no >= @blno) and 
           bol.bl_type like @btype
    order by bol.bill_to_name,bol.bl_no
  end		
end  

if (@strsort is null) begin
  	
  if @sort='O' begin
    select distinct bol.bl_no, bill_to_code, bill_to_name, 
           bol_list.order_no, bol_list.order_ext,
           bol.date_entered, bol.date_shipped, bol.bl_type
    from   bol, bol_list
    where  (bol.bl_no = bol_list.bl_no) and
           (bol_list.order_no >= 0) and 
           bol.bl_type like @btype 
    order by bol_list.order_no,bol.bl_no
  end		
  	
  if @sort='D' begin
    select @dt=convert(datetime,'01/01/90 00:00:00')
    select distinct bol.bl_no, bill_to_code, bill_to_name, 
           bol_list.order_no, bol_list.order_ext,
           bol.date_entered, bol.date_shipped, bol.bl_type
    from   bol, bol_list
    where  (bol.bl_no = bol_list.bl_no) and
           (bol.date_shipped >= @dt) AND (bol.bl_no >= @blno) and
           bol.bl_type like @btype
   order by bol.date_shipped,bol.bl_no
  end		
  	
  if @sort='N' begin
    select distinct bol.bl_no, bill_to_code, bill_to_name, 
           bol_list.order_no, bol_list.order_ext,
           bol.date_entered, bol.date_shipped, bol.bl_type
    from   bol, bol_list
    where  (bol.bl_no = bol_list.bl_no) and
           (bol.bl_no >= 0) and 
           bol.bl_type like @btype
    order by bol.bl_no
  end		
  	
  if @sort='S' begin
    select distinct bol.bl_no, bill_to_code, bill_to_name, 
           bol_list.order_no, bol_list.order_ext,
           bol.date_entered, bol.date_shipped, bol.bl_type
    from   bol, bol_list
    where  (bol.bl_no = bol_list.bl_no) and
           ( (bill_to_name >= ' ') or (bill_to_name is null) ) AND 
           (bol.bl_no >= @blno) and 
           bol.bl_type like @btype
    order by bol.bill_to_name,bol.bl_no
  end		
  if @sort='C' begin
    select distinct bol.bl_no, bill_to_code, bill_to_name, 
           bol_list.order_no, bol_list.order_ext,
           bol.date_entered, bol.date_shipped, bol.bl_type
    from   bol, bol_list
    where  (bol.bl_no = bol_list.bl_no) and
           (bill_to_code >= ' ') AND (bol.bl_no >= @blno) and 
           bol.bl_type like @btype 
    order by bill_to_code,bol.bl_no
  end		
end

GO
GRANT EXECUTE ON  [dbo].[get_q_bl_no] TO [public]
GO
