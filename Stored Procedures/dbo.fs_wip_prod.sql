SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_wip_prod] @prodno int, @tran_no int, @part varchar(30), @loc varchar(10), @qty decimal(20,8) AS
declare @xlp int, @lastlp int , @ext int, @xqty decimal(20,8), @nqty decimal(20,8)

if @qty = 0
  return 1

declare @direction int, @account varchar(10), @part_type char(1),			-- mls 4/25/03 SCR 30972 start
@tran_date datetime, @unitcost decimal(20,8), @conv_factor decimal(20,8), @retval int,
@tempcost decimal(20,8)

select @part_type = part_type,
@tran_date = recv_date,
@unitcost = unit_cost / conv_factor,
@conv_factor = conv_factor
 from receipts_all (nolock) where receipt_no = @tran_no
if @@rowcount = 0
begin
  raiserror 66001 'Not A Valid Receipt Number!'
  return -1
end 											-- mls 4/25/03 SCR 30972 end
	
if @part_type != 'P'
begin
  if exists (select 1 from inv_list l (nolock) where l.part_no=@part and l.location=@loc)
  BEGIN
    raiserror 66001 'Miscellaneous part cannot also be in inventory!'
    return -1
  END
end


select @xqty=(@qty * @conv_factor), @direction = @qty

if not exists (select 1 from produce_all (nolock) where prod_no=@prodno) 
begin
  raiserror 66001 'Not A Valid Production Number!'
  return -1
end 

if not exists (select 1 from produce_all (nolock) where prod_no=@prodno and status >= 'N' and status < 'R') 
begin
  raiserror 66002 'Closed Production Number - Cannot Alter!'
  return -1
end 

if @part_type = 'M' and @direction > 0							-- mls 4/25/03 SCR 30972 start
begin
  select @account=isnull((select value_str from config (nolock) where flag='INV_MISC_ACCOUNT'),'MISC')
  select @account=(select min(@account+convert(varchar(10),@prodno)))

  delete from inv_costing
  where account = @account and part_no = @part and location = @loc
  select @tempcost = @unitcost * @xqty

  exec @retval=	fs_cost_insert @part, @loc, @xqty, 'R', @tran_no, 0, 
    1, @account, @tran_date, @tran_date, @tempcost, 0, 0,0,0 ,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '!','A','Y', 0
end											-- mls 4/25/03 SCR 30972 end

  
  
  
  
  select @ext= isnull((select max(prod_ext) from produce_all (nolock) 
    where prod_no=@prodno and status >= 'N' and status < 'R'),NULL)
  if @ext is null 
  begin
    raiserror 66003 'Production Number Not Found.'
    return -1
  end

  select @lastlp=isnull((select min(line_no) from prod_list (nolock)
    where prod_no=@prodno and prod_ext=@ext and part_no=@part and location=@loc
      and direction < 0),0)
  
  if @lastlp = 0 
  begin
    raiserror 66004 'Part Number Not Found In Production.'
    return -1
  end

  while (@lastlp > 0) 
  begin
    
    if @direction < 0
      select @nqty=isnull((select used_qty
        from prod_list (nolock)
        where prod_no=@prodno and prod_ext=@ext and line_no=@lastlp),0)
    else
      select @nqty=isnull((select (plan_qty - used_qty) 
        from prod_list (nolock)
        where prod_no=@prodno and prod_ext=@ext and line_no=@lastlp),0)

      
    if @nqty >= abs(@xqty)
    begin
      update prod_list 
      set used_qty=used_qty + @xqty
      where prod_no=@prodno and prod_ext=@ext and line_no=@lastlp    
      update prod_list 
      set pieces=pieces + @xqty
      where prod_no=@prodno and prod_ext=@ext and line_no=@lastlp and plan_pcs>0
      select @xqty=0, @lastlp = 0
    end
    else 
    begin
      select @xlp=isnull((select min(line_no) from prod_list (nolock)
        where prod_no=@prodno and prod_ext=@ext and part_no=@part and
        location=@loc and direction < 0 and line_no > @lastlp),0)

      if @nqty > 0 and @xlp != 0
      begin
        update prod_list 
        set used_qty=used_qty + case when @direction < 0 then (@nqty * -1) else @nqty end	-- mls 4/25/03 SCR 30961
        where prod_no=@prodno and prod_ext=@ext and line_no=@lastlp    
        update prod_list  
        set pieces=pieces + case when @direction < 0 then (@nqty * -1) else @nqty end		-- mls 4/25/03 SCR 30961
        where prod_no=@prodno and prod_ext=@ext and line_no=@lastlp and plan_pcs>0
        select @xqty=@xqty - case when @direction < 0 then (@nqty * -1) else @nqty end, 
          @lastlp=@xlp
      end
      else
      begin
        update prod_list 
        set used_qty=used_qty + @xqty							-- mls 4/25/03 SCR 30961
        where prod_no=@prodno and prod_ext=@ext and line_no=@lastlp    
        update prod_list  
        set pieces=pieces + @xqty							-- mls 4/25/03 SCR 30961
        where prod_no=@prodno and prod_ext=@ext and line_no=@lastlp and plan_pcs>0
        select @xqty=0, @lastlp = 0
      end
    end
  end 

  if @direction > 0
    update produce_all set status='P'
      where prod_no=@prodno and prod_ext=@ext and status<'P'

  return 1

GO
GRANT EXECUTE ON  [dbo].[fs_wip_prod] TO [public]
GO
