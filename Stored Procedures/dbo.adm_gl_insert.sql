SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO





--3/26/98 JLK
-- Add ABS() to rate calulations...As a negative mean divide and not a real negative rate.
--3/26/98 JLK
-- 10/28/99 MLS
-- Added changes to calculate the operational balance and natural balance correctly.
-- the unitcost that comes into this routine is in home_currency.  To get to the natural currency
-- you need to calculate the rate of conversion and use that to calculate.
-- Also, you need to calculate the operational cost based on the natural balance and the
-- conversion rate.  
-- 10/28/99 MLS
-- 12/20/00 MLS SCR 25339 - changed to fix problem with CASE statements
-- 01/24/01 MLS SCR 20787 - added tran_line to in_gltrxdet
-- 02/09/01 MLS SCR 24318 - corrected problem with wrong divop, divnat when rate did not exist
-- 04/16/01 MLS SCR 26722 - changed to get rate types from vendor if receipt is entered
--                          in another currency from home or oper
-- 04/10/02 MLS SCR 28686 - improve gl/inv reconciliation
-- 08/19/03 MLS SCR 31660 - changed to check transaction edit rules to not allow prior/future postings
-- 01/25/05 MLS SCR 34142 - changed = NULL to is NULL

CREATE PROCEDURE [dbo].[adm_gl_insert] 
 @part           varchar(30),
 @loc            varchar(10),
 @tran_code      char(1),
 @tran_no        int,
 @tran_ext       int=0,
 @tran_line      int=0,
 @tran_date      datetime,
 @qty            decimal(20,8), 
 @unitcost       decimal(20,8),
 @account 	 varchar(32),  
 @nat_cur_code   varchar(8),
 @natural_rate 	 decimal(20,8)=0,
 @oper_rate      decimal(20,8)=0,
 @company_id 	 int,
 @user           varchar(10)='SA',
 @reference_code varchar(32)='',
 @tran_id	 int=0,									-- mls 6/2/03
 @description    varchar(50)=NULL,							-- mls 4/10/02 SCR 28686
 @totcost        decimal(20,8)=NULL, 							-- mls 4/10/02 SCR 28686
 @force          int = 0,								-- mls 4/10/02 SCR 28686
 @org_id         varchar(30) = '',
 @controlling_org_id varchar(30) = ''
AS

DECLARE @seg1          varchar(32),@seg2 varchar(32),         @seg3 varchar(32),         @seg4 varchar(32)
DECLARE @glnat_cur     varchar(8) ,@rate_type_home varchar(8),@rate_type_oper varchar(8)
DECLARE @oper_cur_code varchar(8), @op_rate decimal(20,8),    @home_cur_code varchar(8), @nat_rate decimal(20,8)
DECLARE @dft_rate_type_home varchar(8),@dft_rate_type_oper varchar(8)				-- mls 4/16/01 SCR 26722
DECLARE @allow_prior_posting char(1),
	@allow_future_posting char(1), 
	@allow_range_posting char(1),
	@apply_date_range int

DECLARE @retval int,@divop int, @divnat int, @curr_date int

DECLARE @nat_balance decimal(20,8), @oper_balance decimal(20,8)					-- mls 10/28/99 SCR 70 21589
DECLARE @posted_flag char(1)

declare @active_date int, @inactive_date int,
  @period_end_date int, @msg varchar(100), @val_apply_dt char(1)

BEGIN

select @posted_flag = 'N'							-- mls 4/12/02 SCR 28686

select @totcost = isnull(@totcost, (@unitcost * @qty))				-- mls 4/12/02 SCR 28686

if (@qty = 0 or @unitcost = 0) and @totcost = 0
 BEGIN  -- Nothing To do Cost = 0!
   if @force != 1								-- mls 4/12/02 SCR 28686
     RETURN 1 
  
   select @posted_flag = 'S'							-- mls 4/12/02 SCR 28686
 END

-- Get the config flags
SELECT @allow_prior_posting = LEFT(value_str, 1) from config (NOLOCK) where upper(flag) = 'PLT_PRIOR_POST'
SELECT @allow_future_posting = LEFT(value_str, 1) from config(NOLOCK) where upper(flag) = 'PLT_FUTURE_POST'
SELECT @allow_range_posting = LEFT(value_str, 1) from config (NOLOCK)where upper(flag) = 'PLT_RANGE_POST'
IF ISNUMERIC((SELECT value_str from config(NOLOCK) where upper(flag) = 'PLT_APPLY_DT_RANGE'))=1
BEGIN
	SELECT @apply_date_range = CAST(value_str as integer) from config(NOLOCK) where upper(flag) = 'PLT_APPLY_DT_RANGE'
