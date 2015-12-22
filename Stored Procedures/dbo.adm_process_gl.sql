SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 14/06/2012 - The concatenation of the fields into doc1 and doc2 is causing a truncation error
--						The tran_no is converted using a char which keeps the space, change to varchar				    
CREATE PROCEDURE [dbo].[adm_process_gl] @user varchar(30),    
 @meth int = 1,     
 @p_trx_type char(1) = '',     
 @p_tran_no int = 0,    
 @p_tran_ext int = 0,    
 @err int OUT AS    
    
--Declarations    
  
  
DECLARE @journalnum varchar(16),@company_code varchar(8), @home_curr varchar(8), @db_name varchar(128)    
DECLARE @oper_curr varchar(8), @description varchar(40),@linedesc varchar(40)    
DECLARE @rate_type_oper varchar(8), @rate_type_home varchar(8),@doc1 varchar(40)    
DECLARE @process_ctrl_num varchar(16),@nat_cur_code varchar(8),@account varchar(32)    
DECLARE @reference_code varchar(32), @batch_code varchar(16), @jtype varchar(8)    
    
DECLARE @result int,@date_entered int, @date_applied int, @seq int    
DECLARE @company_id int,@tran int, @dir int, @user_id int    
DECLARE @xlp int,@tran_ext int, @debug int    
DECLARE @module_id int,@app_id int, @process_state smallint    
    
DECLARE @balance decimal(20,8),@rate decimal(20,8)    
DECLARE @balance_oper decimal(20,8), @rate_oper decimal(20,8)    
    
DECLARE @crdb char(1),    
   @seg1_code  varchar(16),    
   @seg2_code  varchar(16),    
   @seg3_code  varchar(16),    
   @seg4_code  varchar(16), @min_seq int    
    
DECLARE @apply_date datetime, @type char(1), @rate_used float, @row_id int,    
@bal decimal(20,8), @bal_oper decimal(20,8), @bal_nat decimal(20,8),    
@i int, @nat_curr varchar(8)    
    
DECLARE @bad_apply_date_cnt int, @bad_balance_cnt int    -- mls 3/28/00 SCR 22699    
    
Declare @a_control_org_id varchar(30) , @io_ind int    
    
DECLARE @account_format_mask varchar(35), @oper_prec  int,    
@translation_rounding_acct varchar(32),    
@home_prec  smallint,    
@nat_prec smallint    
DECLARE @min_glprd_int int, @max_glprd_int int    
DECLARE @a_row_id int, @a_nat_curr varchar(8)    
DECLARE @batch_mode_on    smallint    
    
declare @post_time datetime       -- mls 11/18/04 SCR 31535    
--Get System Config Values    
    
SELECT @module_id = 6500,    
  @app_id = 18000,    
  @process_state = 3,    
  @bad_apply_date_cnt = 0,       -- mls 3/8/00   SCR 22699    
  @bad_balance_cnt = 0,        -- mls 3/8/00   SCR 22699    
  @debug = 0,    
  @post_time = getdate()       -- mls 11/18/04 SCR 31535    
    
SELECT @company_id = company_id,      -- mls 9/30/99  SCR ?????    
@home_curr = home_currency,     
@oper_curr = oper_currency,     
@rate_type_home = rate_type_home,    
@rate_type_oper = rate_type_oper ,    
@translation_rounding_acct = translation_rounding_acct    
FROM glco (nolock)    
    
SELECT @company_code = company_code, @db_name = db_name,    
@account_format_mask = account_format_mask      
FROM glcomp_vw (nolock) WHERE company_id = @company_id    
    
SELECT @oper_prec = curr_precision     
FROM glcurr_vw (nolock) WHERE currency_code = @oper_curr    
    
SELECT @home_prec = curr_precision    
FROM glcurr_vw (nolock) WHERE currency_code = @home_curr    
    
IF ( @home_prec IS NULL OR @oper_prec IS NULL )    
BEGIN    
  select @err = -5    
  RETURN    
END    
    
EXEC @result = glprsact_sp @translation_rounding_acct, @account_format_mask,    
  @seg1_code = @seg1_code OUTPUT, @seg2_code = @seg2_code OUTPUT,     
  @seg3_code = @seg3_code OUTPUT, @seg4_code = @seg4_code OUTPUT    
    
SELECT @min_glprd_int = min(period_start_date) from glprd (nolock)    
SELECT @max_glprd_int = max(period_end_date) from glprd (nolock)    
    
    
--Create Temp Tables--    
    
CREATE TABLE #gltrx (    
 mark_flag   smallint NOT NULL,    
 next_seq_id   int NOT NULL,    
 trx_state   smallint NOT NULL,    
 journal_type   varchar(8) NOT NULL,    
 journal_ctrl_num   varchar(16) NOT NULL,     
 journal_description   varchar(40) NOT NULL,     
 date_entered   int NOT NULL,    
 date_applied   int NOT NULL,    
 recurring_flag   smallint NOT NULL,    
 repeating_flag   smallint NOT NULL,    
 reversing_flag   smallint NOT NULL,    
 hold_flag   smallint NOT NULL,    
 posted_flag   smallint NOT NULL,    
 date_posted   int NOT NULL,    
 source_batch_code  varchar(16) NOT NULL,     
 process_group_num  varchar(16) NOT NULL,    
 batch_code   varchar(16) NOT NULL,     
 type_flag   smallint NOT NULL,     
 intercompany_flag  smallint NOT NULL,     
 company_code   varchar(8) NOT NULL,     
 app_id    smallint NOT NULL,     
 home_cur_code  varchar(8) NOT NULL,      
 document_1  varchar(16) NOT NULL,     
 trx_type  smallint NOT NULL,      
 user_id   smallint NOT NULL,    
 source_company_code varchar(8) NOT NULL,    
 oper_cur_code varchar(8) ,    
 org_id  varchar(30) NULL,       
 interbranch_flag smallint NULL       
)    
    
CREATE UNIQUE INDEX #gltrx_ind_0 ON #gltrx ( journal_ctrl_num )    
CREATE INDEX #gltrx_ind_1 ON #gltrx( trx_state)      -- mls 9/30/99 SCR ?????    
    
