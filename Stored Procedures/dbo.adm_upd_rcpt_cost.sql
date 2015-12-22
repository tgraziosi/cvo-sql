SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE Procedure [dbo].[adm_upd_rcpt_cost] @rcpt_no int, @A_old_qty decimal(20,8), @dunit_cost decimal(20,8), 
@dtaxincl decimal(20,8), @dconvf decimal(20,8), @daccount varchar(10), @dqc  char(1), @errmsg varchar(100) OUT
AS
BEGIN

-- NOTE: This proc is no longer used and should not be called from anywhere due to changes in costing
-- All costing should be done through adm_inv_tran stored proc.

DECLARE @qty_chg decimal(20,8), @adj_account varchar(10), @stk_acct_ind char (1)	-- mls 7/8/99	SCR 70 20153


DECLARE @posting_code varchar(8)
DECLARE @pur_acct   varchar(32),@var_acct     varchar(32),@inv_acct   varchar(32),@homecode   varchar(8)
DECLARE @direct_acct varchar(32),@ovhd_acct  varchar(32),@util_acct    varchar(32),@i_account   varchar(32)
DECLARE @recv_acct varchar(32),@po_no      varchar(10) ,@reference_code varchar(8), @part_no varchar(30)

DECLARE @company_id int, @iloop int, @typ char(1)


DECLARE @stdutil decimal(20,8),@varmatl   decimal(20,8), @E_invdelta  decimal(20,8)
DECLARE @stdcost   decimal(20,8), @stddirect decimal(20,8), @stdovhd   decimal(20,8), @cost    decimal(20,8)
DECLARE @qty       decimal(20,8), @B_old_cost  decimal(20,8), @D_new_cost  decimal(20,8), @F_prdelta  decimal(20,8)  

DECLARE @AA_layer_cost decimal(20,8), @G_layerbal decimal(20,8),@M_RA_amt decimal(20,8)
DECLARE @L_fg_amt decimal(20,8), @adj_typ varchar(4)
DECLARE @Z_qty decimal(20,8), @Z_cost decimal(20,8), @Z_bal decimal(20,8)

DECLARE @retval int,@iqc char(1), @part varchar(30), @loc varchar(10), 
	@C_new_qty decimal(20,8),@tran_code char(1), @tran_no int, @tran_ext int, @iaccount varchar(10), 
	@tran_date datetime, @tran_age datetime, @direct decimal(20,8), @overhead decimal(20,8),
	@labor decimal(20,8), @utility decimal(20,8) ,
  @line_descr varchar(50)							-- mls 4/25/02 SCR 28686

DECLARE @po_line int									-- mls 5/15/01 SCR 6603
declare @a_tran_id int

SELECT @company_id   = company_id,
       @homecode     = home_currency
 from glco



select @adj_account=isnull((select value_str from config where flag='ADJ_STOCK_ACCOUNT'),'ADJUST')	
select @stk_acct_ind = 'N'										



if exists (select * from receipts_all where receipt_no=@rcpt_no and qc_flag='Y')
 BEGIN
	select @iaccount=isnull((select value_str from config where flag='QC_STOCK_ACCOUNT'),'QC')
 END 
ELSE
 BEGIN
	select @iaccount=isnull((select value_str from config where flag='INV_STOCK_ACCOUNT'),'STOCK')
	select @stk_acct_ind = 'Y'									
 END





 
if NOT exists (select * from receipts_all, inv_list l where receipt_no=@rcpt_no and
	l.part_no=receipts_all.part_no and l.location=receipts_all.location)
BEGIN
	select @iaccount=isnull((select value_str from config where flag='INV_MISC_ACCOUNT'),'MISC')
	select @iaccount=(select min(@iaccount+convert(varchar(10),prod_no)) from receipts_all where
		receipt_no=@rcpt_no) 
	select @stk_acct_ind = 'Y'									
END