END

if isnull(@org_id,'') = '' 
begin
  select @org_id = dbo.adm_get_locations_org_fn(@loc)
  select @account = dbo.adm_mask_acct_fn (@account, @org_id)
end
else if not exists (select 1 from adm_glchart_unsecured (nolock)
  where account_code = @account and ((org_id = @org_id and ib_flag = 1) or ib_flag = 0))
  return -100

if isnull(@controlling_org_id,'') = ''
  select @controlling_org_id = @org_id

if isnull(@org_id,'') != isnull(@controlling_org_id,'')
begin
  if not exists (select 1 from oorel_vw where controlling_org_id = @controlling_org_id and detail_org_id = @org_id)
    return -101
end

SELECT @allow_prior_posting = ISNULL(@allow_prior_posting, 'N'),
	@allow_future_posting = ISNULL(@allow_future_posting, 'N'),
	@allow_range_posting = ISNULL(@allow_range_posting, 'N'),
	@apply_date_range = ISNULL(@apply_date_range, 0) 

select @val_apply_dt = value_str from config(nolock) where upper(flag) = 'PLT_VAL_APPLY_DT' 


SELECT @seg1 = seg1_code,
       @seg2 = seg2_code,
       @seg3 = seg3_code,
       @seg4 = seg4_code,
       @glnat_cur = currency_code,
       @dft_rate_type_home = rate_type_home,							-- mls 4/16/01 SCR 26722
       @dft_rate_type_oper = rate_type_oper, 							-- mls 4/16/01 SCR 26722
       @active_date = active_date,
       @inactive_date = inactive_date
  FROM adm_glchart_all (nolock) 			-- mls 3/24/05 
  WHERE account_code = @account

  if @seg1 is NULL						-- mls 1/25/05 SCR 34142
   BEGIN
     RETURN -1 --Account Not Found on GLCHART!
   END

  SELECT @oper_cur_code = oper_currency,
    @home_cur_code = home_currency  
  FROM glco (nolock)
  WHERE company_id = @company_id


SELECT @period_end_date = CASE WHEN ISNUMERIC(value_str)=1 THEN 
		CAST(value_str AS INT) 
		ELSE 0 END 
  FROM config (NOLOCK) 
 WHERE upper(flag) = 'DIST_PLT_END_DATE' 
 
  if @oper_cur_code is NULL or @oper_cur_code is NULL		-- mls 1/25/05 SCR 34142
   BEGIN
     RETURN -2 --Currencys Not Found on GLCO!
   END

  if @nat_cur_code   is NULL SELECT @nat_cur_code   = @glnat_cur	-- mls 1/25/05 SCR 34142

  SELECT @curr_date = datediff(day,'01/01/1900',@tran_date) + 693596

  if isnull(@val_apply_dt,'1') = '1'
  begin
	  if @allow_range_posting = 'Y'
	  begin
		  if ABS(DATEDIFF(DAY, getdate(), @tran_date)) > @apply_date_range
		  begin 
		        select @msg = 'Cannot apply transaction to ' + convert(varchar(10),@tran_date,101) + ' because it is in not in the valid date range for account ' 
		          + @account + '.'
		        raiserror 992016 @msg
		        return - 2016
		  end
	  end
	  else
	  begin
		if @allow_future_posting = 'N'
		begin
			  if @curr_date > @period_end_date				-- mls 8/19/03 SCR 31660 start
			  begin
			        select @msg = 'Cannot apply transaction to ' + convert(varchar(10),@tran_date,101) + ' because it is in a future period.'
			        raiserror 992027 @msg
			        return -2027
			  end
		end
		
		  if @allow_prior_posting = 'N'
		  begin
			  if @curr_date < (select period_start_date from glprd (nolock) where period_end_date = @period_end_date)
			  begin
			        select @msg = 'Cannot apply transaction to ' + convert(varchar(10),@tran_date,101) + ' because it is in a prior period.'
			        raiserror 992026 @msg
			        return -2026
			  end 		
		  end									-- mls 8/19/03 SCR 31660 end
	  end
  end
  if @tran_code = 'R' and (@nat_cur_code != @oper_cur_code or @nat_cur_code != @home_cur_code)	-- mls 4/16/01 SCR 26722 start
  begin
    select @rate_type_home = isnull(v.rate_type_home,ap.rate_type_home),
      @rate_type_oper = isnull(v.rate_type_oper,ap.rate_type_oper)
    from receipts_all r (nolock), adm_vend_all v (nolock), apco ap (nolock)
    where r.receipt_no = @tran_no and r.vendor = v.vendor_code and ap.company_id = @company_id
  end

  select @rate_type_home = isnull(@rate_type_home,@dft_rate_type_home),
    @rate_type_oper = isnull(@rate_type_oper,@dft_rate_type_oper)				-- mls 4/16/01 SCR 26722 end


  exec @retval = adm_mccurate_sp
                  @curr_date,@nat_cur_code,@oper_cur_code,@rate_type_oper,
                  @op_rate OUTPUT,0,@divop OUTPUT

  if @retval <> 0 
   BEGIN
    RETURN -3 -- Call to MCCURATE FAILED!!!!
   END

  if @op_rate = 0
   BEGIN
      --Did not find a rate use one from transaction
      select @op_rate = @oper_rate
      select @divop = case when @oper_rate < 0 then 1 else 0 end 				-- mls 02/09/01 SCR 24318
   END


  exec @retval = adm_mccurate_sp
                  @curr_date,@nat_cur_code,@home_cur_code,@rate_type_home,
                  @nat_rate OUTPUT,0,@divnat OUTPUT


  if @retval <> 0 
   BEGIN
    RETURN -4 -- Call to MCCURATE FAILED!!!!
   END

  if @nat_rate = 0
   BEGIN
      --Did not find a rate use one from transaction
      select @nat_rate = @natural_rate
      select @divnat = case when @natural_rate < 0 then 1 else 0 end 				-- mls 02/09/01 SCR 24318
   END

   select @nat_balance = @totcost							-- mls 04/10/02 SCR 28686
