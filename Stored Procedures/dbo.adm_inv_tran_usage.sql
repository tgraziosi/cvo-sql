SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[adm_inv_tran_usage] @action varchar(30), @i_tran_no int, @i_tran_ext int, @i_tran_line int,
@i_part_no varchar(30), @i_location varchar(10), @typ char(1) OUT, @m_status char(1),
@i_inv_quantity decimal(20,8), @i_conv_factor decimal(20,8), @i_apply_date datetime, @i_status char(1), 
@i_tran_data varchar(255), @i_update_ind int OUT, @COGS int, @in_stock decimal(20,8) OUT,
@i_mtrl_cost decimal(20,8) OUT, @i_dir_cost decimal(20,8) OUT, @i_ovhd_cost decimal(20,8) OUT, @i_util_cost decimal(20,8) OUT, 
@unitcost decimal(20,8) OUT, @direct decimal(20,8) OUT, @overhead decimal(20,8) OUT, @utility decimal(20,8) OUT,
@cl_account varchar(10) OUT
AS
BEGIN
set nocount on
  declare @rc int, @part_type char(1), @prod_type char(1),
    @sub_com_cost_ind int, @resource_cost_ind int, @plan_qty decimal(20,8),
    @i_used_qty decimal(20,8), @d_used_qty decimal(20,8),
    @avg_cost decimal(20,8), @avg_dir_cost decimal(20,8), @avg_ovhd_cost decimal(20,8), @avg_util_cost decimal(20,8),
    @temp_qty decimal(20,8)

  select @part_type = left(@i_tran_data,1),
    @prod_type = substring(@i_tran_data,2,1),
    @sub_com_cost_ind = convert(int,substring(@i_tran_data,3,1)),
    @resource_cost_ind = convert(int,substring(@i_tran_data,4,1)),
    @plan_qty = convert(decimal(20,8),substring(@i_tran_data,5,30)),
    @i_used_qty = convert(decimal(20,8),substring(@i_tran_data,35,30)),
    @d_used_qty = convert(decimal(20,8),substring(@i_tran_data,65,30))

  select @rc =  -1

  if @action = 'start of adm_inv_tran' -- start of adm_inv_tran
  begin
    if @part_type = 'X'
    begin
      select @cl_account = left('MISC' + convert(varchar(10),@i_tran_no),10),
        @i_update_ind = 2
    end

    if @m_status = 'R'  
    begin
      select @typ = 'S', @i_update_ind = 2

      if @i_inv_quantity > 0 and @resource_cost_ind = 0 -- not reversing resource cost
        select @i_update_ind = -2
    end

    select @avg_cost = @i_mtrl_cost,
      @avg_dir_cost = @i_dir_cost, @avg_ovhd_cost = @i_ovhd_cost, @avg_util_cost = @i_util_cost

    if @typ='S' 
    begin
      select @i_mtrl_cost = @unitcost * @i_inv_quantity, @i_dir_cost = @direct * @i_inv_quantity, 
        @i_ovhd_cost = @overhead * @i_inv_quantity, @i_util_cost = @utility * @i_inv_quantity
    end
    if @typ !='S' and @i_update_ind >= 0
    begin
      
      
      if @i_inv_quantity > 0
      begin
        if (@i_used_qty > 0 or @d_used_qty > 0)         
        begin
          if @typ = 'E'
          begin
            insert #cost_lots (lot_ser, qty, cl_qty, lot_qty, tot_mtrl_cost,tot_ovhd_cost,tot_dir_cost,tot_util_cost,tot_labor_cost)
            select lot_ser, sum(qty * direction), -1, 0,0,0,0,0,0
            from lot_bin_prod 
            where tran_no = @i_tran_no and tran_ext = @i_tran_ext and
              line_no = @i_tran_line and part_no = @i_part_no and location = @i_location
            group by lot_ser
            order by lot_ser

            insert #cost_lots (lot_ser, qty, cl_qty, lot_qty, tot_mtrl_cost,tot_ovhd_cost,tot_dir_cost,tot_util_cost,tot_labor_cost)
            select lot_ser, sum(-qty) , -1, sum(-qty), sum(-mtrl_cost),sum(-ovhd_cost),sum(-dir_cost),sum(-util_cost), sum(-labor_cost)
            from lot_cost_layers 
            where tran_code = 'U' and tran_no = @i_tran_no and tran_ext = @i_tran_ext
              and line_no = @i_tran_line and part_no = @i_part_no and location = @i_location
            group by lot_ser

            insert #cost_lots (lot_ser, qty, cl_qty, lot_qty, tot_mtrl_cost,tot_ovhd_cost,tot_dir_cost,tot_util_cost,tot_labor_cost)
            select lot_ser, sum(qty), 0, sum(lot_qty),sum(tot_mtrl_cost),sum(tot_ovhd_cost),sum(tot_dir_cost),sum(tot_util_cost), sum(tot_labor_cost)
            from #cost_lots
            group by lot_ser
            order by lot_ser

            delete #cost_lots where cl_qty < 0 or qty = 0
          end -- typ = E

          if @typ != 'E'
          begin
            select @temp_qty = 0
            select @i_mtrl_cost = sum(isnull(tot_mtrl_cost,(cost * qty))),
              @i_dir_cost = sum(isnull(tot_dir_cost,(direct_dolrs * qty))),
              @i_ovhd_cost = sum(isnull(tot_ovhd_cost,(ovhd_dolrs * qty))),
              @i_util_cost = sum(isnull(tot_util_cost,(util_dolrs * qty))),
              @temp_qty = sum(qty)
            from prod_list_cost (nolock)
            where prod_no = @i_tran_no and prod_ext = @i_tran_ext and line_no = @i_tran_line

            if @@rowcount = 0 or @temp_qty = 0					-- mls 8/30/06 SCR 36927
              select @i_mtrl_cost = 0, @i_dir_cost = 0, @i_ovhd_cost = 0, @i_util_cost = 0 , @temp_qty = 0
            else
            begin
              select @i_mtrl_cost = (@i_mtrl_cost * @i_inv_quantity) ,
                @i_dir_cost = @i_dir_cost * @i_inv_quantity ,
                @i_ovhd_cost = @i_ovhd_cost * @i_inv_quantity ,
                @i_util_cost = @i_util_cost * @i_inv_quantity
              select @i_mtrl_cost = (@i_mtrl_cost / @temp_qty) ,
                @i_dir_cost = @i_dir_cost / @temp_qty ,
                @i_ovhd_cost = @i_ovhd_cost / @temp_qty ,
                @i_util_cost = @i_util_cost / @temp_qty
            end
          end -- typ != E
          else
          begin
            select @temp_qty = 0
            select @i_mtrl_cost = sum(tot_mtrl_cost),
              @i_dir_cost = sum(tot_dir_cost),
              @i_ovhd_cost = sum(tot_ovhd_cost),
              @i_util_cost = sum(tot_util_cost),
              @temp_qty = sum(lot_qty)
            from #cost_lots (nolock)

            if @@rowcount = 0
              select @i_mtrl_cost = 0, @i_dir_cost = 0, @i_ovhd_cost = 0, @i_util_cost = 0 , @temp_qty = 0
            else
            begin
              select @i_mtrl_cost = (@i_mtrl_cost * @i_inv_quantity) ,
                @i_dir_cost = @i_dir_cost * @i_inv_quantity ,
                @i_ovhd_cost = @i_ovhd_cost * @i_inv_quantity ,
                @i_util_cost = @i_util_cost * @i_inv_quantity
              select @i_mtrl_cost = (@i_mtrl_cost / @temp_qty) ,
                @i_dir_cost = @i_dir_cost / @temp_qty ,
                @i_ovhd_cost = @i_ovhd_cost / @temp_qty ,
                @i_util_cost = @i_util_cost / @temp_qty

              update #cost_lots
                set tot_mtrl_cost = tot_mtrl_cost / lot_qty * qty,
                  tot_dir_cost = tot_dir_cost / lot_qty * qty, 
                  tot_ovhd_cost = tot_ovhd_cost / lot_qty * qty,
                  tot_util_cost = tot_util_cost / lot_qty * qty
            end 
          end -- typ = E
        end --(@i_used_qty > 0 or @d_used_qty > 0)                                                                                       
        else
        begin                                                                                        -- mls 1/31/01 SCR 25781 end
          if @typ = 'E'
          begin
            insert #cost_lots (lot_ser, qty, cl_qty, lot_qty, tot_mtrl_cost,tot_ovhd_cost,tot_dir_cost,tot_util_cost,tot_labor_cost)
            select lot_ser, sum(qty * direction), -1, sum(qty * direction), NULL,NULL,NULL,NULL,NULL
            from lot_bin_prod 
            where tran_no = @i_tran_no and tran_ext = @i_tran_ext and
              line_no = @i_tran_line and part_no = @i_part_no and location = @i_location
            group by lot_ser
	    having sum(qty * direction) != 0
            order by lot_ser

