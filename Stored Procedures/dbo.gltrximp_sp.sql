SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO











CREATE PROCEDURE [dbo].[gltrximp_sp]  @journal_ctrl_num varchar(16),
                              @rec_company_code varchar(8),
                              @account_code   varchar(32),
                              @description    varchar(40),
                              @document_1   varchar(16),
                              @reference_code   varchar(32),
                              @currency_code    varchar(8),
                              @trx_type   smallint,
                              @date     int,
                              @debit      float,
                              @credit     float,
                              @home_curr_code   varchar(8),
                              @oper_curr_code   varchar(8),
			      @hdr_org_id	varchar(30), --REV 1.2
			      @hdr_company_code varchar(8),
			      @row_id     int
			      

AS
DECLARE
  @company_id   smallint,
  @sequence_id    int,
  @balance    float,
  @nat_balance    float,
  @balance_oper   float,
  @home_rate    float,
  @oper_rate    float,
  @precision_home		smallint,
  @precision_oper		smallint,
  @acct_curr_code   varchar(8),
  @seg1_code    varchar(32),
  @seg2_code    varchar(32),
  @seg3_code    varchar(32),
  @seg4_code    varchar(32),
  @rate_type_home   varchar(8),
  @rate_type_oper   varchar(8),
  @inactive_flag    smallint,
  @active_date    int,
  @inactive_date    int,
  @result     int,
  @error      int,
  @company_code_default varchar(8),
  @org_id	varchar(30),
  @account_code1   varchar(32),
  @seq_id_max      int 







select @account_code1 = @account_code





SELECT  @error = 0






SELECT  @seg1_code  = seg1_code,
  @seg2_code  = seg2_code,
  @seg3_code  = seg3_code,
  @seg4_code  = seg4_code,
  @acct_curr_code = currency_code,
  @rate_type_home = rate_type_home,
  @rate_type_oper = rate_type_oper,
  @inactive_flag  = inactive_flag,
  @active_date  = active_date,
  @inactive_date  = inactive_date
FROM  glchart
WHERE account_code  = @account_code




IF ( @@rowcount = 0 )
  SELECT  @error = 1





	
	IF (@error=0) 
		BEGIN
			SELECT @org_id = organization_id FROM glchart WHERE account_code = @account_code
		END
	ELSE
		BEGIN
			SELECT @org_id =@hdr_org_id
		END
	
	
	IF NOT EXISTS (SELECT 1 FROM sm_accounts_access_vw WHERE account_code = @account_code) AND @error = 0
		SELECT @error =8
	
	IF NOT EXISTS (SELECT 1 FROM Organization WHERE organization_id =@org_id) AND @error = 0
		SELECT  @error =9
	




IF ( @inactive_flag = 1 AND @error = 0 )
  SELECT  @error = 2



IF ( @error = 0 AND ((@date < @active_date AND @active_date !=0) OR 
                     (@date >= @inactive_date AND @inactive_date != 0)) )
  SELECT @error = 3


 
SELECT  @sequence_id = ISNULL(MAX(sequence_id),0) + 1
FROM  #gltrxdet1150

SELECT  @seq_id_max = ISNULL(MAX(sequence_id),0) + 1
FROM  #gltrxdettemp1157

if( @seq_id_max >= @sequence_id )
BEGIN
  SELECT  @sequence_id = @seq_id_max
END


IF ( @acct_curr_code != ' '  AND @acct_curr_code IS NOT NULL )             
  SELECT  @currency_code = @acct_curr_code 



IF ( @rate_type_home = ' ' OR @rate_type_home IS NULL )
  SELECT @rate_type_home = rate_type_home
  FROM   glco



IF ( @rate_type_oper = ' ' OR @rate_type_oper IS NULL )
  SELECT @rate_type_oper = rate_type_oper
  FROM   glco






IF (@rec_company_code = '' OR @rec_company_code = ' ' OR @rec_company_code IS NULL)
	SELECT @rec_company_code = company_code
	FROM  glco

SELECT  @company_id   = -1
SELECT  @company_id   = company_id,
  @rec_company_code = company_code
FROM  glco
WHERE company_code = @rec_company_code




IF( @company_id = -1)
BEGIN
	SELECT  @company_id   = 0,
	  @rec_company_code = ''
	SELECT @error = 7
END





IF( @company_id != 0 AND @rec_company_code != @hdr_company_code AND @error = 1 )
	SELECT @org_id = organization_id FROM Organization WHERE outline_num = 1 	








EXEC @result = CVO_Control..mccurate_sp  @date,
                            @currency_code,
                            @home_curr_code,
                            @rate_type_home,
                            @home_rate OUTPUT,
                            0 
IF (@result != 0)
BEGIN



  IF ( @error = 0 )
    SELECT  @error = 4
  SELECT  @home_rate = 0.0
END



EXEC @result = CVO_Control..mccurate_sp  @date,
                            @currency_code,
                            @oper_curr_code,
                            @rate_type_oper,
                            @oper_rate OUTPUT,
                            0 
IF (@result != 0)
BEGIN



  IF (@error = 0) 
    SELECT  @error = 5
  SELECT  @oper_rate = 0.0
END




SELECT 	@precision_home = curr_precision
FROM	glcurr_vw
WHERE	currency_code = @home_curr_code	

SELECT 	@precision_oper = curr_precision
FROM	glcurr_vw
WHERE	currency_code = @oper_curr_code	





IF (@debit = 0.0)
  IF (@credit = 0.0)
    SELECT  @nat_balance = 0.0
  ELSE IF (@credit > 0.0)
    SELECT  @nat_balance = (-1)*@credit
  ELSE
   SELECT  @nat_balance = @credit
ELSE IF (@debit > 0.0)
  SELECT @nat_balance = @debit