CREATE TABLE #gltrxdet (    
 mark_flag  smallint NOT NULL,    
 trx_state  smallint NOT NULL,    
  journal_ctrl_num varchar(16) NOT NULL,    
 sequence_id  int NOT NULL,    
 rec_company_code varchar(8) NOT NULL,     
 company_id  smallint NOT NULL,    
  account_code  varchar(32) NOT NULL,     
 description  varchar(40) NOT NULL,    
  document_1  varchar(16) NOT NULL,      
  document_2  varchar(16) NOT NULL,      
 reference_code  varchar(32) NOT NULL,     
  balance   float NOT NULL,      
 nat_balance  float NOT NULL,      
 nat_cur_code  varchar(8) NOT NULL,     
 rate   float NOT NULL,      
  posted_flag smallint NOT NULL,    
  date_posted  int NOT NULL,    
 trx_type  smallint NOT NULL,    
 offset_flag  smallint NOT NULL,     
 seg1_code  varchar(32) NOT NULL,    
 seg2_code  varchar(32) NOT NULL,    
 seg3_code  varchar(32) NOT NULL,    
 seg4_code  varchar(32) NOT NULL,    
 seq_ref_id  int NOT NULL,      
  balance_oper float NULL,    
  rate_oper float NULL,    
  rate_type_home varchar(8) NULL,    
 rate_type_oper varchar(8) NULL,    
 org_id  varchar(30) NULL       
)    
    
CREATE UNIQUE INDEX #gltrxdet_ind_0 ON #gltrxdet ( journal_ctrl_num, sequence_id )    
CREATE INDEX #gltrxdet_ind_1 ON #gltrxdet ( journal_ctrl_num, account_code )    
CREATE INDEX #gltrxdet_ind_2 ON #gltrxdet( trx_state)     -- mls 9/30/99 SCR ?????    
    
CREATE TABLE #trxerror (    
 journal_ctrl_num  varchar(16),     
 sequence_id  int,    
 error_code   int    
)    
    
CREATE UNIQUE INDEX #trxerror_ind_0 ON #trxerror ( journal_ctrl_num,  sequence_id,  error_code )    
    
CREATE TABLE #offset_accts (    
  account_code varchar(32) NOT NULL,    
  org_code varchar(8) NOT NULL,    
  rec_code varchar(8) NOT NULL,    
  sequence_id int  NOT NULL    
)    
CREATE UNIQUE CLUSTERED INDEX #offset_accts_ind_0 ON #offset_accts( rec_code, account_code, org_code )    
    
CREATE TABLE #offsets (    
 journal_ctrl_num varchar(16) NOT NULL,    
 sequence_id  int NOT NULL,    
 company_code  varchar(8) NOT NULL,    
 company_id  smallint NOT NULL,    
 org_ic_acct    varchar(32) NOT NULL,    
 org_seg1_code  varchar(32) NOT NULL,    
 org_seg2_code  varchar(32) NOT NULL,    
 org_seg3_code  varchar(32) NOT NULL,    
 org_seg4_code  varchar(32) NOT NULL,    
 org_org_id  varchar(30) NOT NULL,    
 rec_ic_acct    varchar(32) NOT NULL,    
 rec_seg1_code  varchar(32) NOT NULL,    
 rec_seg2_code  varchar(32) NOT NULL,    
 rec_seg3_code  varchar(32) NOT NULL,    
 rec_seg4_code  varchar(32) NOT NULL,    
 rec_org_id  varchar(30) NOT NULL )    
    
CREATE UNIQUE CLUSTERED INDEX #offsets_ind_0 ON #offsets ( journal_ctrl_num, sequence_id )    
    
CREATE TABLE #batches (    
 date_applied  int NOT NULL,    
 source_batch_code varchar(16) NOT NULL,    
 org_id varchar(30)    
)    
CREATE UNIQUE CLUSTERED INDEX #batches_ind_0 ON #batches ( date_applied, source_batch_code )    
    
CREATE TABLE #gltrxjcn( journal_ctrl_num varchar(16) )     
    
CREATE TABLE #gldtrdet (    
    journal_ctrl_num varchar(16) NOT NULL,    
 sequence_id  int NOT NULL,    
  account_code  varchar(32) NOT NULL,     
  balance   float NOT NULL,      
 nat_balance  float NOT NULL,      
 nat_cur_code  varchar(8) NOT NULL,     
 rec_company_code varchar(8) NOT NULL,     
  mark_flag smallint NOT NULL,     
  balance_oper float NOT NULL,    
        org_id varchar(30)      -- mls 3/23/06 SCR 36364    
)    
CREATE UNIQUE CLUSTERED INDEX #gldtrdet_ind_0 ON #gldtrdet ( journal_ctrl_num, sequence_id )    
CREATE INDEX #gldtrdet_ind_1 ON #gldtrdet ( account_code )    
    
CREATE TABLE #drcr (    
 account_code varchar(32) NOT NULL,     
 balance_type smallint NOT NULL,    
 currency_code varchar(8) NOT NULL,    
 home_debit float NOT NULL,    
 home_credit float NOT NULL,    
 nat_debit float NOT NULL,    
 nat_credit float NOT NULL,    
 bal_fwd_flag smallint NOT NULL,     
 seg1_code varchar(32) NOT NULL,    
 seg2_code varchar(32) NOT NULL,    
 seg3_code varchar(32) NOT NULL,    
 seg4_code varchar(32) NOT NULL,    
 account_type smallint NOT NULL,    
  initialized tinyint NOT NULL,    
  oper_debit float NOT NULL,    
  oper_credit float NOT NULL     
)    
CREATE UNIQUE INDEX #drcr_ind_0 ON #drcr ( account_code, currency_code, balance_type )    
    
CREATE TABLE #summary (    
  summary_code  varchar(32) NOT NULL,    
  summary_type  tinyint NOT NULL,    
  account_code  varchar(32) NOT NULL     
)    
CREATE UNIQUE CLUSTERED INDEX #summary_ind_0 ON #summary ( account_code, summary_code, summary_type )    
    
