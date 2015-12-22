SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[adm_inv_tran_produce] @action varchar(30), @i_tran_no int, @i_tran_ext int, @i_tran_line int,
@i_part_no varchar(30), @i_location varchar(10), @typ char(1), @m_status char(1),
@i_inv_quantity decimal(20,8), @i_conv_factor decimal(20,8), @i_apply_date datetime, @i_status char(1), 
@i_tran_data varchar(255), @i_update_ind int OUT, @COGS int, @in_stock decimal(20,8) OUT,
@i_mtrl_cost decimal(20,8) OUT, @i_dir_cost decimal(20,8) OUT, @i_ovhd_cost decimal(20,8) OUT, @i_util_cost decimal(20,8) OUT, 
@unitcost decimal(20,8) OUT, @direct decimal(20,8) OUT, @overhead decimal(20,8) OUT, @utility decimal(20,8) OUT
AS
BEGIN
set nocount on
  declare @rc int, @temp_qty decimal(20,8), @l_in_stock decimal(20,8), @prod_type char(1),
    @fg_cost_ind int, @cost_pct decimal(20,8), @plan_qty decimal(20,8), @used_qty decimal(20,8),
    @avg_cost decimal(20,8), @avg_dir_cost decimal(20,8), @avg_ovhd_cost decimal(20,8), @avg_util_cost decimal(20,8),
    @temp_pct decimal(20,8)

  select @prod_type = left(@i_tran_data,1),
    @fg_cost_ind = convert(int,substring(@i_tran_data,2,1)),
    @cost_pct = convert(decimal(20,8),substring(@i_tran_data,3,30)),
    @plan_qty = convert(decimal(20,8),substring(@i_tran_data,33,30)),
    @used_qty = convert(decimal(20,8),substring(@i_tran_data,63,30))

  select @rc =  -1

  if @action = 'start of adm_inv_tran' -- start of adm_inv_tran
  begin
    if (@i_status in ('P','Q','V') and @prod_type = 'R') or @i_status = 'S'		-- mls 4/15/05 SCR 34533
      select @i_update_ind = 0
    else
      select @i_update_ind = -1