--   select @nat_balance = @unitcost * @qty						-- mls 12/20/00 SCR 25339 

   if @nat_cur_code != @home_cur_code							-- mls 12/20/00 SCR 25339 start
   begin
     select @nat_balance =  								-- mls 10/28/99 SCR 70 21589 start
     CASE @divnat
       WHEN 0
         THEN @nat_balance / abs(@nat_rate)	--Natural Balance
       ELSE @nat_balance * abs(@nat_rate)	--Natural Balance
     END
   end											-- mls 12/20/00 SCR 25339 end

   if @oper_cur_code = @home_cur_code
   begin
     select @oper_balance = @totcost							-- mls 04/10/02 SCR 28686
   end
   else
   begin
     select @oper_balance =
     CASE @divop
       WHEN 0
         THEN @nat_balance * abs(@op_rate)	--Balance Oper
       ELSE @nat_balance / abs(@op_rate)	--Balance Oper
     END
   end										-- mls 10/28/99 SCR 70 21589 end

   INSERT in_gltrxdet
    (tran_no,tran_ext,trx_type,part_no,sequence_id,location,description,posted_flag,date_posted,
     company_id,account_code,seg1_code,seg2_code,seg3_code,seg4_code,balance,nat_balance,
     nat_cur_code,rate,balance_oper,rate_oper,rate_type_home,rate_type_oper,user_id,apply_date,reference_code,
     tran_line, 									-- mls 1/24/01 SCR 20787
     tran_qty, tran_cost, tran_date, line_descr,				-- mls 4/12/02 SCR 28686	
     tran_id, organization_id, controlling_organization_id)
    SELECT
       @tran_no,@tran_ext,@tran_code,@part,1,@loc,'TranId:'+ @tran_code + convert(varchar(10),@tran_no),
       @posted_flag,								-- mls 4/12/02 SCR 28686
       case @posted_flag when 'N' then '1/1/1900' else getdate() end,		-- mls 4/12/02 SCR 28686
       @company_id,@account,
       @seg1,@seg2,@seg3,@seg4,
       @totcost,			--balance(Home)				-- mls 04/10/02 SCR 28686
       @nat_balance,			--Natural balance			-- mls 10/28/99 SCR 70 21589 
       @nat_cur_code,			--Nat Cur Code
       @nat_rate,			--Nat Cur Rate        
       @oper_balance,			--Operational Balance			-- mls 10/28/99 SCR 70 21589 
       @op_rate,			--Oper Rate
       @rate_type_home,			--rate_type Home
       @rate_type_oper,			--rate_type Oper
       @user,
       @tran_date,			--apply_date
       @reference_code,
       @tran_line,								-- mls 1/24/01 SCR 20787
       @qty, @unitcost, getdate(), @description,				-- mls 4/12/02 SCR 28686
       @tran_id,
       @org_id,
       @controlling_org_id

   IF @@error <> 0 
    BEGIN
      RETURN -5  --Error On Insert
    END

   RETURN 1
END

GO
GRANT EXECUTE ON  [dbo].[adm_gl_insert] TO [public]
GO