CREATE TABLE #sumhdr (    
  summary_code  varchar(32) NOT NULL,    
  summary_type  tinyint NOT NULL,    
  bal_fwd_flag  smallint NOT NULL,     
  balance_type  smallint NOT NULL,    
  seg1_code  varchar(32) NOT NULL,    
  seg2_code  varchar(32) NOT NULL,    
  seg3_code  varchar(32) NOT NULL,    
  seg4_code  varchar(32) NOT NULL,    
  account_type  smallint  NOT NULL     
)    
CREATE UNIQUE CLUSTERED INDEX #sumhdr_ind_0 ON #sumhdr ( summary_code, summary_type )    
    
CREATE TABLE #gldtrx (    
 journal_ctrl_num  varchar(16) NOT NULL,     
 date_applied   int NOT NULL,    
 recurring_flag  smallint NOT NULL,    
 repeating_flag  smallint NOT NULL,    
 reversing_flag  smallint NOT NULL,    
 mark_flag   smallint NOT NULL,    
 interbranch_flag int      -- mls 3/23/06 SCR 36364    
)    
CREATE UNIQUE CLUSTERED INDEX #gldtrx_ind_0 ON #gldtrx ( journal_ctrl_num )    
CREATE INDEX #gldtrx_ind_1 ON #gldtrx ( mark_flag )    
    
CREATE TABLE #acct (     
 account_code varchar(32) NOT NULL,     
 balance_type smallint NOT NULL     
)    
CREATE UNIQUE INDEX #acct_ind_0 ON  #acct ( account_code, balance_type )    
    
CREATE TABLE #updglbal (     
 account_code  varchar(32) NOT NULL,    
 currency_code  varchar(8) NOT NULL,    
 balance_date  int  NOT NULL,    
 balance_until  int  NOT NULL,    
 balance_type  smallint NOT NULL,    
 current_balance  float  NOT NULL,    
 home_current_balance float  NOT NULL,    
 bal_fwd_flag  smallint NOT NULL,     
 seg1_code  varchar(32) NOT NULL,    
 seg2_code  varchar(32) NOT NULL,    
 seg3_code  varchar(32) NOT NULL,    
 seg4_code  varchar(32) NOT NULL,    
  account_type   smallint  NOT NULL,    
  current_balance_oper  float   NOT NULL    
)    
CREATE UNIQUE INDEX #updglbal_ind_0 ON #updglbal (account_code, currency_code, balance_date, balance_type )    
    
CREATE TABLE #hold(    
 journal_ctrl_num  varchar(16) NOT NULL,     
 e_code    int NOT NULL,    
 logged    smallint NOT NULL    
)    
CREATE UNIQUE INDEX #hold_ind_0 ON #hold ( journal_ctrl_num, e_code )    
    
-- ************************************************************************************************************************     
CREATE TABLE #in_gltrxdet (    
 tran_no  int NOT NULL ,    
 tran_ext  int NOT NULL ,    
 trx_type  char (1) NOT NULL ,    
 part_no  varchar (30) NOT NULL ,    
 sequence_id  int IDENTITY (1,1) NOT NULL ,    
 location  varchar (10) NOT NULL ,    
 description  varchar (40) NOT NULL ,    
 posted_flag  char (1) NOT NULL ,    
 date_posted  datetime NOT NULL ,    
 company_id  smallint NOT NULL ,    
 account_code  varchar (32) NOT NULL ,    
 seg1_code  varchar (32) NOT NULL ,    
 seg2_code  varchar (32) NOT NULL ,    
 seg3_code  varchar (32) NOT NULL ,    
 seg4_code  varchar (32) NOT NULL ,    
 balance  decimal(20, 8) NOT NULL ,    
 nat_balance  decimal(20, 8) NOT NULL ,    
 nat_cur_code  varchar (8) NOT NULL ,    
 rate   decimal(20, 8) NOT NULL ,    
 balance_oper  decimal(20, 8) NULL ,    
 rate_oper  decimal(20, 8) NULL ,    
 rate_type_home  varchar (8) NULL ,    
 rate_type_oper  varchar (8) NULL ,    
 row_id   int  NOT NULL ,    
 apply_date  datetime NULL ,    
 crdb   char (1) NULL ,    
 user_id  varchar (10) NULL ,    
 acct_type  char (1) NULL ,    
 reference_code  varchar (32) NULL ,    
 jcn  varchar(16) NOT NULL,    
 document_1      varchar(16) NOT NULL,    
 summarize int,    
        tran_line int NOT NULL,        -- mls 1/24/01 SCR 20787    
 org_id  varchar(30) NULL    
)    
CREATE INDEX in_gltrxdet_tmp1 on #in_gltrxdet ( row_id     )    
CREATE INDEX in_gltrxdet_tmp2 on #in_gltrxdet ( apply_date )    
CREATE INDEX in_gltrxdet_tmp3 on #in_gltrxdet ( summarize  )    
    
CREATE TABLE #in_gltrxdet_rows (    
 row_id   int  NOT NULL ,    
)    
    
CREATE TABLE #apply ( apply_date varchar(11), nat_cur_code varchar(8), controlling_org_id varchar(30), row_id int identity (1,1))    
create index apply1 on #apply( row_id)    
    
CREATE TABLE #gltrxedt1    
     (    
       journal_ctrl_num varchar(16),     
     sequence_id int,     
       journal_description varchar(30),    
       journal_type varchar(8), date_entered int,     
                  date_applied int, batch_code varchar(16),     
      hold_flag smallint, home_cur_code varchar(8),     
      intercompany_flag smallint,     
      company_code varchar(8) NULL,     
      source_batch_code varchar(16), type_flag smallint,     
      user_id smallint, source_company_code varchar(8),      
      account_code varchar(32), account_description varchar(40),     
      rec_company_code varchar(8),nat_cur_code varchar(8),     
     document_1 varchar(16), description varchar(40),     
     reference_code varchar(32),balance float,     
     nat_balance float, trx_type smallint,    
     offset_flag smallint, seq_ref_id int,     
     temp_flag smallint, spid smallint,    
     oper_cur_code varchar(8) NULL, balance_oper float NULL,    
     db_name varchar(128),    
    controlling_org_id varchar(30) NULL,    
    detail_org_id  varchar(30) NULL,    
    interbranch_flag smallint NULL    
     )    
