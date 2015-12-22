SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[adm_inv_tran_xfer] @action varchar(30), @i_tran_no int, @i_tran_ext int, @i_tran_line int,
@i_part_no varchar(30), @i_location varchar(10), 
@i_inv_quantity decimal(20,8), @i_conv_factor decimal(20,8), @i_apply_date datetime, @i_status char(1), 
@i_tran_data varchar(255) OUT, @i_update_ind int OUT, @COGS int, @in_stock decimal(20,8), @typ char(1),
@i_mtrl_cost decimal(20,8) OUT, @i_dir_cost decimal(20,8) OUT, @i_ovhd_cost decimal(20,8) OUT, @i_util_cost decimal(20,8) OUT, 
@avg_unitcost decimal(20,8), @avg_direct decimal(20,8), @avg_overhead decimal(20,8), @avg_utility decimal(20,8), @avg_labor decimal(20,8),
@unitcost decimal(20,8) OUT, @direct decimal(20,8) OUT, @overhead decimal(20,8) OUT, @utility decimal(20,8) OUT,
@update_typ char(1) OUT, @hold_qty decimal(20,8) OUT
AS
BEGIN
  declare @rc int
  select @rc = -1

  if @action = 'start of adm_inv_tran' -- start of adm_inv_tran
  begin
    if @i_status not in ('R','S')
      select @i_update_ind = -1

    if @i_status not in ('R','S')
      select @update_typ = 'H'

    if @update_typ = 'H'
      select @hold_qty = @i_inv_quantity
    else
      select @hold_qty = convert(decimal(20,8),substring(@i_tran_data,1,30))

    if @i_status = 'R'
    begin
      if @typ = 'E'
      begin
        insert #cost_lots (lot_ser, qty, cl_qty, lot_qty)
        select lot_ser, sum(qty * direction), 0, sum(qty* direction)
        from lot_bin_xfer
        where tran_no = @i_tran_no and tran_ext = @i_tran_ext and line_no = @i_tran_line
          and part_no = @i_part_no and location = @i_location
        group by lot_ser
        order by lot_ser
      end
    end
    if @i_status = 'S'
    begin
      if @typ = 'E'
      begin
        insert #cost_lots (lot_ser, qty, cl_qty, lot_qty)
        select lot_ser, sum((qty_received * conv_factor) * direction * -1), 0, sum((qty_received *conv_factor) * direction * -1)
        from lot_bin_xfer
        where tran_no = @i_tran_no  and line_no = @i_tran_line
          and part_no = @i_part_no --and location = @i_location
        group by lot_ser
        having sum((qty_received * conv_factor) * direction * -1) != 0
        order by lot_ser

        if @i_inv_quantity > 0
        begin
          update c
          set tot_mtrl_cost = (l.mtrl_cost / l.qty) * c.qty,
            tot_dir_cost = (l.dir_cost / l.qty) * c.qty,
            tot_ovhd_cost = (l.ovhd_cost / l.qty) * c.qty,
            tot_util_cost = (l.util_cost / l.qty) * c.qty
          from #cost_lots c
          join lot_cost_layers l on l.tran_code = 'X' and l.tran_no = @i_tran_no  
            and l.line_no = @i_tran_line and l.part_no = @i_part_no and l.lot_ser = c.lot_ser

          update c
          set tot_mtrl_cost = (@avg_unitcost) * c.qty,
            tot_dir_cost = (@avg_direct)  * c.qty,
            tot_ovhd_cost = (@avg_overhead)  * c.qty,
            tot_util_cost = (@avg_utility)  * c.qty
          from #cost_lots c
          where tot_mtrl_cost is null            

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
    -- return cogs_qty to xfer_list update trigger
    select @i_tran_data = 
      convert(varchar(30),@i_inv_quantity) + replicate(' ',30 - datalength(convert(varchar(30),@i_inv_quantity)))

      delete from lot_cost_layers
      where tran_code = 'X' and tran_no = @i_tran_no 
        and line_no = @i_tran_line and part_no = @i_part_no and location = @i_location

      insert lot_cost_layers (location,part_no,lot_ser,tran_code,tran_no,tran_ext,line_no,qty,
        mtrl_cost, dir_cost, ovhd_cost, util_cost, labor_cost)
      select @i_location,@i_part_no,l.lot_ser,'X',@i_tran_no,@i_tran_ext,@i_tran_line,
        qty, tot_mtrl_cost, tot_dir_cost, tot_ovhd_cost, tot_util_cost, tot_labor_cost
      from #cost_lots l

    select @rc = 1
  end

  RETURN @rc
END
GO
GRANT EXECUTE ON  [dbo].[adm_inv_tran_xfer] TO [public]
GO
