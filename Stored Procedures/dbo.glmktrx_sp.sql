SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

	
CREATE  PROCEDURE [dbo].[glmktrx_sp]        
        @batch_ctrl_num	varchar(16),	
	@sys_date	int,		
	@next_prd	int,		
	@debug		smallint = 0	
							
AS DECLARE 						
	@work_time		datetime,
        @period_end	  	int,				
	@currency		smallint,
	@rate_type_home		varchar(8),
	@rate_type_oper		varchar(8),
	@home_cur_code		varchar(8),
	@oper_cur_code		varchar(8),
	@userid			int,		
	@username		nvarchar(30),	
	@ret			int		



IF ( @debug >= 3 )
BEGIN
	SELECT	"Creating new transactions - repeating"
	SELECT	@work_time = getdate()
END




INSERT  gltrx(
        journal_type,       
        journal_ctrl_num,   
        journal_description,        
        date_entered,       
        date_applied,       
        recurring_flag,
        repeating_flag,     
        reversing_flag,     
        hold_flag,                
        posted_flag,        
        date_posted,        
        source_batch_code,
        batch_code,         
        type_flag,          
        intercompany_flag,
        company_code,       
        app_id,             
        home_cur_code,
        document_1,         
        trx_type,           
        user_id,
	source_company_code,
        process_group_num,
        oper_cur_code,
	org_id,
	interbranch_flag )
SELECT  journal_type,       
	new_journal_ctrl_num,          
	journal_description,        
        @sys_date,
        @next_prd,         
        0,
        repeating_flag,     
        reversing_flag,     
        1,
        0,                  
        0,                  
        batch_code,
        @batch_ctrl_num,   
        4,          
        intercompany_flag,
        company_code,       
        app_id,             
        home_cur_code,
        t.journal_ctrl_num,	    
        trx_type,           
        user_id,
	source_company_code,
        ' ',
        oper_cur_code,
	org_id,
	interbranch_flag
FROM    gltrx t, #new_trx n
WHERE	t.journal_ctrl_num = n.journal_ctrl_num
  AND	n.flag_type = 1





INSERT  gltrxdet(
        journal_ctrl_num,  
        sequence_id,         
        account_code,
        posted_flag,       
        date_posted,         
        balance, 
        document_1,
        description,         
        rec_company_code,
        company_id,        
        document_2,          
        reference_code,
        nat_balance,       
        nat_cur_code,        
        rate,
        trx_type,          
        offset_flag,         
        seg1_code,
        seg2_code,         
        seg3_code,           
        seg4_code,
        seq_ref_id,
        balance_oper,
        rate_oper,
        rate_type_home,
        rate_type_oper,
	org_id)

SELECT  new_journal_ctrl_num,         
	sequence_id,         
	account_code,
        0,                 
        0,                   
        0,
        document_1,        
        description,         
        rec_company_code,
        company_id,        
        t.journal_ctrl_num,         
        reference_code,
        0,       	   
        nat_cur_code,        
        0,
        trx_type,          
        offset_flag,         
        seg1_code,
        seg2_code,         
        seg3_code,           
        seg4_code,
        seq_ref_id,
        0.0,
        0.0,
        rate_type_home,
        rate_type_oper,
	org_id

FROM    gltrxdet t, #new_trx n
WHERE	t.journal_ctrl_num = n.journal_ctrl_num
  AND	n.flag_type = 1
  AND   t.seq_ref_id != -1
  





INSERT  gltrxdet(
        journal_ctrl_num,  
        sequence_id,         
        account_code,
        posted_flag,       
        date_posted,         
        balance, 
        document_1,        
        description,         
        rec_company_code,
        company_id,        
        document_2,          
        reference_code,
        nat_balance,       
        nat_cur_code,        
        rate,
        trx_type,          
        offset_flag,         
        seg1_code,
        seg2_code,         
        seg3_code,           
        seg4_code,
        seq_ref_id,
        balance_oper,
        rate_oper,
        rate_type_home,
        rate_type_oper,
	org_id )              

SELECT  new_journal_ctrl_num,         
	sequence_id,         
	account_code,
        0,                 
        0,                   
        0,
        document_1,        
        description,         
        rec_company_code,
        company_id,        
        n.journal_ctrl_num,		
        reference_code,
        0,       	   
        nat_cur_code,        
        0,
        trx_type,          
        offset_flag,         
        seg1_code,
        seg2_code,         
        seg3_code,           
        seg4_code,
        seq_ref_id,
        0.0,
        0.0,
        rate_type_home,
        rate_type_oper,
	org_id		

FROM    glictrxd t, #new_trx n
WHERE	t.journal_ctrl_num = n.journal_ctrl_num
  AND	n.flag_type = 1
  AND   t.seq_ref_id != -1  





SELECT @currency = NULL, @home_cur_code = NULL, @oper_cur_code = NULL

