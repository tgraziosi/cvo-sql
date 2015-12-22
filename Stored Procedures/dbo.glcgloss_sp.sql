SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROC [dbo].[glcgloss_sp] (
	@journal_ctrl_num       varchar(16),
	@gain_loss_account      varchar(32),
	@company_code		varchar(8),
	@company_id		smallint,
	@trx_type		smallint,
	@seq_id                 int,
	@acct_mask		varchar(35),
	@home_curr_code		varchar(8) )
AS

DECLARE @balance float,		@balance_oper float,	@seg1_code varchar(32), 
	@rate_type_home varchar(8),
	@rate_type_oper varchar(8),
	@seg2_code varchar(32), @seg3_code varchar(32),	@seg4_code varchar(32),
	@oper_currency		varchar(8),
	@home_currency		varchar(8),
	@precision		smallint,
	@precision_oper		smallint,
	@str_msg		varchar(255)

SELECT  @home_currency = home_currency,
	@oper_currency = oper_currency,
	@rate_type_home = rate_type_home,
	@rate_type_oper = rate_type_oper
FROM glco

SELECT	@precision = curr_precision
FROM	glcurr_vw
WHERE	currency_code = @home_currency

SELECT	@precision_oper = curr_precision
FROM	glcurr_vw
WHERE	currency_code = @oper_currency




SELECT	@balance = ISNULL( SUM(balance), 0.00),
	@balance_oper = ISNULL( SUM(balance_oper), 0.00) 
FROM 	gltrxdet 
WHERE 	journal_ctrl_num = @journal_ctrl_num
AND 	trx_type = @trx_type

SELECT	@balance = -(SIGN(@balance) * ROUND(ABS(@balance) + 0.0000001, @precision))
SELECT	@balance_oper = -(SIGN(@balance_oper) * ROUND(ABS(@balance_oper) + 0.0000001, @precision_oper)) 

IF ISNULL(@balance,0) = 0
        RETURN 




SELECT	@seg1_code = seg1_code,
	@seg2_code = seg2_code,
	@seg3_code = seg3_code,
	@seg4_code = seg4_code
FROM	glchart
WHERE	account_code = @gain_loss_account






EXEC appgetstring_sp "STR_CON_GAIN_LOSS", @str_msg OUT

INSERT INTO gltrxdet (
	journal_ctrl_num,	sequence_id,	rec_company_code,
	company_id,		account_code,	description,
	document_1,		document_2,	reference_code,
	balance,		nat_balance, 	nat_cur_code,
	rate,			posted_flag,	date_posted,
	trx_type,		offset_flag,	seg1_code,
	seg2_code,		seg3_code, 	seg4_code,
	seq_ref_id,		balance_oper,	rate_oper,
	rate_type_home,		rate_type_oper)
VALUES (
	@journal_ctrl_num,	@seq_id,	@company_code,
	@company_id, 		ISNULL(@gain_loss_account, " "), @str_msg,
	"",			"",		"",
	@balance,	0,		@home_curr_code,
	1,			0,		0,
	@trx_type,		0,		ISNULL(@seg1_code, " "),
	ISNULL(@seg2_code, " "), ISNULL(@seg3_code, " "), ISNULL(@seg4_code, " "),
	2,			@balance_oper, 0.0,
	@rate_type_home,	@rate_type_oper )

/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glcgloss_sp] TO [public]
GO