SELECT @part       = i.part_no,
       @loc        = i.location,
       @C_new_qty  = (i.quantity * i.conv_factor),                       
       @tran_code  = 'R',
       @tran_no    = @rcpt_no,
       @tran_ext   = 0,
       @tran_date  = getdate(),
       @tran_age   = recv_date,
       @stdcost    = i.std_cost,
       @stddirect  = i.std_direct_dolrs,
       @stdovhd    = i.std_ovhd_dolrs,
       @stdutil    = i.std_util_dolrs,
       @direct     = 0,
       @overhead   = 0,
       @utility    = 0,
       @inv_acct   = i.account_no,
       @po_no      = i.po_no,
       @part_no    = i.part_no,
       @B_old_cost = case @A_old_qty
		      WHEN 0 then (@dunit_cost / @dconvf)
		      ELSE ((((@dunit_cost * @A_old_qty) - @dtaxincl) / @A_old_qty) / @dconvf)
		     end,
       @D_new_cost = CASE i.quantity
                      WHEN 0 THEN (i.unit_cost / i.conv_factor)
                      ELSE ((((i.unit_cost * i.quantity) - i.tax_included) / i.quantity) / i.conv_factor)
                     END,
	@po_line   = i.po_line									-- mls 5/15/01 SCR 6603
 FROM receipts_all i,purchase_all(nolock)
 WHERE i.receipt_no = @rcpt_no AND purchase_all.po_no = i.po_no


--Get Current qty that exists in the inventory layer for this receipts
exec @G_layerbal = adm_cost_check @part, @loc, @A_old_qty, @tran_code, @tran_no, @tran_ext,0,@daccount

--Get INV Posting Code and Costing Method
IF NOT exists (select * from receipts_all, inv_list l where receipt_no=@rcpt_no and
    l.part_no=receipts_all.part_no and l.location=receipts_all.location)
 BEGIN
   SELECT @typ = 'A',
          @posting_code = apacct_code
    FROM locations_all (nolock) 
    WHERE location = @loc
 END
ELSE 
 BEGIN
   SELECT @typ = inv_cost_method,
          @posting_code = acct_code
    FROM inventory(nolock) 
    WHERE part_no  = @part AND location = @loc
 END


--Get reference from po line for GL inventory transaction
SELECT @reference_code = isnull(reference_code,'')
  FROM pur_list(nolock)
  WHERE po_no   = @po_no AND part_no = @part_no 
	and line = case when isnull(@po_line,0)=0 then line else @po_line end			-- mls 5/15/01 SCR 6603


--Default to Average
IF @typ NOT IN ('A','F','L','W','S') select @typ='A'

SELECT @pur_acct      = ap_cgp_code,
       @var_acct      = cost_var_code,
       @direct_acct   = cost_var_direct_code,
       @ovhd_acct     = cost_var_ovhd_code,
       @util_acct     = cost_var_util_code,
       @direct_acct   = inv_direct_acct_code,
       @ovhd_acct     = inv_ovhd_acct_code,
       @util_acct     = inv_util_acct_code,
       @recv_acct     = rec_var_code
 FROM in_account(nolock)
 WHERE acct_code = @posting_code



--Set Delta Values for Updates
SELECT @E_invdelta = @C_new_qty  - @A_old_qty,
  @F_prdelta  = @D_new_cost - @B_old_cost