update c
set tot_mtrl_cost = (l.mtrl_cost / l.qty) * c.qty,
tot_dir_cost = (l.dir_cost / l.qty) * c.qty,
tot_ovhd_cost = (l.ovhd_cost / l.qty) * c.qty,
tot_util_cost = (l.util_cost / l.qty) * c.qty,
tot_labor_cost = (l.labor_cost / l.qty) * c.qty
from #cost_lots c, lot_cost_layers l, produce_all p
            where l.tran_code = 'U' and l.tran_no = p.orig_prod_no and l.tran_ext = p.orig_prod_ext
              and l.line_no = @i_tran_line and l.part_no = @i_part_no and l.location = @i_location
              and p.prod_no = @i_tran_no and p.prod_ext = @i_tran_ext
and c.lot_ser = l.lot_ser

update c
set tot_mtrl_cost = @avg_cost * c.qty,
tot_dir_cost = @avg_dir_cost * c.qty,
tot_ovhd_cost = @avg_ovhd_cost * c.qty,
tot_util_cost = @avg_util_cost * c.qty,
tot_labor_cost = 0
from #cost_lots c
where c.tot_mtrl_cost is null

          end -- typ = E
          
          select @temp_qty = 0
          if @sub_com_cost_ind != 0
          begin
if @typ != 'E'
begin
            select @i_mtrl_cost = sum(c.cost * c.qty),
              @i_dir_cost = sum(c.direct_dolrs * c.qty),
              @i_ovhd_cost = sum(c.ovhd_dolrs * c.qty),
              @i_util_cost = sum(c.util_dolrs * c.qty),
              @temp_qty = sum(c.qty)
            from produce_all p (nolock)
            join prod_list_cost c (nolock) on c.prod_no = p.orig_prod_no and c.prod_ext = p.orig_prod_ext
              and c.line_no = @i_tran_line
            where p.prod_no = @i_tran_no and p.prod_ext = @i_tran_ext	-- mls 6/22/04

            if isnull(@temp_qty,0) != 0
            begin
              select @i_mtrl_cost = @i_mtrl_cost * @i_inv_quantity / @temp_qty,
                @i_dir_cost = @i_dir_cost * @i_inv_quantity / @temp_qty,
                @i_ovhd_cost = @i_ovhd_cost * @i_inv_quantity / @temp_qty,
                @i_util_cost = @i_util_cost * @i_inv_quantity / @temp_qty
            end                                         