-- ************************************************************************************************************************     
    
select @jtype = isnull((select journal_type FROM glappid WHERE app_id = @module_id),'GJ')     
    
SELECT @user_id = isnull((select user_id FROM glusers_vw WHERE lower(user_name) = lower(@user)),1)      
    
--Update transaction posting flag to mark records for posting to GL.    
    
if @p_tran_no = 0 and @p_trx_type = ''    
BEGIN --Update All transaction    
  UPDATE in_gltrxdet    
  SET posted_flag = 'W' ,    
    date_posted = @post_time       -- mls 11/18/04 SCR 31535    
  WHERE posted_flag in ('N','W') and datediff(hh,date_posted,@post_time) > 3 -- mls 11/18/04 SCR 31535    
    
  insert #apply (apply_date, nat_cur_code, controlling_org_id)    
  select distinct convert(varchar(11),apply_date), nat_cur_code, isnull(controlling_organization_id,isnull(organization_id,dbo.IBOrgbyAcct_fn(account_code)))    
  from in_gltrxdet     
  where posted_flag = 'W' and date_posted = @post_time    -- mls 11/18/04 SCR 31535    
END    
ELSE    
BEGIN --Update for spefic Transaction    
  if @p_tran_no = 0         -- mls 4/21/99  EPR08022 start    
  begin    
    UPDATE in_gltrxdet    
    SET posted_flag = 'W',    
    date_posted = @post_time       -- mls 11/18/04 SCR 31535    
    WHERE trx_type = @p_trx_type and posted_flag in ('N','W')   -- mls 9/30/99 SCR ?????       
      and datediff(hh,date_posted,@post_time) > 3    -- mls 11/18/04 SCR 31535    
    
    insert #apply (apply_date, nat_cur_code, controlling_org_id)    
    select distinct convert(varchar(11),apply_date), nat_cur_code, isnull(controlling_organization_id,isnull(organization_id,dbo.IBOrgbyAcct_fn(account_code)))    
    from in_gltrxdet     
    where trx_type = @p_trx_type   and posted_flag = 'W'    
      and date_posted = @post_time      -- mls 11/18/04 SCR 31535    
  end          -- mls 4/21/99  EPR08022 end    
ELSE    
  begin    
    if @p_trx_type = 'Z'       -- mls 8/11/04 SCR 31856    
    begin    
      update g    
      set posted_flag = 'W',    
        date_posted = @post_time      -- mls 11/18/04 SCR 31535    
      from issues_all i    
      join in_gltrxdet g on g.trx_type = 'I' and g.tran_no = i.issue_no and g.tran_ext = 0 and g.posted_flag in ('N','W')    
      where i.reason_code = 'RTV' + convert(varchar,@p_tran_no)    
        and datediff(hh,g.date_posted,@post_time) > 3    -- mls 11/18/04 SCR 31535    
    
      insert #apply (apply_date, nat_cur_code, controlling_org_id)    
      select distinct convert(varchar(11),apply_date), nat_cur_code, isnull(controlling_organization_id,isnull(g.organization_id,dbo.IBOrgbyAcct_fn(g.account_code)))    
      from issues_all i    
      join in_gltrxdet g on g.trx_type = 'I' and g.tran_no = i.issue_no and g.tran_ext = 0 and g.posted_flag = 'W'    
      where i.reason_code = 'RTV' + convert(varchar,@p_tran_no)    
        and g.date_posted = @post_time      -- mls 11/18/04 SCR 31535    
    end    
    else    
    begin    
      UPDATE in_gltrxdet    
      SET posted_flag = 'W',    
        date_posted = @post_time      -- mls 11/18/04 SCR 31535     
      WHERE trx_type = @p_trx_type and tran_no = @p_tran_no AND tran_ext = @p_tran_ext AND posted_flag in ('N','W')    
        and datediff(hh,date_posted,@post_time) > 3    -- mls 11/18/04 SCR 31535    
    
      insert #apply (apply_date, nat_cur_code, controlling_org_id)    
      select distinct convert(varchar(11),apply_date), nat_cur_code, isnull(controlling_organization_id,isnull(organization_id,dbo.IBOrgbyAcct_fn(account_code)))    
      from in_gltrxdet     
      where trx_type = @p_trx_type and tran_no = @p_tran_no and tran_ext = @p_tran_ext and posted_flag = 'W'    
        and date_posted = @post_time      -- mls 11/18/04 SCR 31535    
    end    
  END          -- mls 4/21/99  EPR08022     
END    
     
if @@error <> 0     
BEGIN    
  select @err = -10    
  RETURN --Error Updateing in_gltrxdet table     
END    
    