if (@E_invdelta <> 0 or @F_prdelta <> 0) 
BEGIN
  select 
    @Z_cost = 
    CASE when @F_prdelta = 0 then @B_old_cost * -1		--Set for + stock increase = Credit To COGP account
    ELSE @F_prdelta * -1  
    END,
    @Z_qty = CASE when @E_invdelta = 0 then @C_new_qty ELSE @E_invdelta END

  --Insert into Purchase Expense Acct
  exec @retval = adm_gl_insert  @part,@loc,@tran_code,@tran_no,@tran_ext,0,
    @tran_date, @Z_qty, @Z_cost,@pur_acct,@homecode,DEFAULT,DEFAULT,@company_id,
    DEFAULT, DEFAULT, @a_tran_id, 'ap_cgp_acct'

  IF @retval <= 0
  BEGIN
    select @errmsg = 'Error Inserting GL Costing Record! (pur exp acct)'
    return -1
  END

  IF @typ in ('S','W')
  BEGIN  
    IF @E_invdelta <> 0 --If qty change
    BEGIN  
      IF (@E_invdelta + @G_layerbal) <= 0 					
      BEGIN
        SELECT @qty = CASE WHEN @E_invdelta < 0 then (@G_layerbal * -1) else @G_layerbal END
      END
      ELSE
      BEGIN 
        select @qty = @E_invdelta
      END									

      --Inventory/Receipt Adjustment Accounts   
      --We do a inv trans if delta is a positive increase and a receipt adjust if a decrease in qty

      SELECT @iloop = 1
  
      WHILE @iloop <= 4
      BEGIN 
        Select @cost = 
          CASE @iloop
          WHEN 1 THEN @stdcost   
          WHEN 2 THEN @stddirect 
          WHEN 3 THEN @stdovhd   
          WHEN 4 THEN @stdutil   
          END,
          @i_account = 
          CASE @iloop
          WHEN 1 THEN @inv_acct
          WHEN 2 THEN @direct_acct
          WHEN 3 THEN @ovhd_acct
          WHEN 4 THEN @util_acct
          END,
          @line_descr = 
          CASE @iloop
          WHEN 1 THEN 'inv_acct'
          WHEN 2 THEN 'inv_direct_acct'
          WHEN 3 THEN 'inv_ovhd_acct'
          WHEN 4 THEN 'inv_util_acct'
          END

             
        IF @cost <> 0 
        BEGIN
          if @iloop != 1 select @reference_code = ''
                      
          exec @retval = adm_gl_insert  @part,@loc,@tran_code,@tran_no,@tran_ext,0,
  	    @tran_date,@qty,@cost,@i_account,@homecode,DEFAULT,DEFAULT,			
            @company_id,DEFAULT,@reference_code, @a_tran_id, @line_descr
          IF @retval <= 0
          BEGIN
            select @errmsg = 'Error Inserting GL Costing Record! for std cost (' + convert(varchar(2),@iloop) + ')'
            return -1
          END
        END 

        SELECT @iloop = @iloop + 1
      END --While

      IF ((@E_invdelta + @G_layerbal ) < 0)          
      BEGIN
        SELECT @cost = @stdcost + @stddirect + @stdovhd + @stdutil
        SELECT @qty  = (@E_invdelta + @G_layerbal)                    

        --Receipt Adjustment Account         
        EXEC @retval = adm_gl_insert  @part,@loc,@tran_code,@tran_no,@tran_ext,0,

          @tran_date,@qty,@cost,@recv_acct,@homecode,DEFAULT,DEFAULT,@company_id,
          DEFAULT, DEFAULT, @a_tran_id, 'rec_var_acct'

        IF @retval <= 0
        BEGIN
          select @errmsg = 'Error Inserting GL Costing Record! for std cost rcpt adj acct'
          return -1
        END
      END

      --Standard Cost Variance Account
      IF (@stdcost + @stddirect + @stdovhd + @stdutil) != @D_new_cost
      BEGIN
        SELECT @varmatl = @D_new_cost  - (@stdcost + @stddirect + @stdovhd + @stdutil)

        exec @retval = adm_gl_insert  @part,@loc,@tran_code,@tran_no,@tran_ext,0,
          @tran_date,@E_invdelta,@varmatl,@var_acct,@homecode,DEFAULT,DEFAULT,@company_id,
          DEFAULT, DEFAULT, @a_tran_id, 'cost_var_acct'

        IF @retval <= 0
        BEGIN
          select @errmsg = 'Error Inserting GL Costing Record! for std cost var acct'
          return -1
        END
      END --STANDARD Cost Variance Insert
    END -- (Inventory Change)       

    IF @F_prdelta <> 0 --(Price Change)
    BEGIN
      --Standard Cost Variance Account
      IF (@stdcost + @stddirect + @stdovhd + @stdutil) != @D_new_cost
      BEGIN
        SELECT @varmatl = ( @D_new_cost - @B_old_cost)


        exec @retval = adm_gl_insert  @part,@loc,@tran_code,@tran_no,@tran_ext,0,
          @tran_date, @Z_qty,@varmatl,@var_acct,@homecode,DEFAULT,DEFAULT, @company_id,
          DEFAULT, DEFAULT, @a_tran_id,'cost_var_acct'
        IF @retval <= 0
        BEGIN
          select @errmsg = 'Error Inserting GL Costing Record! for std cost prchg var acct'
          return -1
        END
      END --STANDARD Cost Variance Insert
      ELSE
      BEGIN
        SELECT @varmatl = ( @D_new_cost - @B_old_cost)  

        exec @retval = adm_gl_insert  @part,@loc,@tran_code,@tran_no,@tran_ext,0,
          @tran_date,@Z_qty,@varmatl,@var_acct,@homecode,DEFAULT,DEFAULT,@company_id,
          DEFAULT, DEFAULT, @a_tran_id, 'rec_var_acct'
        IF @retval <= 0
        BEGIN
          select @errmsg = 'Error Inserting GL Costing Record! for std cost var acct'
          return -1
        END
      END --STANDARD Cost Variance Insert
    END --IF @prch = 0 (Price Change)
  END -- @typ = 'S' or 'W'

  IF @typ in ('A','L','F')
  BEGIN        
    select @AA_layer_cost = isnull((select sum(unit_cost * balance)
      FROM inv_costing
      WHERE part_no = @part and location = @loc and account = @daccount and 
        tran_no = @tran_no and tran_ext = @tran_ext and tran_line= 0 and 
        tran_code= @tran_code),0)

    select @Z_qty = case when @E_invdelta = 0 then @G_layerbal else @E_invdelta end
    select @Z_cost = 
      CASE WHEN @E_invdelta = 0 then @F_prdelta 
      WHEN (@E_invdelta + @G_layerbal) <= 0 then (@G_layerbal * @B_old_cost * -1) / @E_invdelta
      ELSE ((@AA_layer_cost * (@A_old_qty - @G_layerbal)) + (@E_invdelta * @B_old_cost)) / @E_invdelta
      END
    select @Z_bal = 
      CASE WHEN @E_invdelta > 0 then @E_invdelta
      WHEN @G_layerbal <> 0 then @E_invdelta
      ELSE 0 
      END +
      CASE WHEN @E_invdelta <> 0 and (@E_invdelta + @G_layerbal) > 0 
        THEN (CASE WHEN @G_layerbal > 0 then @A_old_qty else 0 END) - @G_layerbal
      ELSE 0
      END

    select @L_fg_amt = 
      (CASE WHEN @E_invdelta + @G_layerbal <= 0 then
        CASE WHEN @E_invdelta < 0 then @G_layerbal * -1 else @G_layerbal END 
      ELSE @E_invdelta END * @D_new_cost) +
      (CASE WHEN @G_layerbal - @A_old_qty >= 0 then @A_old_qty else @G_layerbal END * @F_prdelta)

    select @M_RA_amt = 
      (CASE WHEN @E_invdelta + @G_layerbal < 0 then @E_invdelta else 0 END * @D_new_cost) +
      (CASE WHEN @G_layerbal - @A_old_qty < 0 then @A_old_qty - @G_layerbal else 0 END * @F_prdelta)

    --Insert into Inventory Acct
    exec @retval = adm_gl_insert  @part,@loc,@tran_code,@tran_no,@tran_ext,0,
      @tran_date,1,@L_fg_amt,@inv_acct,@homecode,DEFAULT,DEFAULT,@company_id,DEFAULT,@reference_code,
          DEFAULT, DEFAULT, @a_tran_id, 'inv_acct'


    IF @retval <= 0
    BEGIN
      select @errmsg = 'Error Inserting GL Costing Record! for inv acct'
      return -1
    END

    --Insert into Receipt Adjustment Acct
    exec @retval = adm_gl_insert @part,@loc,@tran_code,@tran_no,@tran_ext,0,
      @tran_date,1,@M_RA_amt,@recv_acct,@homecode,DEFAULT,DEFAULT,@company_id,
          DEFAULT, DEFAULT, @a_tran_id, 'rec_var_acct'

    IF @retval <= 0
    BEGIN
      select @errmsg = 'Error Inserting GL Costing Record! for rcpt adj acct'
      return -1
    END

    if @daccount = @iaccount and @stk_acct_ind = 'Y'
    begin
      select @adj_typ = CASE WHEN @E_invdelta = 0 then 'PADJ' else 'IADJ' end

      exec @retval=adm_cost_adjust @part,@loc, @Z_qty, @Z_bal, @tran_code, @tran_no, @tran_ext, 0, 
        @adj_account, @tran_date, @tran_age, @Z_cost, @direct, @overhead, 0, @utility, @iaccount, @adj_typ

      IF @retval=0 
      BEGIN
        select @errmsg = 'Error from adm_cost_adjust'
        return -1
      END
    end
  END --@tyop = 'A','f','l'

  if @daccount <> @iaccount or @stk_acct_ind = 'N'				
  begin
    --Do ADM Cost Layer DELETE

    select @qty = 0
    select @Z_cost = 0

    IF (@E_invdelta <> 0)
    BEGIN
      select @qty = 0
      select @cost = @D_new_cost
      if @G_layerbal >= abs(@E_invdelta) select @qty = abs(@E_invdelta)
      if @G_layerbal < abs(@E_invdelta) select @qty = @G_layerbal
    END

    IF @qty != 0
    BEGIN
      --Delta costing Layer for the QTY that we found!
      exec @retval=fs_cost_delete @part,@loc,@qty,@tran_code, @tran_no, @tran_ext, 0, @daccount, @tran_date,
        @tran_age, @cost, @direct, @overhead, 0, @utility
    
      IF @retval=0 
      BEGIN
        select @errmsg = 'Error returned from fs_cost_delete'
        return -1
      END
    END

    --Do ADM Cost Layer INSERT
    select @qty = 0

    IF @E_invdelta > 0 
    BEGIN
      if @G_layerbal < abs(@E_invdelta)  select @qty = @C_new_qty - @G_layerbal
      if @G_layerbal >= abs(@E_invdelta) select @qty = @C_new_qty
      select @cost = @D_new_cost
    END

    if @qty > 0
    BEGIN
      --Delta costing Layer for the QTY that we found!
      exec @retval=fs_cost_insert @part,@loc,@qty,@tran_code, @tran_no, @tran_ext, 0, @iaccount, @tran_date,
                                   @tran_age, @cost, @direct, @overhead, 0, @utility
      IF @retval=0 
      BEGIN
        select @errmsg = 'Error returned from fs_cost_insert'
        return -1
      END
    END
  END -- dacct <> iacct or stk_acct_ind = 'N'						