end
else
begin
            select @temp_qty = 0
            select @i_mtrl_cost = sum(tot_mtrl_cost),
              @i_dir_cost = sum(tot_dir_cost),
              @i_ovhd_cost = sum(tot_ovhd_cost),
              @i_util_cost = sum(tot_util_cost),
              @temp_qty = sum(lot_qty)
            from #cost_lots (nolock)

            if @@rowcount = 0 or isnull(@temp_qty,0) = 0
              select @i_mtrl_cost = 0, @i_dir_cost = 0, @i_ovhd_cost = 0, @i_util_cost = 0 , @temp_qty = 0
            else
            begin
              select @i_mtrl_cost = (@i_mtrl_cost * @i_inv_quantity) ,
                @i_dir_cost = @i_dir_cost * @i_inv_quantity ,
                @i_ovhd_cost = @i_ovhd_cost * @i_inv_quantity ,
                @i_util_cost = @i_util_cost * @i_inv_quantity
              select @i_mtrl_cost = (@i_mtrl_cost / @temp_qty) ,
                @i_dir_cost = @i_dir_cost / @temp_qty ,
                @i_ovhd_cost = @i_ovhd_cost / @temp_qty ,
                @i_util_cost = @i_util_cost / @temp_qty

            end 
end -- typ = 'E'
          end -- @sub_com_cost_ind != 0
          if @sub_com_cost_ind = 0 or isnull(@temp_qty,0) = 0
          begin
