CREATE TABLE [dbo].[lc_alloc_cost_to]
(
[timestamp] [timestamp] NOT NULL,
[allocation_no] [int] NOT NULL,
[voucher_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[receipt_no] [int] NOT NULL,
[cost_to_cd] [char] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cost_to_amt] [money] NOT NULL,
[item] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[prorate_factor] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[row_id] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t700inslcallocct] ON [dbo].[lc_alloc_cost_to] FOR insert AS 
BEGIN

DECLARE @i_allocation_no int, @i_voucher_no varchar(16), @i_receipt_no int, @i_cost_to_cd char(3),
@i_cost_to_amt money, @i_item varchar(30), @i_account_code varchar(32),
@i_prorate_factor char(1), @i_reference_code varchar(32), @i_row_id int

declare @tran_date datetime, @operRate decimal(20,8), @part varchar(30), @loc varchar(10),
  @line_descr varchar(50), @a_tran_id int, @in_qty_on_hand decimal(20,8),
  @i_tran_data varchar(255), @retval int,
@overhead decimal(20,8), @unitcost decimal(20,8), @direct decimal(20,8), @utility decimal(20,8),
@COGS int, @in_stock decimal(20,8), @order int,
@msg varchar(255), @company_id int, @natcode varchar(8), @prev_no int, @prev_receipt int

DECLARE t700inslc_a_cursor CURSOR LOCAL STATIC FOR
SELECT case when i.cost_to_cd = 'I' then 1 else 2 end,
i.allocation_no, i.voucher_no, i.receipt_no, i.cost_to_cd, i.cost_to_amt, i.item,
i.account_code, i.prorate_factor, isnull(i.reference_code,''), i.row_id
from inserted i
OPEN t700inslc_a_cursor

if @@cursor_rows = 0
begin
CLOSE t700inslc_a_cursor
DEALLOCATE t700inslc_a_cursor
return
end

SELECT @company_id = company_id,
 @natcode = home_currency
 FROM glco(nolock)
select @a_tran_id = 0, @prev_no = 0, @prev_receipt = 0

FETCH NEXT FROM t700inslc_a_cursor into @order,
@i_allocation_no, @i_voucher_no, @i_receipt_no, @i_cost_to_cd, @i_cost_to_amt, @i_item,
@i_account_code, @i_prorate_factor, @i_reference_code, @i_row_id

While @@FETCH_STATUS = 0
begin

  if @i_cost_to_amt != 0
  begin
    if @order = 1
      select @a_tran_id = 0
    else
      select @a_tran_id = isnull((select max(tran_id) from in_gltrxdet (nolock) 
        where trx_type = 'L' and tran_no = @i_allocation_no),0)

    SELECT @tran_date = isnull((select apply_dt
    from lc_history (nolock) 
    where allocation_no = @i_allocation_no),getdate())

    select @operRate = isnull((select rate_home/rate_oper
    from adm_apvohdr (nolock)
    where trx_ctrl_num = @i_voucher_no),0)

    select @part = part_no, @loc = location
    from receipts_all
    where receipt_no = @i_receipt_no

    select @line_descr =						-- mls 4/22/02 SCR 28686
      case @i_cost_to_cd 
      when 'I' then 'inv_ovhd_acct'
      when 'S' then 'lc_scrap_acct'
      when 'C' then 'ar_cgs_ovhd_acct'
      when 'O' then 'lc_offset_acct'
      else 'lc_misc_acct'
      end

    if @i_cost_to_cd = 'I'
    begin
      select @in_qty_on_hand = isnull((select qty_on_hand
      from lc_alloc_list 
      where allocation_no = @i_allocation_no and voucher_no = @i_voucher_no and receipt_no = @i_receipt_no),0)

      if @in_qty_on_hand != 0
      begin
        select @i_tran_data = 'OHADJ     R0000000000000000000000ADJUST',
          @overhead = @i_cost_to_amt, @unitcost = 0, @direct = 0, @utility = 0

        exec @retval = adm_inv_tran 
          'L', @i_allocation_no, 0, @i_receipt_no, @part, @loc, @in_qty_on_hand, @tran_date, '', 
          0, '', @i_tran_data, DEFAULT, 
          @a_tran_id OUT, @unitcost OUT, @direct OUT, @overhead OUT, @utility OUT,0,
          @COGS OUT, @unitcost OUT, @direct OUT, @overhead OUT, @utility OUT, 0,@in_stock OUT
    
        if @retval <> 1
        begin
          rollback tran
          select @msg = 'Error ([' + convert(varchar(10), @retval) + ']) returned from adm_inv_tran.'
          exec adm_raiserror 83202, @msg
          RETURN
        end
      end -- in_qty_on_hand != 0
      else
        select @i_cost_to_amt = 0
    end

    select @overhead = @i_cost_to_amt
    exec @retval = adm_gl_insert @part,@loc,'L',@i_allocation_no,0,@i_receipt_no,
      @tran_date,1,@overhead,@i_account_code,@natcode,1,@operRate,
      @company_id,DEFAULT,@i_reference_code,
      @a_tran_id, @line_descr							-- mls 4/22/02 SCR 28686

    IF @retval <= 0
    BEGIN
      rollback tran
      exec adm_raiserror 89010, 'Error Inserting GL Costing Record!'
      return
    END
  end -- cost <> 0



FETCH NEXT FROM t700inslc_a_cursor into @order,
@i_allocation_no, @i_voucher_no, @i_receipt_no, @i_cost_to_cd, @i_cost_to_amt, @i_item,
@i_account_code, @i_prorate_factor, @i_reference_code, @i_row_id
end -- while

CLOSE t700inslc_a_cursor
DEALLOCATE t700inslc_a_cursor

END
GO
CREATE UNIQUE NONCLUSTERED INDEX [lc_alloc_cost_to_pk] ON [dbo].[lc_alloc_cost_to] ([allocation_no], [voucher_no], [receipt_no], [cost_to_cd]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [ui_lc_alloc_cost_to] ON [dbo].[lc_alloc_cost_to] ([row_id]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[lc_alloc_cost_to] ADD CONSTRAINT [fk_lc_alloc_ref_90860_lc_alloc] FOREIGN KEY ([allocation_no], [voucher_no], [receipt_no]) REFERENCES [dbo].[lc_alloc_list] ([allocation_no], [voucher_no], [receipt_no])
GO
GRANT REFERENCES ON  [dbo].[lc_alloc_cost_to] TO [public]
GO
GRANT SELECT ON  [dbo].[lc_alloc_cost_to] TO [public]
GO
GRANT INSERT ON  [dbo].[lc_alloc_cost_to] TO [public]
GO
GRANT DELETE ON  [dbo].[lc_alloc_cost_to] TO [public]
GO
GRANT UPDATE ON  [dbo].[lc_alloc_cost_to] TO [public]
GO
