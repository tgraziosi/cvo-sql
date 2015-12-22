CREATE TABLE [dbo].[lc_list]
(
[timestamp] [timestamp] NOT NULL,
[allocation_no] [int] NOT NULL,
[voucher_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[lc_expense_amt] [money] NULL,
[lc_expense_acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lc_offset_acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t700inslclist] ON [dbo].[lc_list] FOR insert AS 
BEGIN

DECLARE @tran_date datetime
DECLARE @i_allocation_no int, @i_voucher_no varchar(16), @i_sequence_id int,
@i_lc_expense_amt money, @i_lc_expense_acct varchar(32), @i_lc_offset_acct varchar(32)
DECLARE @natcode varchar(8), @operRate decimal(20,8)
DECLARE @a_tran_id int

DECLARE @company_id int, @retval int,  @part varchar(30), @loc varchar(10)
DECLARE @org_id varchar(30)

DECLARE t700inslc_l_cursor CURSOR LOCAL STATIC FOR
SELECT i.allocation_no, i.voucher_no, i.sequence_id, isnull(i.lc_expense_amt,0), i.lc_expense_acct,
i.lc_offset_acct
from inserted i

OPEN t700inslc_l_cursor

if @@cursor_rows = 0
begin
CLOSE t700inslc_l_cursor
DEALLOCATE t700inslc_l_cursor
return
end

SELECT @company_id = company_id,
 @natcode = home_currency
 FROM glco(nolock)

FETCH NEXT FROM t700inslc_l_cursor into
@i_allocation_no, @i_voucher_no, @i_sequence_id, @i_lc_expense_amt, @i_lc_expense_acct,
@i_lc_offset_acct

While @@FETCH_STATUS = 0
begin
  SELECT @tran_date = apply_dt,
    @org_id = organization_id
  from lc_history (nolock) 
  where allocation_no = @i_allocation_no

  if @@rowcount = 0
  begin
    rollback tran
    exec adm_raiserror 89001, 'Could not find lc_history header record'
    return
  end    

  if @i_lc_expense_amt <> 0
  begin
    select @operRate = isnull((select rate_home/rate_oper
    from adm_apvohdr (nolock)
    where trx_ctrl_num = @i_voucher_no),0)

    select @part = 'VOUCHER-EXPENSE', @loc = ''

    exec @retval = adm_gl_insert @part,@loc,'L',@i_allocation_no,0,@i_sequence_id,
      @tran_date,1,@i_lc_expense_amt,@i_lc_expense_acct,@natcode,1,@operRate,
      @company_id, DEFAULT, DEFAULT, @a_tran_id, 'lc_expense_acct',					-- mls 4/22/02 SCR 28686
      DEFAULT,DEFAULT, @org_id

    IF @retval <= 0
    BEGIN
      rollback tran
      exec adm_raiserror 89010, 'Error Inserting GL Costing Record!'
      return
    END

    exec @retval = adm_gl_insert @part,@loc,'L',@i_allocation_no,0,@i_sequence_id,
      @tran_date,-1,@i_lc_expense_amt,@i_lc_offset_acct,@natcode,1,@operRate,
      @company_id, DEFAULT, DEFAULT, @a_tran_id, 'lc_offset_acct',					-- mls 4/22/02 SCR 28686
      DEFAULT,DEFAULT, @org_id

    IF @retval <= 0
    BEGIN
      rollback tran
      exec adm_raiserror 89010, 'Error Inserting GL Costing Record!'
      return
    END
  end -- cost <> 0

FETCH NEXT FROM t700inslc_l_cursor into
@i_allocation_no, @i_voucher_no, @i_sequence_id, @i_lc_expense_amt, @i_lc_expense_acct,
@i_lc_offset_acct
end -- while

CLOSE t700inslc_l_cursor
DEALLOCATE t700inslc_l_cursor

END
GO
CREATE UNIQUE CLUSTERED INDEX [ui_lc_list] ON [dbo].[lc_list] ([allocation_no], [voucher_no], [sequence_id]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[lc_list] ADD CONSTRAINT [fk_lc_list_ref_90841_lc_histo] FOREIGN KEY ([allocation_no], [voucher_no]) REFERENCES [dbo].[lc_history] ([allocation_no], [voucher_no])
GO
GRANT REFERENCES ON  [dbo].[lc_list] TO [public]
GO
GRANT SELECT ON  [dbo].[lc_list] TO [public]
GO
GRANT INSERT ON  [dbo].[lc_list] TO [public]
GO
GRANT DELETE ON  [dbo].[lc_list] TO [public]
GO
GRANT UPDATE ON  [dbo].[lc_list] TO [public]
GO