--    if @m_status = 'K' and @in_stock < 0	-- mls 9/9/08 - correct issue when autokit is used on production and goes negative
--      select @in_stock = 0

    select @avg_cost = @i_mtrl_cost,
      @avg_dir_cost = @i_dir_cost, @avg_ovhd_cost = @i_ovhd_cost, @avg_util_cost = @i_util_cost


    if @typ='S' 
    begin
      select @i_mtrl_cost = @unitcost * @i_inv_quantity, @i_dir_cost = @direct * @i_inv_quantity, @i_ovhd_cost = @overhead * @i_inv_quantity,
        @i_util_cost = @utility * @i_inv_quantity		-- mls 11/29/05 SCR 35780
    end
    if @typ !='S' and @i_update_ind >= 0
    begin
      
      
      if @i_inv_quantity > 0
      begin
        if @typ = 'E' and @i_update_ind >= 0
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
          where tran_code = 'P' and tran_no = @i_tran_no and tran_ext = @i_tran_ext
            and line_no = @i_tran_line and part_no = @i_part_no and location = @i_location
          group by lot_ser

          insert #cost_lots (lot_ser, qty, cl_qty, lot_qty)
          select lot_ser, sum(qty), 0, sum(lot_qty)
          from #cost_lots
          group by lot_ser
          order by lot_ser

          delete #cost_lots where cl_qty < 0 or qty = 0

          if isnull((select sum(qty) from #cost_lots),0) != @i_inv_quantity
          begin
            select @rc = -2
            return @rc
          end
        end
        
        if @prod_type = 'R'
        BEGIN
          select @temp_pct = case when @cost_pct = 100 then 1 else @cost_pct end
          select @i_mtrl_cost=p.est_avg_cost / p.qty_scheduled ,	-- mls 11/1/04 SCR 33662
            @i_dir_cost=p.est_direct_dolrs / p.qty_scheduled  ,	-- mls 11/1/04 SCR 33662
            @i_ovhd_cost=p.est_ovhd_dolrs / p.qty_scheduled  ,	-- mls 11/1/04 SCR 33662
            @i_util_cost=p.est_util_dolrs / p.qty_scheduled   	-- mls 11/1/04 SCR 33662
          from produce_all p (nolock)
          where p.prod_no=@i_tran_no and p.prod_ext=@i_tran_ext

--          if @cost_pct != 100
--          begin 
--            select @temp_qty = 100
--            select @i_mtrl_cost = @i_mtrl_cost / @temp_qty, @i_dir_cost = @i_dir_cost / @temp_qty,
--              @i_ovhd_cost = @i_ovhd_cost / @temp_qty, @i_util_cost = @i_util_cost / @temp_qty
--          end

          select @temp_qty = @i_inv_quantity					-- mls 11/1/04 SCR 33662 begin
          select @i_mtrl_cost = @i_mtrl_cost * @temp_qty, @i_dir_cost = @i_dir_cost * @temp_qty,
            @i_ovhd_cost = @i_ovhd_cost * @temp_qty, @i_util_cost = @i_util_cost * @temp_qty
										-- mls 11/1/04 SCR 33662 end
        END
        ELSE 
        BEGIN
          select @temp_pct = case when @cost_pct = 100 then 1 else @cost_pct end
          select @i_mtrl_cost=p.tot_avg_cost * @temp_pct ,
            @i_dir_cost=p.tot_direct_dolrs * @temp_pct ,
            @i_ovhd_cost=p.tot_ovhd_dolrs * @temp_pct ,
            @i_util_cost=p.tot_util_dolrs  * @temp_pct 
          from produce_all p (nolock)
          where p.prod_no=@i_tran_no and p.prod_ext=@i_tran_ext

          if @cost_pct != 100
          begin
            select @temp_qty = 100
            select @i_mtrl_cost = @i_mtrl_cost / @temp_qty, @i_dir_cost = @i_dir_cost / @temp_qty,
              @i_ovhd_cost = @i_ovhd_cost / @temp_qty, @i_util_cost = @i_util_cost / @temp_qty
          end
        END

        if @typ = 'E' and @i_update_ind >= 0
        begin
          update c
          set tot_mtrl_cost = convert(decimal(20,8),convert(decimal(20,8),(@i_mtrl_cost / @i_inv_quantity)) * c.qty),
            tot_dir_cost = convert(decimal(20,8),convert(decimal(20,8),(@i_dir_cost / @i_inv_quantity))  * c.qty),
            tot_ovhd_cost = convert(decimal(20,8),convert(decimal(20,8),(@i_ovhd_cost / @i_inv_quantity))  * c.qty),
            tot_util_cost = convert(decimal(20,8),convert(decimal(20,8),(@i_util_cost / @i_inv_quantity))  * c.qty)
          from #cost_lots c
          where tot_mtrl_cost is null            
        end
      end
      else 
      begin
        if @typ = 'E'
        begin
if @plan_qty > 0 and @used_qty >= 0
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
          where tran_code = 'P' and tran_no = @i_tran_no and tran_ext = @i_tran_ext
            and line_no = @i_tran_line and part_no = @i_part_no and location = @i_location
          group by lot_ser

          insert #cost_lots (lot_ser, qty, cl_qty, lot_qty)
          select lot_ser, sum(qty), 0, sum(lot_qty)
          from #cost_lots
          group by lot_ser
          order by lot_ser

          delete #cost_lots where cl_qty < 0 or qty = 0
end
else
begin
          insert #cost_lots (lot_ser, qty, cl_qty, lot_qty, tot_mtrl_cost,tot_ovhd_cost,tot_dir_cost,tot_util_cost,tot_labor_cost)
          select lot_ser, sum(qty * direction), 0, sum(qty * direction), NULL,NULL,NULL,NULL,NULL
          from lot_bin_prod 
          where tran_no = @i_tran_no and tran_ext = @i_tran_ext and
            line_no = @i_tran_line and part_no = @i_part_no and location = @i_location
          group by lot_ser
          having sum(qty*direction) != 0
          order by lot_ser

          update c
          set tot_mtrl_cost = convert(decimal(20,8),convert(decimal(20,8),(l.mtrl_cost / l.qty)) * c.qty),
            tot_dir_cost = convert(decimal(20,8),convert(decimal(20,8),(l.dir_cost / l.qty)) * c.qty),
            tot_ovhd_cost = convert(decimal(20,8),convert(decimal(20,8),(l.ovhd_cost / l.qty)) * c.qty),
            tot_util_cost = convert(decimal(20,8),convert(decimal(20,8),(l.util_cost / l.qty)) * c.qty),
            tot_labor_cost = convert(decimal(20,8),convert(decimal(20,8),(l.labor_cost / l.qty)) * c.qty)
          from #cost_lots c, lot_cost_layers l, produce_all p
            where l.tran_code = 'P' and l.tran_no = p.orig_prod_no and l.tran_ext = p.orig_prod_ext
              and l.line_no = @i_tran_line and l.part_no = @i_part_no and l.location = @i_location
              and p.prod_no = @i_tran_no and p.prod_ext = @i_tran_ext
              and c.lot_ser = l.lot_ser

          update c
          set tot_mtrl_cost = convert(decimal(20,8),@avg_cost * c.qty),
            tot_dir_cost = convert(decimal(20,8),@avg_dir_cost * c.qty),
            tot_ovhd_cost = convert(decimal(20,8),@avg_ovhd_cost * c.qty),
            tot_util_cost = convert(decimal(20,8),@avg_util_cost * c.qty),
            tot_labor_cost = 0
          from #cost_lots c
          where c.tot_mtrl_cost is null
end

          if isnull((select sum(qty) from #cost_lots),0) != @i_inv_quantity
          begin
            select @rc = -2
            return @rc
          end

        end -- typ = E
        

























































          select @i_mtrl_cost= @avg_cost * @i_inv_quantity, @i_dir_cost= @avg_dir_cost * @i_inv_quantity, 
            @i_ovhd_cost= @avg_ovhd_cost * @i_inv_quantity,
            @i_util_cost= @avg_util_cost * @i_inv_quantity
--        end		
      end -- @i_inv_quantity < 0
    end -- invmethod != S
    select @rc = 1
  end
  if @action = 'after costing' and @i_update_ind >= 0 -- update transaction
  begin
    select @rc = 1
  end
  if @action = 'end of adm_inv_tran' -- update inventory
  begin
    if @typ = 'E' and @i_update_ind >= 0
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
        and lcl.lot_ser = c.lot_ser and lcl.tran_code = 'P' 

      insert lot_cost_layers (location,part_no,lot_ser,tran_code,tran_no,tran_ext,line_no,qty,
        mtrl_cost, dir_cost, ovhd_cost, util_cost, labor_cost)
      select @i_location,@i_part_no,lot_ser,'P',@i_tran_no,@i_tran_ext,@i_tran_line,qty,
        tot_mtrl_cost, tot_dir_cost, tot_ovhd_cost, tot_util_cost, tot_labor_cost
      from #cost_lots c
      where not exists (select 1 from lot_cost_layers lcl
        where lcl.tran_no = @i_tran_no and lcl.tran_ext = @i_tran_ext and 
          lcl.line_no = @i_tran_line and lcl.location = @i_location and lcl.part_no = @i_part_no
          and lcl.lot_ser = c.lot_ser and lcl.tran_code = 'P' )    
    end

    select @rc = 1
  end

  RETURN @rc
END
GO
GRANT EXECUTE ON  [dbo].[adm_inv_tran_produce] TO [public]
GO