ELSE
  SELECT @nat_balance = (-1)*@debit
SELECT  @balance      = (SIGN(@nat_balance * ( SIGN(1 + SIGN(@home_rate))*(@home_rate) + 
(SIGN(ABS(SIGN(ROUND(@home_rate,6))))/(@home_rate + SIGN(1 - ABS(SIGN(ROUND(@home_rate,6)))))) 
* SIGN(SIGN(@home_rate) - 1) )) * ROUND(ABS(@nat_balance * ( SIGN(1 + SIGN(@home_rate))*(@home_rate) +
(SIGN(ABS(SIGN(ROUND(@home_rate,6))))/(@home_rate + SIGN(1 - ABS(SIGN(ROUND(@home_rate,6)))))) * 
SIGN(SIGN(@home_rate) - 1) )) + 0.0000001, @precision_home)),
  @balance_oper = (SIGN(@nat_balance * ( SIGN(1 + SIGN(@oper_rate))*(@oper_rate) + (SIGN(ABS(SIGN(ROUND(@oper_rate,6))))/
  (@oper_rate + SIGN(1 - ABS(SIGN(ROUND(@oper_rate,6)))))) * SIGN(SIGN(@oper_rate) - 1) )) * 
  ROUND(ABS(@nat_balance * ( SIGN(1 + SIGN(@oper_rate))*(@oper_rate) + (SIGN(ABS(SIGN(ROUND(@oper_rate,6))))/
  (@oper_rate + SIGN(1 - ABS(SIGN(ROUND(@oper_rate,6)))))) * SIGN(SIGN(@oper_rate) - 1) )) + 0.0000001, @precision_oper))



IF (@reference_code != '')
BEGIN
  EXEC @result = glrefact_sp  @account_code,
        @reference_code,
        0
  IF  (@result !=1)
  BEGIN
  SELECT  @error = 6  -- , @reference_code = ''
  END
END



IF (@error != 0)
BEGIN
  IF (@error = 1)
    SELECT  @description = '*** ERROR:Account Code is Invalid' ,
	    @account_code = ' ',
	    @seg1_code = ' ',
	    @seg2_code = ' ',
	    @seg3_code = ' ',
	    @seg4_code = ' '
  IF (@error = 2)
    SELECT  @description = '*** ERROR:Account is Inactive'  
  IF (@error = 3)
    SELECT  @description = '*** ERROR:Account is Inactive in this date' 
  IF (@error = 4)
    SELECT  @description = '*** ERROR:Invalid Home Rate' 
  IF (@error = 5)
    SELECT  @description = '*** ERROR:Invalid Operational Rate' 
  IF (@error = 6) 
    SELECT  @description = '*** ERROR:Invalid Reference Code'
  IF (@error = 7)
    SELECT  @description = '*** ERROR:Invalid Company Code'	
  IF (@error = 8)
    SELECT  @description = '*** ERROR:Account without access ', 
	    @account_code = ' ',
	    @seg1_code = ' ',
	    @seg2_code = ' ',
	    @seg3_code = ' ',
	    @seg4_code = ' '
 IF (@error = 9)
    SELECT  @description = '*** ERROR:Organization without access ', @account_code = ' ',
	    @seg1_code = ' ',
	    @seg2_code = ' ',
	    @seg3_code = ' ',
	    @seg4_code = ' '
	   -- Rev 1.2  @org_id    = ' '
END


/**************  
INSERT  #gltrxdet1150
(
        timestamp,    journal_ctrl_num, sequence_id,
  rec_company_code, company_id,   account_code,
  description,    document_1,   document_2,
  reference_code,   balance,    nat_balance,
  nat_cur_code,     rate,     posted_flag,
        date_posted,            trx_type,   offset_flag,
  seg1_code,              seg2_code,    seg3_code,
  seg4_code,              seq_ref_id,   balance_oper,
  rate_oper,              rate_type_home,   rate_type_oper,
  org_id
)
SELECT
  NULL,     @journal_ctrl_num,  @sequence_id,
  @rec_company_code,      @company_id,    @account_code,
  @description,   @document_1,    @journal_ctrl_num,
  @reference_code,        @balance,   @nat_balance,
  @currency_code,   @home_rate,   0,
  0,      @trx_type,    0,
  @seg1_code,   @seg2_code,   @seg3_code,
  @seg4_code,             0,          @balance_oper,
  @oper_rate,   @rate_type_home,  @rate_type_oper,
  @org_id
****************/
INSERT  #gltrxdettemp1157
(
        timestamp,    journal_ctrl_num, sequence_id,
  rec_company_code, company_id,   account_code,
  description,    document_1,   document_2,
  reference_code,   balance,    nat_balance,
  nat_cur_code,     rate,     posted_flag,
        date_posted,            trx_type,   offset_flag,
  seg1_code,              seg2_code,    seg3_code,
  seg4_code,              seq_ref_id,   balance_oper,
  rate_oper,              rate_type_home,   rate_type_oper,
  org_id, account_code1, row_id
)
SELECT
  NULL,     @journal_ctrl_num,  @sequence_id,
  @rec_company_code,      @company_id,    @account_code1,
  @description,   @document_1,    @journal_ctrl_num,
  @reference_code,        @balance,   @nat_balance,
  @currency_code,   @home_rate,   0,
  0,      @trx_type,    0,
  @seg1_code,   @seg2_code,   @seg3_code,
  @seg4_code,             0,          @balance_oper,
  @oper_rate,   @rate_type_home,  @rate_type_oper,
  @org_id,@account_code1, @row_id




IF (@error !=0)
  SELECT 1
ELSE
  SELECT 0
RETURN
GO
GRANT EXECUTE ON  [dbo].[gltrximp_sp] TO [public]
GO