end -- (@E_invdelta <> 0 or @F_prdelta <> 0

ELSE --Have an update to receipts but nothing to the qty or price So check if it is the QC update and update cost layers
BEGIN

  SELECT @iqc  = i.qc_flag FROM receipts_all i WHERE i.receipt_no = @rcpt_no

  if (@dqc = 'Y' and @iqc = 'F')
  begin
    --Delta costing Layer for the QTY that we found!
    exec @retval=fs_cost_delete @part,@loc,@A_old_qty,@tran_code, @tran_no, @tran_ext, 0, @daccount, @tran_date,
      @tran_age, @B_old_cost, @direct, @overhead, 0, @utility
    
    IF @retval=0 
    BEGIN
        select @errmsg = 'Error returned from fs_cost_delete'
        return -1
    END

    --Delta costing Layer for the QTY that we found!
    exec @retval=fs_cost_insert @part,@loc,@C_new_qty,@tran_code, @tran_no, @tran_ext, 0, @iaccount, @tran_date,
      @tran_age, @D_new_cost, @direct, @overhead, 0, @utility
     
    IF @retval=0 
    BEGIN
        select @errmsg = 'Error returned from fs_cost_insert'
        return -1
    END
  END
END

return 1
END
GO
GRANT EXECUTE ON  [dbo].[adm_upd_rcpt_cost] TO [public]
GO
