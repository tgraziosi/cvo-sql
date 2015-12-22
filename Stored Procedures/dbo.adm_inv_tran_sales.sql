SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[adm_inv_tran_sales] @action varchar(30), @i_tran_no int, @i_tran_ext int, @i_tran_line int,
@i_part_no varchar(30), @i_location varchar(10), 
@i_inv_quantity decimal(20,8), @i_conv_factor decimal(20,8), @i_apply_date datetime, @i_status char(1), 
@i_tran_data varchar(255), @i_update_ind int OUT, @COGS int, @in_stock decimal(20,8),
@i_mtrl_cost decimal(20,8) OUT, @i_dir_cost decimal(20,8) OUT, @i_ovhd_cost decimal(20,8) OUT, @i_util_cost decimal(20,8) OUT, 
@unitcost decimal(20,8) OUT, @direct decimal(20,8) OUT, @overhead decimal(20,8) OUT, @utility decimal(20,8) OUT,
@update_typ char(1) OUT, @hold_qty decimal(20,8) OUT, @typ char(1) = '',
@avg_unitcost decimal(20,8), @avg_direct decimal(20,8), @avg_overhead decimal(20,8), @avg_utility decimal(20,8), @avg_labor decimal(20,8),
@std_unitcost decimal(20,8), @std_direct decimal(20,8), @std_overhead decimal(20,8), @std_utility decimal(20,8), @std_labor decimal(20,8),
@process_typ char(1) OUT
AS
BEGIN
  declare @rc int, @temp_qty decimal(20,8), @l_in_stock decimal(20,8),
    @l_mtrl_cost decimal(20,8), @l_dir_cost decimal(20,8), @l_ovhd_cost decimal(20,8), @l_util_cost decimal(20,8),
    @l_labor_cost decimal(20,8)

  select @rc =  -1

  if @action = 'start of adm_inv_tran' -- start of adm_inv_tran
  begin
    if @i_status != 'S' or left(@i_tran_data,1) not in ('P','V','J')
      select @i_update_ind = -1

    if @i_status = 'S' and left(@i_tran_data,1) = 'J'
      select @i_update_ind = 2

    if @i_status != 'S' and left(@i_tran_data,1) in ('P','V')
      select @update_typ = 'H'

    if @update_typ = 'H'
      select @hold_qty = @i_inv_quantity
    else
      select @hold_qty = convert(decimal(20,8),substring(@i_tran_data,2,30))


    if @i_status = 'S'
    begin
      if @typ = 'E'
      begin
        insert #cost_lots (lot_ser, qty, cl_qty, lot_qty)
        select lot_ser, sum(qty * direction), 0, sum(qty* direction)
        from lot_bin_ship
        where tran_no = @i_tran_no and tran_ext = @i_tran_ext and line_no = @i_tran_line
          and part_no = @i_part_no and location = @i_location
        group by lot_ser
        order by lot_ser

        if @i_inv_quantity > 0
        begin
          if (@i_mtrl_cost != 0 or @i_dir_cost != 0 or @i_ovhd_cost != 0 or @i_util_cost != 0)
          begin
            declare @orig_no int, @orig_ext int
            select @orig_no = orig_no, @orig_ext = orig_ext
            from orders_all where order_no = @i_tran_no and ext = @i_tran_ext

            if @orig_no != 0
            begin
              update c
              set tot_mtrl_cost = (l.mtrl_cost / l.qty) * c.qty,
                tot_dir_cost = (l.dir_cost / l.qty) * c.qty,
                tot_ovhd_cost = (l.ovhd_cost / l.qty) * c.qty,
                tot_util_cost = (l.util_cost / l.qty) * c.qty
              from #cost_lots c
              join lot_cost_layers l on l.tran_code = 'S' and l.tran_no = @orig_no and l.tran_ext = @orig_ext
                and l.line_no = @i_tran_line and l.part_no = @i_part_no and l.lot_ser = c.lot_ser
            end
            update c
            set tot_mtrl_cost = (@i_mtrl_cost / @i_inv_quantity) * c.qty,
              tot_dir_cost = (@i_dir_cost / @i_inv_quantity)  * c.qty,
              tot_ovhd_cost = (@i_ovhd_cost / @i_inv_quantity)  * c.qty,
              tot_util_cost = (@i_util_cost / @i_inv_quantity)  * c.qty
            from #cost_lots c
            where tot_mtrl_cost is null            
          end
          else
          begin
            if (@avg_unitcost != 0 or @avg_direct != 0 or @avg_overhead != 0 or @avg_utility != 0 or @avg_labor != 0)
              select @l_mtrl_cost = @avg_unitcost, @l_dir_cost = @avg_direct , 
                 @l_ovhd_cost = @avg_overhead , @l_util_cost = @avg_utility , @l_labor_cost = @avg_labor ,
                 @process_typ = 'A'
            else
              select @l_mtrl_cost = @std_unitcost , @l_dir_cost = @std_direct , 
                @l_ovhd_cost = @std_overhead , @l_util_cost = @std_utility , @l_labor_cost = @std_labor ,
                @process_typ = 'S'

            update c
            set tot_mtrl_cost = @l_mtrl_cost * c.qty,
              tot_dir_cost = @l_dir_cost * c.qty,
              tot_ovhd_cost = @l_ovhd_cost * c.qty,
              tot_util_cost = @l_util_cost * c.qty
            from #cost_lots c
            where tot_mtrl_cost is null
          end

          select @i_mtrl_cost = sum(tot_mtrl_cost),
            @i_dir_cost = sum(tot_dir_cost),
            @i_ovhd_cost = sum(tot_ovhd_cost),
            @i_util_cost = sum(tot_util_cost)
          from #cost_lots
        end
      end
    end
    select @rc = 1
  end

  if @action = 'end of adm_inv_tran' -- update inventory
  begin
    if @i_status = 'S' and @typ = 'E'
    begin
      delete from lot_cost_layers
      where tran_code = 'S' and tran_no = @i_tran_no and tran_ext = @i_tran_ext
        and line_no = @i_tran_line and part_no = @i_part_no and location = @i_location
      insert lot_cost_layers (location,part_no,lot_ser,tran_code,tran_no,tran_ext,line_no,qty,
        mtrl_cost, dir_cost, ovhd_cost, util_cost, labor_cost)
      select @i_location,@i_part_no,lot_ser,'S',@i_tran_no,@i_tran_ext,@i_tran_line,qty,
        tot_mtrl_cost, tot_dir_cost, tot_ovhd_cost, tot_util_cost, tot_labor_cost
      from #cost_lots

      -- pass back to the receipts trigger the COGS qty of the transaction and the negative cost used
      select @i_tran_data = 
        convert(varchar(30),@i_inv_quantity) + replicate(' ',30 - datalength(convert(varchar(30),@i_inv_quantity))) +
        convert(varchar(30),@unitcost) + replicate(' ',30 - datalength(convert(varchar(30),@unitcost))) +
        convert(varchar(30),@direct) + replicate(' ',30 - datalength(convert(varchar(30),@direct))) +
        convert(varchar(30),@overhead) + replicate(' ',30 - datalength(convert(varchar(30),@overhead))) +
        convert(varchar(30),@utility) + replicate(' ',30 - datalength(convert(varchar(30),@utility))) 
    end
    select @rc = 1
  end

  RETURN @rc
END
GO
GRANT EXECUTE ON  [dbo].[adm_inv_tran_sales] TO [public]
GO