SELECT @currency = multi_currency_flag,
       @rate_type_home = rate_type_home,
       @rate_type_oper = rate_type_oper,
       @home_cur_code = home_currency,
       @oper_cur_code = oper_currency
FROM   glco 


INSERT #rates (	from_currency,
		to_currency,
		rate_type,
		date_applied,
		rate )
SELECT 	DISTINCT t.nat_cur_code,
		 @home_cur_code,
		 t.rate_type_home,
		 @next_prd,
		 0.0
FROM	gltrxdet t, #new_trx n
WHERE	t.journal_ctrl_num = n.new_journal_ctrl_num
AND	n.flag_type = 1
	
INSERT #rates (	from_currency,
		to_currency,
		rate_type,
		date_applied,
		rate )
SELECT 	DISTINCT t.nat_cur_code,
		 @oper_cur_code,
		 t.rate_type_oper,
		 @next_prd,
		 0.0
FROM	gltrxdet t, #new_trx n
WHERE	t.journal_ctrl_num = n.new_journal_ctrl_num
AND	n.flag_type = 1

EXEC CVO_Control..mcsrates_sp


UPDATE 	gltrxdet 
SET	rate = b.rate
FROM	gltrxdet t, #new_trx n, #rates b
WHERE	t.journal_ctrl_num = n.new_journal_ctrl_num
AND	n.flag_type = 1
AND	t.nat_cur_code = b.from_currency
AND	b.to_currency = @home_cur_code
AND	t.rate_type_home = b.rate_type

UPDATE 	gltrxdet 
SET	rate_oper = b.rate
FROM	gltrxdet t, #new_trx n, #rates b
WHERE	t.journal_ctrl_num = n.new_journal_ctrl_num
AND	n.flag_type = 1
AND	t.nat_cur_code = b.from_currency
AND	b.to_currency = @oper_cur_code
AND	t.rate_type_oper = b.rate_type





IF ( @currency = 0 )
BEGIN
	UPDATE gltrxdet
	SET    rate = 1.0
	FROM   gltrxdet b, #new_trx n
	WHERE  b.journal_ctrl_num = n.new_journal_ctrl_num
	AND    n.flag_type = 1
END
ELSE
BEGIN
	UPDATE gltrxdet
	SET    rate = 1.0
	FROM   gltrx a, gltrxdet b, #new_trx n
	WHERE  a.journal_ctrl_num = b.journal_ctrl_num
	AND    a.journal_ctrl_num = n.new_journal_ctrl_num
	AND    a.home_cur_code = b.nat_cur_code
	AND    n.flag_type = 1
END

IF ( @debug >= 3 )
BEGIN
	SELECT	"Creating repeating TRXes - time: " +
		convert (varchar(10), datediff( ms, @work_time, getdate() ) ) +
		" ms" " "
	SELECT	"Creating new transactions - reversing"
	SELECT	@work_time = getdate()
END




INSERT  gltrx(
        journal_type,       
        journal_ctrl_num,   
        journal_description,        
        date_entered,       
        date_applied,       
        recurring_flag,
        repeating_flag,     
        reversing_flag,     
        hold_flag,                
        posted_flag,        
        date_posted,        
        source_batch_code,
        batch_code,         
        type_flag,          
        intercompany_flag,
        company_code,       
        app_id,             
        home_cur_code,
        document_1,         
        trx_type,           
        user_id,
	source_company_code,
        process_group_num,
        oper_cur_code,
	org_id,
	interbranch_flag )

SELECT  journal_type,       
	new_journal_ctrl_num,          
	journal_description,        
        @sys_date,     
        @next_prd,         
        0,
        0,                  
        0,                  
        hold_flag,                 
        0,                  
        0,                  
        batch_code,
        @batch_ctrl_num,   
        5,          
        intercompany_flag,
        company_code,       
        app_id,             
        home_cur_code,
        t.journal_ctrl_num,        
        130,           
        user_id,
	source_company_code,
        process_group_num,
        oper_cur_code,
	org_id,
	interbranch_flag

FROM    gltrx t, #new_trx n
WHERE	t.journal_ctrl_num = n.journal_ctrl_num
  AND	n.flag_type = 2

INSERT  gltrxdet(
        journal_ctrl_num,   
        sequence_id,        
        account_code,
        posted_flag,        
        date_posted,        
        balance, 
        document_1,         
        description,        
        rec_company_code,
        company_id,         
        document_2,         
        reference_code,
        nat_balance,        
        nat_cur_code,       
        rate,
        trx_type,           
        offset_flag,        
        seg1_code,
        seg2_code,          
        seg3_code,          
        seg4_code,
        seq_ref_id,
        balance_oper,
        rate_oper,
        rate_type_home,
        rate_type_oper,
	org_id )

