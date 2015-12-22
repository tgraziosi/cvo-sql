SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[adm_inv_tran_issue] @action varchar(30), @i_tran_no int, @i_part_no varchar(30), @i_location varchar(10), 
@i_inv_quantity decimal(20,8), @i_apply_date datetime, @i_tran_data varchar(255), 
@i_update_ind int OUT, @COGS int, @in_stock decimal(20,8), @i_typ char(1),
@i_mtrl_cost decimal(20,8) OUT, @i_dir_cost decimal(20,8) OUT, @i_ovhd_cost decimal(20,8) OUT, @i_util_cost decimal(20,8) OUT, 
@unitcost decimal(20,8) OUT, @direct decimal(20,8) OUT, @overhead decimal(20,8) OUT, @utility decimal(20,8) OUT,
@update_typ char(1) OUT
AS
BEGIN
  declare @rc int, @a_code varchar(8)
  select @rc = -1

  if @action = 'start of adm_inv_tran' -- start of adm_inv_tran
  begin
    if left(@i_tran_data,4) = 'XFR ' -- or substring(@i_tran_data,9,1) = 'Q'
      select @i_update_ind = -1

    if substring(@i_tran_data,9,1) = 'Q' 
      select @update_typ = 'Q'

    select @rc = 1

    if @i_update_ind >= 0
    begin
      if @i_typ = 'E'
      begin
        insert #cost_lots (lot_ser, qty, cl_qty)
        select lot_ser, sum(qty * direction ), 0
        from lot_serial_bin_issue
        where tran_no = @i_tran_no
        group by lot_ser
        order by lot_ser

	if @@rowcount = 0
          select @rc = -2
      end
    end
  end
  if @action = 'after costing' and @i_update_ind >= 0 -- update transaction
  begin
    select @rc = 1
  end
  if @action = 'end of adm_inv_tran' -- update inventory
  begin
    if (@i_update_ind >= 0 and substring(@i_tran_data,9,1) != 'Q') or left(@i_tran_data,4) = 'XFR '
    begin
      select @rc = 1
      update inv_list 
      set issued_mtd=(issued_mtd + @i_inv_quantity),
        issued_ytd=(issued_ytd + @i_inv_quantity),
        cycle_date = case when left(@i_tran_data,4) = 'CYC ' then @i_apply_date else cycle_date end,
        qc_qty = qc_qty - case when substring(@i_tran_data,10,1) = 'Q' then @i_inv_quantity else 0 end
      where part_no=@i_part_no and location=@i_location
      if @@error != 0
        select @rc = -2

      exec @rc = adm_inv_mtd_upd @i_part_no, @i_location, 'I', @i_inv_quantity
      select @rc = case when @rc < 1 then -2 else 1 end
    end
    if substring(@i_tran_data,9,1) = 'Q'
    begin
      select @rc = 1
     update inv_list 
      set qc_qty = isnull(qc_qty,0) + @i_inv_quantity
      where part_no=@i_part_no and location=@i_location
      if @@error != 0
        select @rc = -2
    end
    if  @i_update_ind < 0
    begin 
      select @i_mtrl_cost = 0, @i_dir_cost = 0, @i_ovhd_cost = 0, @i_util_cost = 0,
        @unitcost = 0, @direct = 0, @overhead = 0, @utility = 0
    end
  end

  RETURN @rc
END

GO
GRANT EXECUTE ON  [dbo].[adm_inv_tran_issue] TO [public]
GO