if @typ = 'E'
update c
set tot_mtrl_cost = @avg_cost * c.qty,
tot_dir_cost = @avg_dir_cost * c.qty,
tot_ovhd_cost = @avg_ovhd_cost * c.qty,
tot_util_cost = @avg_util_cost * c.qty,
tot_labor_cost = 0
from #cost_lots c

            select @i_mtrl_cost = @avg_cost * @i_inv_quantity, @i_dir_cost = @avg_dir_cost * @i_inv_quantity, 
              @i_ovhd_cost = @avg_ovhd_cost * @i_inv_quantity, @i_util_cost = @avg_util_cost * @i_inv_quantity
          end
        end -- not (@i_used_qty > 0 or @d_used_qty > 0)
      end --  @i_inv_quantity > 0
      else
      begin
        if @typ = 'E'
        begin
          insert #cost_lots (lot_ser, qty, cl_qty,lot_qty)
          select lot_ser, sum(qty * direction), -1, sum(qty * direction)
          from lot_bin_prod 
          where tran_no = @i_tran_no and tran_ext = @i_tran_ext and
            line_no = @i_tran_line and part_no = @i_part_no and location = @i_location
          group by lot_ser
          order by lot_ser

          insert #cost_lots (lot_ser, qty, cl_qty, lot_qty)
          select lot_ser, sum(-qty) , -1, 0
          from lot_cost_layers 
          where tran_code = 'U' and tran_no = @i_tran_no and tran_ext = @i_tran_ext
            and line_no = @i_tran_line and part_no = @i_part_no and location = @i_location
          group by lot_ser

          insert #cost_lots (lot_ser, qty, cl_qty, lot_qty)
          select lot_ser, sum(qty), 0, sum(lot_qty)
          from #cost_lots
          group by lot_ser
          order by lot_ser
          delete #cost_lots where cl_qty < 0 or qty = 0

        end

      end -- @i_inv_quantity <= 0
    end -- invmethod != S

    select @rc = 1

    if @typ = 'E' 
    begin
      if isnull((select sum(qty) from #cost_lots),0) != @i_inv_quantity
        select @rc = -2
    end

  end
  if @action = 'after costing' and @i_update_ind >= 0 -- update transaction
  begin
    select @rc = 1
  end
  if @action = 'end of adm_inv_tran' -- update inventory
  begin
    if @typ = 'E'
    begin
      update lcl
      set qty = lcl.qty + c.qty,
        mtrl_cost = mtrl_cost + tot_mtrl_cost,
        dir_cost = dir_cost + tot_dir_cost,
        ovhd_cost = ovhd_cost + tot_ovhd_cost,
        util_cost = util_cost + tot_util_cost,
        labor_cost = labor_cost + tot_labor_cost
      from lot_cost_layers lcl, #cost_lots c 
      where lcl.tran_no = @i_tran_no and lcl.tran_ext = @i_tran_ext and 
        lcl.line_no = @i_tran_line and lcl.location = @i_location and lcl.part_no = @i_part_no
        and lcl.lot_ser = c.lot_ser and lcl.tran_code = 'U' 

      insert lot_cost_layers (location,part_no,lot_ser,tran_code,tran_no,tran_ext,line_no,qty,
        mtrl_cost, dir_cost, ovhd_cost, util_cost, labor_cost)
      select @i_location,@i_part_no,lot_ser,'U',@i_tran_no,@i_tran_ext,@i_tran_line,qty,
        tot_mtrl_cost, tot_dir_cost, tot_ovhd_cost, tot_util_cost, tot_labor_cost
      from #cost_lots c
      where not exists (select 1 from lot_cost_layers lcl
        where lcl.tran_no = @i_tran_no and lcl.tran_ext = @i_tran_ext and 
          lcl.line_no = @i_tran_line and lcl.location = @i_location and lcl.part_no = @i_part_no
          and lcl.lot_ser = c.lot_ser and lcl.tran_code = 'U' )        
    end

    select @rc = 1
  end

  RETURN @rc
END
GO
GRANT EXECUTE ON  [dbo].[adm_inv_tran_usage] TO [public]
GO