SELECT  new_journal_ctrl_num,          
	sequence_id,        
	account_code,
        0,                  
        0,                  
        ( -balance ), 
        document_1,         
        description,        
        rec_company_code,
        company_id,         
        t.journal_ctrl_num,	
        reference_code,
        ( -nat_balance ),   
        nat_cur_code,       
        rate,
        130,           
        offset_flag,        
        seg1_code,
        seg2_code,          
        seg3_code,          
        seg4_code,
        seq_ref_id,
        ( -balance_oper ),
        rate_oper,
        rate_type_home,
        rate_type_oper,
	org_id

FROM    gltrxdet t, #new_trx n
WHERE	t.journal_ctrl_num = n.journal_ctrl_num
  AND	n.flag_type = 2
  AND   t.seq_ref_id != -1
  




INSERT  gltrxdet(
        journal_ctrl_num,   
        sequence_id,        
        account_code,
	posted_flag,        
	date_posted,        
	balance, 
        document_1,         
        description,        
        rec_company_code,
        company_id,         
        document_2,         
        reference_code,
	nat_balance,        
	nat_cur_code,       
	rate,
        trx_type,           
        offset_flag,        
        seg1_code,
        seg2_code,          
        seg3_code,          
        seg4_code,
        seq_ref_id,
        balance_oper,
        rate_oper,
        rate_type_home,
        rate_type_oper,
	org_id )		

SELECT  new_journal_ctrl_num,          
	sequence_id,        
	account_code,
	0,                  
	0,                  
	( -balance ), 
        document_1,         
        description,        
        rec_company_code,
        company_id,         
        t.journal_ctrl_num,	
        reference_code,
	( -nat_balance ),   
	nat_cur_code,       
	rate,
        130,           
        offset_flag,        
        seg1_code,
        seg2_code,          
        seg3_code,          
        seg4_code,
        seq_ref_id,
        ( - balance_oper ),
        rate_oper,
        rate_type_home,
        rate_type_oper,
	org_id		

FROM    glictrxd t, #new_trx n
WHERE	t.journal_ctrl_num = n.journal_ctrl_num
  AND	n.flag_type = 2
  AND   t.seq_ref_id != -1
  

IF ( @debug >= 3 )
BEGIN
	SELECT	"Creating reversing TRXes - time: " +
		convert (varchar(10), datediff( ms, @work_time, getdate() ) ) +
		" ms" " "
	SELECT	"Creating new transactions - recurring"
	SELECT	@work_time = getdate()
END











SELECT	@period_end = NULL

SELECT  @period_end = MAX( period_end_date )
FROM    glprd
WHERE   period_end_date < @next_prd


INSERT  glrecur(
        journal_ctrl_num,         
        recur_description,
        journal_type,             
        tracked_balance_flag,
       	percentage_flag,          
       	continuous_flag,
        year_end_type,            
        recur_if_zero_flag,
        hold_flag,                
        posted_flag,
        tracked_balance_amount,   
        base_amount,
        date_last_applied,        
        date_end_period_1,
        date_end_period_2,        
        date_end_period_3,
        date_end_period_4,        
        date_end_period_5,
        date_end_period_6,        
        date_end_period_7,
        date_end_period_8,        
        date_end_period_9,
        date_end_period_10,       
        date_end_period_11,
        date_end_period_12,       
        date_end_period_13,
        all_periods,              
        number_of_periods, 
        period_interval,          
        intercompany_flag,
        nat_cur_code,             
        document_1,
	rate_type_home,
	rate_type_oper,
	org_id,
	interbranch_flag )

SELECT  new_journal_ctrl_num,                
	journal_description,
        journal_type,             
        0,
        0,                        
        1,
        3,                        
        1,
        1,                        
        0,
        0,                        
        0.0,
        @period_end,                        
        @next_prd,
        0,               
        0,
        0,               
        0,
        0,               
        0,
        0,               
        0,
        0,              
        0,
        0,              
        0,
        0,                        
        13, 
        1,                        
        intercompany_flag,
        home_cur_code,            
        t.journal_ctrl_num,
	@rate_type_home,
	@rate_type_oper,
	org_id,
	interbranch_flag
FROM    gltrx t, #new_trx n
WHERE	t.journal_ctrl_num = n.journal_ctrl_num
  AND	n.flag_type = 3




INSERT  glrecdet(
	sequence_id,             
	journal_ctrl_num, 
        rec_company_code,        
        account_code,
        reference_code,          
        document_1,          
        document_2,              
        nat_cur_code,
        amount_period_1,         
        amount_period_2,
        amount_period_3,         
        amount_period_4,  
        amount_period_5,         
        amount_period_6,
        amount_period_7,         
        amount_period_8,
        amount_period_9,         
        amount_period_10, 
        amount_period_11,        
        amount_period_12, 
        amount_period_13,        
        posted_flag,
        date_applied,            
        offset_flag,
        seg1_code,               
        seg2_code,
        seg3_code,               
        seg4_code,
	seq_ref_id,
	org_id )
