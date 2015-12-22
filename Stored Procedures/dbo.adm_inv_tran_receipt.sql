SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[adm_inv_tran_receipt] @action varchar(30), @i_tran_no int, @i_tran_ext int, @i_tran_line int,
@i_part_no varchar(30), @i_location varchar(10), @typ char(1), @m_status char(1),
@i_inv_quantity decimal(20,8) OUT, @i_conv_factor decimal(20,8), @i_apply_date datetime, @i_status char(1), 
@i_tran_data varchar(255) OUT, @i_update_ind int OUT, @COGS int, @in_stock decimal(20,8) OUT,
@i_mtrl_cost decimal(20,8) OUT, @i_dir_cost decimal(20,8) OUT, @i_ovhd_cost decimal(20,8) OUT, @i_util_cost decimal(20,8) OUT, 
@unitcost decimal(20,8) OUT, @direct decimal(20,8) OUT, @overhead decimal(20,8) OUT, @utility decimal(20,8) OUT,
@cl_account varchar(10) OUT, @i_update_typ char(1) OUT, @layer_qty decimal(20,8) OUT, @skip_costing int OUT,
@d_qc_flag char(1) OUT, @i_qc_flag char(1) OUT, @i_qty decimal(20,8) OUT,
@i_trigger char(1) OUT, @i_cost decimal(20,8) OUT
AS
BEGIN
  declare @rc int, @chgtyp char(1), @a_process char(1),
    @a_inv_qty decimal(20,8), @l_layer_qty decimal(20,8), @a_skip int, @part_type char(1),
    @l_mtrl_cost decimal(20,8), @l_dir_cost decimal(20,8), @l_ovhd_cost decimal(20,8), @l_util_cost decimal(20,8),
    @l_labor_cost decimal(20,8), @i_nonrec_tax decimal(20,8)

  select @rc =  -1

  if @action = 'start of adm_inv_tran' -- start of adm_inv_tran
  begin
    select 
      @a_process = isnull(left(@i_tran_data,1),'I'),
      @i_qc_flag = isnull(substring(@i_tran_data,2,1),'N'),
      @part_type = isnull(substring(@i_tran_data,3,1),'P'),
      @d_qc_flag = isnull(substring(@i_tran_data,4,1),'N')

    select @i_trigger = @a_process
    if @i_qc_flag = 'Y'
      select @cl_account = 'QC', @i_update_ind = 1, @in_stock = 0, @i_update_typ = 'Q'
    
    if @a_process = 'U'
    begin
      select @chgtyp = isnull(substring(@i_tran_data,5,1),'I')
      select @a_inv_qty = isnull(convert(decimal(20,8),substring(@i_tran_data,6,30)),0)
      select @a_skip = isnull(convert(int,substring(@i_tran_data,36,1)),0)
      select @i_qty = isnull(convert(decimal(20,8),substring(@i_tran_data,37,30)),@i_inv_quantity)
      select @i_cost = isnull(convert(decimal(20,8),substring(@i_tran_data,67,30)),0)
      select @i_nonrec_tax = isnull(convert(decimal(20,8),substring(@i_tran_data,97,30)),0)
      if @chgtyp = 'C'
        select @i_update_typ = 'C'

      if @a_inv_qty != 0
        select @i_inv_quantity = @a_inv_qty

      select @skip_costing = @a_skip
      select @i_cost = @i_qty * @i_cost + @i_nonrec_tax

      if @typ = 'E'
      begin
        insert #cost_lots (lot_ser, qty, cl_qty, lot_qty)
        select lot_ser, sum(qty), 
          case when (@chgtyp = 'I' and @d_qc_flag != 'Y') then -1 else 0 end,
          sum(qty)
        from lot_bin_recv 
        where tran_no = @i_tran_no
        group by lot_ser
        order by lot_ser

        if @chgtyp = 'C' and @i_qc_flag != 'Y'
         update #cost_lots set qty = 0

        if @chgtyp = 'I' and @d_qc_flag != 'Y'  -- qty change
        begin
          insert #cost_lots (lot_ser, qty, cl_qty, lot_qty)
          select lot_ser, sum(-qty) , -1, 0
          from lot_cost_layers 
          where tran_code = 'R' and tran_no = @i_tran_no and tran_ext = @i_tran_ext
            and line_no = @i_tran_line and part_no = @i_part_no and location = @i_location
          group by lot_ser

          insert #cost_lots (lot_ser, qty, cl_qty, lot_qty)
          select lot_ser, sum(qty), 0, sum(lot_qty)
          from #cost_lots
          group by lot_ser
          order by lot_ser
          delete #cost_lots where cl_qty < 0 or qty = 0
        end
      end
    end
    else
    begin
      select @i_qty = @i_inv_quantity, @i_cost = @i_mtrl_cost -- * @i_inv_quantity

      if @typ = 'E'
        insert #cost_lots (lot_ser, qty, cl_qty,lot_qty)
        select lot_ser, sum(qty), 0, sum(qty)
        from lot_bin_recv 
        where tran_no = @i_tran_no
        group by lot_ser
        order by lot_ser
    end

    select @rc = 1

    if @typ = 'E' --and (@i_qc_flag != 'Y' and @d_qc_flag != 'Y')
    begin
      if @chgtyp != 'C'
      begin
        if isnull((select sum(qty) from #cost_lots),0) != @i_inv_quantity
          select @rc = -2
      end
      else
      begin
        if isnull((select sum(lot_qty) from #cost_lots),0) != @i_inv_quantity
          select @rc = -2
      end
    end
    select @layer_qty = 0										-- mls 5/9/01 SCR 26911
    if (@i_qc_flag != 'Y' and @d_qc_flag != 'Y') and @typ = 'W'
    begin												-- mls 5/9/01 SCR 26911
      --Get Current qty that exists in the inventory layer for this receipts
      select @l_layer_qty = 0
      exec adm_cost_check @i_part_no, @i_location, 0, 'R', @i_tran_no, @i_tran_ext, @i_tran_line,'STOCK', @l_layer_qty OUT	
      select @layer_qty = @l_layer_qty
    end


    if @part_type = 'M'
      select @i_update_ind = -1

  end
  if @action = 'after costing' -- update transaction
  begin
    if @i_update_ind = 1 and @i_qc_flag = 'Y'
      select @i_update_typ = 'Q'

    select @rc = 1
  end
  if @action = 'end of adm_inv_tran' -- update inventory
  begin
    select @l_dir_cost = 0,
      @l_ovhd_cost = 0,
      @l_util_cost = 0,
      @l_labor_cost = 0
    select @l_mtrl_cost = r.unit_cost / conv_factor
    from receipts_all r where receipt_no = @i_tran_no

    delete from lot_cost_layers
    where tran_code = 'R' and tran_no = @i_tran_no and tran_ext = @i_tran_ext
      and line_no = @i_tran_line and part_no = @i_part_no and location = @i_location
    insert lot_cost_layers (location,part_no,lot_ser,tran_code,tran_no,tran_ext,line_no,qty,
      mtrl_cost, dir_cost, ovhd_cost, util_cost, labor_cost)
    select @i_location,@i_part_no,l.lot_ser,'R',@i_tran_no,@i_tran_ext,@i_tran_line,sum(l.qty * l.direction),
      (@l_mtrl_cost * sum(l.qty * l.direction)), @l_dir_cost, @l_ovhd_cost, @l_util_cost, @l_labor_cost
    from lot_bin_recv l
    where l.tran_no = @i_tran_no and l.tran_ext = @i_tran_ext and l.line_no = @i_tran_line and
      l.part_no = @i_part_no and l.location = @i_location
    group by l.lot_ser
  
    -- pass back to the receipts trigger the COGS qty of the transaction and the negative cost used
    select @i_tran_data = 
      convert(varchar(30),@i_inv_quantity) + replicate(' ',30 - datalength(convert(varchar(30),@i_inv_quantity))) +
      convert(varchar(30),@unitcost) + replicate(' ',30 - datalength(convert(varchar(30),@unitcost))) +
      convert(varchar(30),@direct) + replicate(' ',30 - datalength(convert(varchar(30),@direct))) +
      convert(varchar(30),@overhead) + replicate(' ',30 - datalength(convert(varchar(30),@overhead))) +
      convert(varchar(30),@utility) + replicate(' ',30 - datalength(convert(varchar(30),@utility))) 
    select @rc = 1
  end

  RETURN @rc
END
GO
GRANT EXECUTE ON  [dbo].[adm_inv_tran_receipt] TO [public]
GO