if not exists (select 1 from #apply)    
BEGIN    
  SELECT @err = 1    
  RETURN 1    
END    
    
SELECT @a_row_id = -1    
    
WHILE @a_row_id is not null    
BEGIN    
  select @a_row_id = isnull((select min(row_id) from #apply where row_id > @a_row_id),NULL)    
  if @a_row_id is NULL    
    BREAK    
    
  select @apply_date = apply_date,    
    @a_nat_curr = nat_cur_code,    
    @a_control_org_id = controlling_org_id    
  from #apply    
  where row_id = @a_row_id    
    
  SELECT @nat_prec = curr_precision FROM glcurr_vw (nolock) WHERE currency_code = @a_nat_curr    
    
  select @date_applied = datediff(day,'01/01/1900',@apply_date) + 693596,    
    @date_entered = datediff(day,'01/01/1900',getdate() ) + 693596     
    
  if @date_applied not between @min_glprd_int and @max_glprd_int    
  begin    
    select @bad_apply_date_cnt = @bad_apply_date_cnt + 1      -- mls 3/28/00 SCR 22699    
    CONTINUE    
  end    
    
  --Get new Process Control Number     
  exec @result = pctrladd_sp @process_ctrl_num OUTPUT, 'ADM GL Transactions', @user_id, @app_id, @company_code    
    
  if @result <> 0     
  BEGIN    
    select @err = -20    
    RETURN -- Error getting process control number    
  END    
    
  SELECT @journalnum = NULL    
    
  EXEC @result = gltrxnew_sp @company_code, @journalnum OUTPUT    
  IF ( @debug > 3 ) SELECT '*** gltrxcrh_sp - Getting new journal ctrl number '+ @journalnum    
    
  if @result <> 0    
  BEGIN    
    select @err = -21    
    RETURN    
  END    
    
  delete #in_gltrxdet    
  delete #in_gltrxdet_rows    
    
  IF @p_tran_no = 0 and @p_trx_type = ''    
  BEGIN    
        
    INSERT INTO #in_gltrxdet ( tran_no, tran_ext, trx_type, part_no, location, description, posted_flag,    
      date_posted, company_id, account_code, seg1_code, seg2_code, seg3_code, seg4_code, balance,    
      nat_balance, nat_cur_code, rate, balance_oper, rate_oper, rate_type_home, rate_type_oper,    
      row_id, apply_date, crdb, user_id, acct_type, reference_code, jcn, document_1, summarize, tran_line, org_id) -- mls 1/24/01 SCR 20787    
    SELECT     
  tran_no    , tran_ext    , trx_type    , part_no               , location      , part_no + ' / ' + location, posted_flag,     
  date_posted, company_id  , account_code, seg1_code   , seg2_code  , seg3_code     , seg4_code     , balance    ,    
  nat_balance, nat_cur_code, rate        , balance_oper, rate_oper  , rate_type_home, rate_type_oper, row_id     ,    
  apply_date , crdb        , user_id     , acct_type   , isnull(reference_code,''), @journalnum, '',0, isnull(tran_line,0), isnull(organization_id,dbo.IBOrgbyAcct_fn(account_code)) -- mls 1/24/01 SCR 20787    
    FROM  in_gltrxdet    
    WHERE posted_flag = 'W'    
      AND   convert(varchar(11), apply_date) = @apply_date and nat_cur_code = @a_nat_curr    
      and   isnull(controlling_organization_id,isnull(organization_id,dbo.IBOrgbyAcct_fn(account_code))) = @a_control_org_id     
      and   date_posted = @post_time       -- mls 11/18/04 SCR 31535    
  END    
  ELSE IF @p_tran_no = 0 and @p_trx_type > ''    
  BEGIN --Update All transaction    
        
    INSERT INTO #in_gltrxdet ( tran_no, tran_ext, trx_type, part_no, location, description, posted_flag,    
      date_posted, company_id, account_code, seg1_code, seg2_code, seg3_code, seg4_code, balance,    
      nat_balance, nat_cur_code, rate, balance_oper, rate_oper, rate_type_home, rate_type_oper,    
      row_id, apply_date, crdb, user_id, acct_type, reference_code, jcn, document_1, summarize, tran_line, org_id) -- mls 1/24/01 SCR 20787    
    SELECT     
  tran_no    , tran_ext    , trx_type    , part_no               , location      ,  part_no + ' / ' + location, posted_flag,     
  date_posted, company_id  , account_code, seg1_code   , seg2_code  , seg3_code     , seg4_code     , balance    ,    
  nat_balance, nat_cur_code, rate        , balance_oper, rate_oper  , rate_type_home, rate_type_oper, row_id     ,    
  apply_date , crdb        , user_id     , acct_type   , isnull(reference_code,''), @journalnum, '',0, isnull(tran_line,0) , isnull(organization_id,dbo.IBOrgbyAcct_fn(account_code))    
    FROM  in_gltrxdet    
    WHERE posted_flag = 'W' AND trx_type = @p_trx_type AND convert(varchar(11), apply_date) = @apply_date     
      and nat_cur_code = @a_nat_curr    
      and   isnull(controlling_organization_id,isnull(organization_id,dbo.IBOrgbyAcct_fn(account_code))) = @a_control_org_id     
      and   date_posted = @post_time       -- mls 11/18/04 SCR 31535    
  END    
  ELSE    
  BEGIN    
    if @p_trx_type = 'Z'           -- mls 8/11/04 SCR 31856    
    begin    
          
      INSERT INTO #in_gltrxdet ( tran_no, tran_ext, trx_type, part_no, location, description, posted_flag,    
        date_posted, company_id, account_code, seg1_code, seg2_code, seg3_code, seg4_code, balance,    
        nat_balance, nat_cur_code, rate, balance_oper, rate_oper, rate_type_home, rate_type_oper,    
        row_id, apply_date, crdb, user_id, acct_type, reference_code, jcn, document_1, summarize, tran_line, org_id) -- mls 1/24/01 SCR 20787    
      SELECT     
  g.tran_no    , g.tran_ext    , g.trx_type    , g.part_no             , g.location      ,  g.part_no + ' / ' + g.location, g.posted_flag,     
  g.date_posted, g.company_id  , g.account_code, g.seg1_code   , g.seg2_code  , g.seg3_code     , g.seg4_code     , g.balance    ,    
  g.nat_balance, g.nat_cur_code, g.rate        , g.balance_oper, g.rate_oper  , g.rate_type_home, g.rate_type_oper, g.row_id     ,    
  g.apply_date , g.crdb        , user_id     , g.acct_type   , isnull(g.reference_code,''), @journalnum, '',0, isnull(g.tran_line,0), isnull(g.organization_id,dbo.IBOrgbyAcct_fn(g.account_code))    
      FROM issues_all i    
      join in_gltrxdet g on g.posted_flag = 'W' and g.tran_no = i.issue_no and g.tran_ext = 0 and g.trx_type = 'I' and convert(varchar(11), g.apply_date) = @apply_date     
        and g.nat_cur_code = @a_nat_curr    
        and   isnull(controlling_organization_id,isnull(g.organization_id,dbo.IBOrgbyAcct_fn(g.account_code))) = @a_control_org_id     
        and g.date_posted = @post_time       -- mls 11/18/04 SCR 31535    
      where i.reason_code = 'RTV' + convert(varchar,@p_tran_no)    
    end    
    else    
    begin    
          
      INSERT INTO #in_gltrxdet ( tran_no, tran_ext, trx_type, part_no, location, description, posted_flag,    
        date_posted, company_id, account_code, seg1_code, seg2_code, seg3_code, seg4_code, balance,    
        nat_balance, nat_cur_code, rate, balance_oper, rate_oper, rate_type_home, rate_type_oper,    
        row_id, apply_date, crdb, user_id, acct_type, reference_code, jcn, document_1, summarize, tran_line, org_id) -- mls 1/24/01 SCR 20787    
      SELECT     
  tran_no    , tran_ext    , trx_type    , part_no             , location      ,  part_no + ' / ' + location, posted_flag,     
  date_posted, company_id  , account_code, seg1_code   , seg2_code  , seg3_code     , seg4_code     , balance    ,    
  nat_balance, nat_cur_code, rate        , balance_oper, rate_oper  , rate_type_home, rate_type_oper, row_id     ,    
  apply_date , crdb        , user_id     , acct_type   , isnull(reference_code,''), @journalnum, '',0, isnull(tran_line,0), isnull(organization_id,dbo.IBOrgbyAcct_fn(account_code))    
      FROM  in_gltrxdet    
      WHERE posted_flag = 'W' AND   tran_no     = @p_tran_no AND   tran_ext    = @p_tran_ext     
        AND   trx_type    = @p_trx_type AND   convert(varchar(11), apply_date) = @apply_date     
        and nat_cur_code = @a_nat_curr    
        and   isnull(controlling_organization_id,isnull(organization_id,dbo.IBOrgbyAcct_fn(account_code))) = @a_control_org_id     
        and date_posted = @post_time       -- mls 11/18/04 SCR 31535    
    end    
  END    
    
  if isnull((select sum(balance) from #in_gltrxdet),-1) <> 0    
  begin    
    select @bad_balance_cnt = @bad_balance_cnt + 1      -- mls 3/28/00 SCR 22699    
    CONTINUE    
  end    
    
    
    
  INSERT #in_gltrxdet_rows    
  select row_id from #in_gltrxdet    
    
  --Reset Journal Number    
  SELECT @description = 'IV Trans For: ' + convert(varchar(10),@apply_date,110)    
    
-- ************************************************************************************************************************     
-- EXEC @result = gltrxcrh_sp     
    
  IF ( @debug > 0 ) SELECT '*** gltrxcrh_sp - Entering gltrxcrh_sp 11'    
    
  INSERT #gltrx(    
 journal_type, journal_ctrl_num, journal_description,     
 date_entered, date_applied, recurring_flag, repeating_flag, reversing_flag, hold_flag,     
 posted_flag, date_posted, source_batch_code, batch_code, type_flag, intercompany_flag,    
 company_code, app_id, home_cur_code, document_1, trx_type, user_id,    
 source_company_code, process_group_num, trx_state, next_seq_id, mark_flag, oper_cur_code,    
 org_id, interbranch_flag     
 )     
  VALUES (@jtype, @journalnum, @description, @date_entered, @date_applied, 0,    
 0, 0, 0, -1, 0, '',' ', 0, 0, @company_code, @module_id, @home_curr,    
 '', 111, @user_id, '', @process_ctrl_num, 0, 1, 0, @oper_curr,    
 @a_control_org_id, 0)     
    
  IF ( @@error != 0 )     
  begin    
    ROLLBACK TRAN    
    exec @result = pctrlupd_sp @process_ctrl_num, @process_state    
    select @err = -30    
    RETURN     
  END    
      
  IF ( @debug > 3 ) SELECT '*** gltrxcrh_sp - Inserted transaction: '+@journalnum    
  IF ( @debug > 0 ) SELECT '*** gltrxcrh_sp - Leaving gltrxcrh_sp 11'    
-- ************************************************************************************************************************     
    
  if exists (select 1 from #in_gltrxdet where rate_oper is null)    
  BEGIN    
    EXEC @result = adm_mccurate_sp  @date_applied, @home_curr, @oper_curr,    
      @rate_type_oper, @rate_used OUTPUT, 0    
     
    IF ( @result != 0)    
    BEGIN    
      IF ( @debug > 0 ) SELECT '*** gltrxcrd_sp - Could not get Exchange Rate'    
      ROLLBACK TRAN    
      exec @result = pctrlupd_sp @process_ctrl_num, @process_state    
      select @err = -31    
      RETURN     
    END    
    
    Update #in_gltrxdet    
    set rate_oper = @rate_used,    
      balance_oper = (SIGN(balance * ( SIGN(1 + SIGN(@rate_used))*(@rate_used) + (SIGN(ABS(SIGN(ROUND(@rate_used,6))))/(@rate_used + SIGN(1 - ABS(SIGN(ROUND(@rate_used,6)))))) * SIGN(SIGN(@rate_used) - 1) )) * ROUND(ABS(balance * ( SIGN(1 + SIGN(@rate_used))*(@rate_used) + (SIGN(ABS(SIGN(ROUND(@rate_used,6))))/(@rate_used + SIGN(1 - ABS(SIGN(ROUND(@rate_used,6)))))) * SIGN(SIGN(@rate_used) - 1) )) + 0.0000001, @oper_prec))    
    where rate_oper is null    
  END    
    
  Update #in_gltrxdet    
  set summarize = 1    
  from #in_gltrxdet d, glacsum g (nolock)    
  where d.account_code = g.account_code and g.app_id = @module_id    
    
  select @row_id = isnull((select min( sequence_id ) from #in_gltrxdet where summarize = 1),null)    
  while @row_id is not NULL    
  begin    
    select @account = account_code, @reference_code = reference_code,    
    @nat_cur_code = nat_cur_code, @rate = rate, @rate_oper = rate_oper    
    from #in_gltrxdet where sequence_id = @row_id    
    
    select @bal = isnull((select sum(balance) from #in_gltrxdet     
      where summarize = 1 and account_code = @account AND reference_code = @reference_code AND     
 nat_cur_code = @nat_cur_code and rate = @rate and rate_oper = @rate_oper),0)    
    select @bal_oper = isnull((select sum(balance_oper) from #in_gltrxdet     
      where summarize = 1 and account_code = @account AND reference_code = @reference_code AND     
        nat_cur_code = @nat_cur_code and rate = @rate and rate_oper = @rate_oper),0)    
    select @bal_nat = isnull((select sum(nat_balance) from #in_gltrxdet     
      where summarize = 1 and account_code = @account AND reference_code = @reference_code AND     
        nat_cur_code = @nat_cur_code and rate = @rate and rate_oper = @rate_oper),0)    
      
    UPDATE #in_gltrxdet    
    set balance = @bal, balance_oper = @bal_oper, nat_balance = @bal_nat    
    where sequence_id = @row_id    
    
    delete from #in_gltrxdet     
      where summarize = 1 and account_code = @account AND reference_code = @reference_code AND     
        nat_cur_code = @nat_cur_code and rate = @rate and isnull(rate_oper,0) = @rate_oper AND    
        sequence_id != @row_id    
    select @row_id = isnull((select min( sequence_id ) from #in_gltrxdet     
      where summarize = 1 and sequence_id > @row_id),null)    
  end    
      
  select @min_seq = isnull((select min(sequence_id) from #in_gltrxdet),1)    
    
  INSERT #gltrxdet ( journal_ctrl_num,  sequence_id,  rec_company_code, company_id ,     
 account_code    , description, document_1    ,      
 document_2      , reference_code  , balance    ,    nat_balance     ,       balance_oper,     
 nat_cur_code    , rate       ,    rate_oper       ,       rate_type_home,    
 rate_type_oper  ,       posted_flag,    date_posted , trx_type,     
 offset_flag ,  seg1_code  , seg2_code ,  seg3_code,     
 seg4_code , seq_ref_id , trx_state , mark_flag ,    
 org_id )     
  SELECT  d.jcn  ,  (d.sequence_id - @min_seq + 1),  @company_code , d.company_id , d.account_code  , d.description,    
  case d.summarize     
     when 0 then trx_type + '-' + convert(varchar(8), tran_no) + '-' + convert(varchar(5), tran_ext) + '.' +    
                     convert(varchar(8),tran_line)      -- changed from d.document_1    -- v1.0
     else ''     
  end ,     
  convert(varchar(10), tran_no) + '-' + convert(varchar(5), tran_ext) + '.' +    
       convert(varchar(8),tran_line),      -- document_2   -- v1.0 
 d.reference_code,     
 (SIGN((d.balance)) * ROUND(ABS((d.balance)) + 0.0000001, @home_prec)) ,     
 (SIGN((d.nat_balance)) * ROUND(ABS((d.nat_balance)) + 0.0000001, @nat_prec)) ,     
 (SIGN((d.balance_oper)) * ROUND(ABS((d.balance_oper)) + 0.0000001, @oper_prec)),    
 d.nat_cur_code  , d.rate     , d.rate_oper  , d.rate_type_home,    
 d.rate_type_oper, 0    , 0  , 111       ,    
 0  ,  d.seg1_code, d.seg2_code , d.seg3_code ,    
 d.seg4_code , 0    , 0  , 0,    
 org_id         
  FROM  #in_gltrxdet d    
    
  if @@error != 0     
  BEGIN    
    exec @result = pctrlupd_sp @process_ctrl_num, @process_state    
    select @err = -35    
    RETURN     
  END    
    
-- *********************************************************************************************************************    
  --CALL gltrxvfy_sp to check/verify multicurrency rounding error    
  DECLARE @balance_home float, @natural_balance float, @sq_id int, @trx_type smallint    
       
  IF ( @debug > 1 )    
  BEGIN    
    SELECT '*****************  Entering gltrxvfy_sp ******************'    
    SELECT 'Journal No.        : '+@journalnum    
    SELECT 'Debug Level        : '+convert(char(10), @debug )    
  END    
      
  SELECT @balance_home = 0.0, @balance_oper = 0.0, @natural_balance = 0.0    
    
  IF ( @debug > 1 )    
  BEGIN     
    SELECT 'GLTRXVFY - Details From #GLTRXDET'    
    SELECT convert(char(25), @oper_prec)    
    SELECT convert( char(20), journal_ctrl_num )+    
      convert( char(35), rate_oper )+    
      convert( char(35), balance_oper ) +    
      convert( char(35), balance )    
    FROM  #gltrxdet    
  END    
    
  SELECT @balance_home = -SUM((SIGN((balance)) * ROUND(ABS((balance)) + 0.0000001, @home_prec))),    
  @balance_oper = -SUM((SIGN((balance_oper)) * ROUND(ABS((balance_oper)) + 0.0000001, @oper_prec))),    
  @natural_balance = -SUM((SIGN((nat_balance)) * ROUND(ABS((nat_balance)) + 0.0000001, @nat_prec))),    
  @io_ind = sum(case when isnull(org_id,'') != @a_control_org_id then 1 else 0 end)    
  FROM #gltrxdet    
      
  SELECT @balance_home = ISNULL(@balance_home,0.0), @balance_oper = ISNULL(@balance_oper,0.0),    
    @natural_balance = ISNULL(@natural_balance,0.0)    
    
  IF ( @debug > 1 )    
  BEGIN     
    SELECT 'GLTRXVFY - Check balances'    
    SELECT convert(char(25), @balance_home)    
    SELECT convert(char(25), @balance_oper)    
    SELECT convert(char(25), @natural_balance)    
  END    
    
  IF NOT ((ABS((@balance_home)-(0.0)) < 0.0000001) AND (ABS((@balance_oper)-(0.0)) < 0.0000001) AND    
   (ABS((@balance_oper)-(0.0)) < 0.0000001))    
  BEGIN    
    select @sq_id = 1 + max(sequence_id) from #gltrxdet    
     
    set rowcount 1    
    INSERT #gltrxdet ( journal_ctrl_num,  sequence_id,  rec_company_code, company_id ,     
 account_code    , description, document_1    ,      
 document_2      , reference_code  , balance    ,    nat_balance     ,       balance_oper,     
 nat_cur_code    , rate       ,    rate_oper       ,       rate_type_home,    
 rate_type_oper  ,       posted_flag,    date_posted , trx_type,     
 offset_flag ,  seg1_code  , seg2_code ,  seg3_code,     
 seg4_code , seq_ref_id , trx_state , mark_flag ,    
 org_id )     
    SELECT  d.jcn , @sq_id, @company_code , d.company_id , @translation_rounding_acct ,      
 'Currency translation adjustment','','', '', @balance_home, @natural_balance, @balance_oper,    
 @a_nat_curr  , 0.0 , 0.0 , d.rate_type_home,    
 d.rate_type_oper, 0, 0, 111,    
 0  ,  @seg1_code, @seg2_code , @seg3_code ,    
 @seg4_code , 0    , 0  , 0,    
 org_id         
    FROM  #in_gltrxdet d    
      
    IF @@error != 0    
    BEGIN    
      set rowcount 0    
      exec @result = pctrlupd_sp @process_ctrl_num, @process_state    
      select @err = -37    
      RETURN     
    END    
    set rowcount 0    
  end    
    
    
  if @io_ind != 0    
  begin    
    update #gltrx    
    set interbranch_flag = 1     
  end    
-- *********************************************************************************************************************    
    
  BEGIN TRAN    
    
  -- Set to Intermediate Posted     
  UPDATE in_gltrxdet    
  SET posted_flag = 'S'    
  from #in_gltrxdet_rows d, in_gltrxdet t    
  WHERE d.row_id = t.row_id and t.posted_flag = 'W'     
    and t.date_posted = @post_time    
    
  --CALL gltrxval_sp to validate transaction    
  EXEC @result = gltrxval_sp @company_code, @company_code, NULL, NULL, @debug    
    
  IF @result != 0    
  BEGIN    
    ROLLBACK TRAN    
    exec @result = pctrlupd_sp @process_ctrl_num, @process_state    
    select @err = -60    
    RETURN     
  END    
    
  --CALL gltrxsav_sp    
  EXEC @result = gltrxsav_sp @process_ctrl_num, @company_code, @debug    
    
  IF @result != 0    
  BEGIN    
    ROLLBACK TRAN    
    exec @result = pctrlupd_sp @process_ctrl_num, @process_state    
    select @err = -70    
    RETURN     
  END    
    
  COMMIT TRAN    
    
  exec @result = pctrlupd_sp @process_ctrl_num, @process_state    
    
  if @meth = 1     
  BEGIN    
    EXEC @result = glpsindp_sp  @process_ctrl_num, @company_code, @debug    
    
    IF @result != 0    
    BEGIN    
      select @err = -80    
      RETURN     
    END    
  END    
  ELSE     
  BEGIN    
    delete #gldtrx          -- mls 8/26/99 SCR 70 20464 start     
    delete #gldtrdet    
    delete #summary    
    delete #sumhdr    
    delete #hold    
    delete #drcr          -- mls 8/26/99 SCR 70 20464 end    
    delete #updglbal          -- mls 4/26/01 SCR 26816    
    delete #acct          -- mls 4/26/01 SCR 26816    
    
    IF NOT EXISTS( SELECT * FROM glco (nolock) WHERE batch_proc_flag = 1 )    
    begin    
      EXEC @result = glpsmkbt_sp @process_ctrl_num, @company_code, @debug    
    
      IF @result != 0    
      BEGIN    
        select @err = -90    
        RETURN     
      END     
    end    
    
    select @batch_code = isnull((SELECT min(batch_code)     -- mls 9/30/99 SCR ?????    
      FROM gltrx (nolock) WHERE process_group_num = @process_ctrl_num),'')    
     
    if @batch_code = ''    
    BEGIN    
      select @err = -100    
      RETURN     
    END    
    
    EXEC @result = glpsprep_sp @batch_code, @debug    
    
    IF @result != 0    
    BEGIN    
      select @err = -92    
      RETURN     
    END    
    
    EXEC @result = glpsechk_sp @batch_code, @company_code, @company_code, @debug    
    
    IF @result != 0    
    BEGIN    
      select @err = -94    
      RETURN     
    END    
    
    
    
    
    
    
    EXEC @result = gledldp_sp 1, @batch_code,  @debug -- mls 8/14/02 SCR 29270    
    
    IF @result != 0    
    BEGIN    
      select @err = -98    
      RETURN     
    END    
    
     
    
    
    
    
    
    
    EXEC @result = gledldb_sp @db_name, @db_name, 1 , 0 ,  @debug -- mls 8/14/02 SCR 29270    
    IF @result != 0    
    BEGIN    
      select @err = -97    
      RETURN     
    END    
    
    delete from #gltrxedt1                              -- mls 8/26/02 SCR 29606    
    
    EXEC @result = glpshold_sp @batch_code, @debug    
    
    IF @result != 0    
    BEGIN    
      select @err = -96    
      RETURN     
    END    
     
    EXEC @result = glpspost_sp @batch_code, @debug    
    
    IF @result != 0    
    BEGIN    
      select @err = -110    
      RETURN     
    END    
     
    update gltrx set posted_flag = 1 where batch_code = @batch_code and hold_flag <> 1    
    
    if @@error <> 0     
    BEGIN    
      select @err = -120    
      RETURN     
    END    
    
    
    
    
    
    
    
    
    SELECT @batch_mode_on = batch_proc_flag    
    FROM glco    
    
    IF ( @batch_mode_on = 1 )    
 IF EXISTS(Select * from gltrx where batch_code = @batch_code and posted_flag = 1)    
  EXEC batupdst_sp @batch_code, 1     
 ELSE    
  EXEC batupdst_sp @batch_code, 5     
    
    if @@error <> 0     
    BEGIN    
      select @err = -125    
      RETURN     
    END    
  END    
    
END --While on apply table    
    
if @bad_apply_date_cnt <> 0        -- mls 3/8/00 SCR 22699 start    
begin    
  select @err = -200    
  return    
end    
if @bad_balance_cnt <> 0    
begin    
  select @err = -210    
  return    
end           -- mls 3/8/00 SCR 22699 end    
    
select @err = 1    
return 1    
    
GO
GRANT EXECUTE ON  [dbo].[adm_process_gl] TO [public]
GO