SELECT  sequence_id,             
	new_journal_ctrl_num, 
        rec_company_code,        
        account_code,
        reference_code,          
        document_1,
        t.journal_ctrl_num,		 
        nat_cur_code,
        balance,                 
        0,
        0,                 
        0,        
        0,                 
        0,        
        0,                 
        0,
        0,                 
        0,        
        0,                 
        0,        
        0,                 
        0,
        0,                       
        offset_flag,
        seg1_code,               
        seg2_code,
        seg3_code,               
        seg4_code, 
	seq_ref_id,
	org_id
FROM	gltrxdet t, #new_trx n
WHERE	t.journal_ctrl_num = n.journal_ctrl_num
  AND	n.flag_type = 3
  AND   t.seq_ref_id != -1
  





INSERT  glrecdet(
	sequence_id,             
	journal_ctrl_num, 
	rec_company_code,        
	account_code,
	reference_code,          
	document_1,          
	document_2,              
	nat_cur_code,
	amount_period_1,         
	amount_period_2,
	amount_period_3,         
	amount_period_4,  
	amount_period_5,         
	amount_period_6,
	amount_period_7,         
	amount_period_8,
	amount_period_9,         
	amount_period_10, 
	amount_period_11,        
	amount_period_12, 
	amount_period_13,        
	posted_flag,
	date_applied,            
	offset_flag,
	seg1_code,               
	seg2_code,
	seg3_code,               
	seg4_code, 
	seq_ref_id,
	org_id )           
SELECT  sequence_id,             
	new_journal_ctrl_num, 
	rec_company_code,        
	account_code,
	reference_code,          
	"",
	t.journal_ctrl_num,		 
	nat_cur_code,
	balance,                 
	0,
	0,                 
	0,        
	0,                 
	0,        
	0,                 
	0,
	0,                 
	0,        
	0,                 
	0,        
	0,                 
	0,
	0,                       
	offset_flag,
	seg1_code,               
	seg2_code,
	seg3_code,               
	seg4_code,
	seq_ref_id,
	org_id      
FROM	glictrxd t, #new_trx n
WHERE	t.journal_ctrl_num = n.journal_ctrl_num
  AND	n.flag_type = 3
  AND   t.seq_ref_id != -1

IF ( @debug >= 3 )
BEGIN
	SELECT	"Creating recurring TRXes - time: " +
		convert (varchar(10), datediff( ms, @work_time, getdate() ) ) +
		" ms" " "
	SELECT	"Updating batch totals"
	SELECT	@work_time = getdate()
END




SELECT DISTINCT new.journal_ctrl_num,new.new_journal_ctrl_num,hdr.trx_type
INTO #ibifc_Temp
FROM gltrx hdr
	INNER JOIN gltrxdet det ON hdr.journal_ctrl_num = det.journal_ctrl_num
	INNER JOIN #new_trx new	ON hdr.journal_ctrl_num = new.journal_ctrl_num
WHERE (hdr.recurring_flag + hdr.repeating_flag + reversing_flag) >= 1 AND
	hdr.interbranch_flag = 1 AND hdr.org_id <> det.org_id


IF EXISTS(SELECT TOP 1 journal_ctrl_num FROM #ibifc_Temp)
BEGIN

	EXEC @ret = ibget_userid_sp @userid OUTPUT, @username OUTPUT
	
	UPDATE #ibifc_Temp 
	SET #ibifc_Temp.trx_type = g.trx_type
	FROM gltrx g 
	WHERE  g.journal_ctrl_num = #ibifc_Temp.new_journal_ctrl_num AND g.interbranch_flag = 1
	
	
	DELETE ibifc WHERE EXISTS( SELECT new_journal_ctrl_num FROM #ibifc_Temp tmp WHERE tmp.new_journal_ctrl_num = link1 AND tmp.trx_type = trx_type)
	
	INSERT ibifc  
		(timestamp,		id,			date_entered,		date_applied,
		trx_type,	 	controlling_org_id,	detail_org_id,	amount,		 
		currency_code,	tax_code,		recipient_code,	originator_code,		 
		tax_payable_code,	tax_expense_code,	state_flag,	process_ctrl_num,
		link1,		link2,		link3,	username,	reference_code)
	SELECT  NULL,			NEWID(),		-1,			0,
		 trx_type,			'',			'',			0.0,
		 '',			'',			'',			'',
		 '',			'',			0,			'',
		 new_journal_ctrl_num,	'',			'',			@username,	''
	FROM #ibifc_Temp
	
	DROP TABLE #ibifc_Temp

END	




RETURN 0

GO
GRANT EXECUTE ON  [dbo].[glmktrx_sp] TO [public]
GO
