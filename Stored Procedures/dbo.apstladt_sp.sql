SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO














CREATE PROC [dbo].[apstladt_sp] @settlement_ctrl_num       varchar( 16 ),
      @i_doc_ctrl_num   varchar( 16 ),
      @amt_payment    float,
      @pay_full   smallint,
      @auto_load    smallint,
      @desc     varchar( 40 ),
      @restrict_by_cur  smallint,
      @pymt_cur_code    varchar( 8),
      @pa_date_applied  int,
      @pa_date_doc    int,
      @rate_home    float,
      @rate_oper    float,
      @rate_type_home   varchar( 8),
      @force_disc	int,
      @pay_to_code	varchar(8)
AS



DECLARE @sequence_id    int,
  @vo_sequence_id  int,
  @vendor_code    varchar( 12 ),
  @apply_to_num   varchar( 16 ),
  @apply_trx_type   smallint,
  @doc_ctrl_num   varchar( 16 ),
  @remain_bal   float,
  @amount     float,
  @amt_paid   float,
  @amt_pyt_unposted float,
  @amt_applied    float,
  @min_date_due   int,
  @cross_rate   float,
  @gain_home    float,
  @gain_oper    float,
  @vo_amt_applied  float,
  @new_bal    float,
  @result     int,
  @after_entry_flag int,
  @amt_payment_vo  float,
  @pymt_curr_precision  smallint,
  @date_aging   int,
  @trx_type   int,
  @year     int,
  @month      int,
  @day      int,
  @payoff_vo_flag  smallint,
  @disc_payoff_vo_flag smallint,
  @discount_flag    smallint,
  @discount_amt   float,
  @balance    float,
  @vo_posted_disc  float,
  @vo_amt_applied_temp float,
  @bal_fwd_flag   smallint,
  @cur_row    numeric,
  @age_apply_num    numeric,
  @home_cur_code    varchar( 8),
  @oper_cur_code    varchar( 8),
  @dis_doc		varchar(16),
  @dis_trx_type		smallint,
  @dis_terms_code		varchar(8),
  @dis_doc_date		int,
  @discount_flag_2	smallint,
  @discount_prc		float,
  @prc float, 
  @dis_trx_ctrl_num varchar(16),
  @dis_date 	int,
  @doc_date	int


   
BEGIN

  SELECT  @sequence_id = 1

  SELECT  @pymt_curr_precision  = curr_precision
  FROM  glcurr_vw
  WHERE currency_code = @pymt_cur_code

  SELECT  @home_cur_code = home_currency,
          @oper_cur_code = oper_currency
  FROM glco

  DELETE #apinppdt3450
  WHERE trx_ctrl_num = @settlement_ctrl_num

  


  EXEC appdtjul_sp @year OUTPUT, @month OUTPUT, @day OUTPUT, @pa_date_doc

  



  CREATE TABLE  #unpaid_vouchers
  (
    vendor_code   varchar( 12 ),
    doc_ctrl_num    varchar( 16 ),
    trx_type    smallint,
    date_aging    int,
    date_applied    int,
    amt_tot_chg   float,
    amt_paid_to_date  float,
    date_doc    int,
    amt_net     float,
    nat_cur_code    varchar( 8 ),
    rate_type_home    varchar( 8 ),
    rate_home   float,
    rate_oper   float,
    paid_flag   int,
    discount_flag   int NULL,
    discount_prc    float NULL,
    vo_amt_applied   float,
    vo_amt_disc_taken  float,
    sequence_id   int identity,
    cross_rate    float,
    mc_date_applied   int,
    curr_precision    int NULL,
    amt_applied   float,
    amt_disc_taken    float,
    gain_home   float,
    gain_oper   float,
    vo_posted_disc   float,
    vo_unposted_disc float,
    terms_code    varchar( 8 ),
    vo_precision     smallint,
    org_id	 varchar(30)
  )

  CREATE TABLE  #unposted_payments
  (
    vendor_code   varchar( 12 ),
    apply_to_num    varchar( 16 ),
    apply_trx_type    smallint,
    vo_amt_total   float,        
    vo_amt_disc_taken  float,

  )

  CREATE TABLE #rates 
  (
    from_currency   varchar( 8 ),
    to_currency     varchar( 8 ),
    rate_type     varchar( 8 ),
    date_applied    int,
    rate      float
  )

  





  IF ( @restrict_by_cur = 0 )           

    INSERT  #unpaid_vouchers
    (
      	vendor_code,    	doc_ctrl_num,   	trx_type,      		
	date_aging,   		amt_tot_chg,    	amt_paid_to_date,
	date_doc,   		amt_net,            	date_applied,   	
	nat_cur_code,   	rate_type_home,		rate_home,    
	rate_oper,    		paid_flag,		vo_amt_applied, 	
	vo_amt_disc_taken,	cross_rate,		mc_date_applied,    
	amt_applied,    	amt_disc_taken,		gain_home,    		
	gain_oper,    		vo_posted_disc,		vo_unposted_disc,  
	terms_code, 		vo_precision, 		org_id
    )
    SELECT  aptrxapl_vw.vendor_code,  aptrxapl_vw.trx_ctrl_num, 4091,  aptrxapl_vw.date_aging, aptrxapl_vw.amt_net - aptrxapl_vw.amt_paid_to_date ,  aptrxapl_vw.amt_paid_to_date,
      aptrxapl_vw.date_doc,   aptrxapl_vw.amt_net,    aptrxapl_vw.date_applied, 
	aptrxapl_vw.currency_code, aptrxapl_vw.rate_type_home,      aptrxapl_vw.rate_home,  
	aptrxapl_vw.rate_oper,  aptrxapl_vw.paid_flag,      0.0,      
	0.0,      	      0.0,        SIGN(SIGN(@pa_date_applied-aptrxapl_vw.date_applied+0.5)+1)*@pa_date_applied   +SIGN(SIGN(aptrxapl_vw.date_applied-@pa_date_applied-0.5)+1)*aptrxapl_vw.date_applied,
      0.0,      0.0,	      0.0,      
	0.0,      ISNULL(aptrxapl_vw.amt_discount, 0.0),      0.0,      
	terms_code, (select curr_precision from glcurr_vw where currency_code = aptrxapl_vw.currency_code), org_id
    FROM  aptrxapl_vw ,  #apvpay3450
    WHERE aptrxapl_vw.vendor_code = #apvpay3450.vendor_code
    AND aptrxapl_vw.trx_ctrl_num = aptrxapl_vw.apply_to_num
    AND aptrxapl_vw.pay_to_code = @pay_to_code   
    
    
    AND   aptrxapl_vw.paid_flag = 0 
    
    ORDER BY aptrxapl_vw.vendor_code, aptrxapl_vw.apply_to_num
  ELSE
    INSERT  #unpaid_vouchers
    (
      	vendor_code,    	doc_ctrl_num,     		trx_type,
      	date_aging,   		amt_tot_chg,      		amt_paid_to_date,
      	date_doc,   		amt_net,      		      date_applied,   
	nat_cur_code,     	rate_type_home,		      rate_home,    
	rate_oper,      	paid_flag,		      vo_amt_applied,  
	vo_amt_disc_taken,      cross_rate,     	      mc_date_applied,
        amt_applied,      	amt_disc_taken,		      gain_home,    
	gain_oper,      	vo_posted_disc,		      vo_unposted_disc,  
	terms_code, 		vo_precision,			org_id
    )
    SELECT  aptrxapl_vw.vendor_code,  aptrxapl_vw.trx_ctrl_num,   4091,
      aptrxapl_vw.date_aging, aptrxapl_vw.amt_net - aptrxapl_vw.amt_paid_to_date ,    aptrxapl_vw.amt_paid_to_date,
      aptrxapl_vw.date_doc,   aptrxapl_vw.amt_net,     aptrxapl_vw.date_applied, 
	aptrxapl_vw.currency_code,   aptrxapl_vw.rate_type_home,      aptrxapl_vw.rate_home,  
	aptrxapl_vw.rate_oper,    aptrxapl_vw.paid_flag,      0.0,      
	0.0,        	      	0.0,            SIGN(SIGN(@pa_date_applied-aptrxapl_vw.date_applied+0.5)+1)*@pa_date_applied+SIGN(SIGN(aptrxapl_vw.date_applied-@pa_date_applied-0.5)+1)*aptrxapl_vw.date_applied,
	0.0,        		0.0,	      	0.0,            
	0.0,			ISNULL(aptrxapl_vw.amt_discount, 0.0),      0.0,  
	terms_code, (select curr_precision from glcurr_vw where currency_code = aptrxapl_vw.currency_code), org_id

    FROM  aptrxapl_vw, #apvpay3450
    WHERE aptrxapl_vw.vendor_code = #apvpay3450.vendor_code
    AND aptrxapl_vw.trx_ctrl_num = aptrxapl_vw.apply_to_num
    AND aptrxapl_vw.pay_to_code = @pay_to_code      
    

    AND   aptrxapl_vw.paid_flag = 0 
    
    AND aptrxapl_vw.currency_code = @pymt_cur_code
    ORDER BY aptrxapl_vw.vendor_code, aptrxapl_vw.apply_to_num















DECLARE apdiscount_calc CURSOR FOR
	SELECT doc_ctrl_num, date_doc, terms_code FROM #unpaid_vouchers

OPEN apdiscount_calc

FETCH NEXT FROM apdiscount_calc into @dis_trx_ctrl_num, @dis_date, @dis_terms_code

WHILE @@FETCH_STATUS = 0
BEGIN

	EXEC calc_discount_sp @pa_date_applied, @dis_trx_ctrl_num, @dis_terms_code, @prc OUTPUT


	IF @force_disc = 1
	BEGIN
		
		SELECT	@prc = Max(discount_prc)/100 
		FROM	aptermsd 
		WHERE	terms_code = @dis_terms_code 

		UPDATE 	#unpaid_vouchers
		SET 	vo_amt_disc_taken = ROUND(#unpaid_vouchers.amt_net * @prc, #unpaid_vouchers.vo_precision)
		WHERE	#unpaid_vouchers.doc_ctrl_num = @dis_trx_ctrl_num
	END
	ELSE
		UPDATE 	#unpaid_vouchers
		SET 	vo_amt_disc_taken = ROUND(#unpaid_vouchers.amt_net * @prc,#unpaid_vouchers.vo_precision)
		WHERE	#unpaid_vouchers.doc_ctrl_num = @dis_trx_ctrl_num
		AND 	@pa_date_applied <= @dis_date
	
	SELECT @dis_trx_ctrl_num = "", @dis_terms_code = "",@dis_date = 0, @prc =0
		
	FETCH NEXT FROM apdiscount_calc into @dis_trx_ctrl_num, @dis_date, @dis_terms_code

END
  
CLOSE apdiscount_calc
DEALLOCATE apdiscount_calc




  UPDATE  #unpaid_vouchers
  SET curr_precision = gl.curr_precision
  FROM  glcurr_vw gl
  WHERE #unpaid_vouchers.nat_cur_code = gl.currency_code

  



  CREATE INDEX unpaid_Vouchers on #unpaid_vouchers (vendor_code, doc_ctrl_num, trx_type)


CREATE  TABLE   #all_apinppdt   
(
  trx_ctrl_num            varchar(16),
  apply_to_num            varchar(16),
  apply_trx_type  smallint,
  vendor_code           varchar(12),
  vo_amt_applied float,
  vo_amt_disc_taken      float,
  org_id		varchar(30)
)

INSERT #all_apinppdt (   trx_ctrl_num,vendor_code,  apply_to_num, apply_trx_type, vo_amt_applied,
  vo_amt_disc_taken, org_id )
SELECT apinppdt.trx_ctrl_num,apinppdt.vendor_code,  apply_to_num, apply_trx_type, vo_amt_applied,
  vo_amt_disc_taken, apinppdt.org_id
FROM  apinppdt, #apvpay3450, apinppyt
WHERE apinppdt.vendor_code = #apvpay3450.vendor_code  
AND apinppyt.settlement_ctrl_num != @settlement_ctrl_num
AND apinppdt.trx_ctrl_num = apinppyt.trx_ctrl_num

INSERT #all_apinppdt (   trx_ctrl_num,vendor_code,  apply_to_num, apply_trx_type, vo_amt_applied,
  vo_amt_disc_taken, org_id )
SELECT trx_ctrl_num,apinppdt.vendor_code,  apply_to_num, apply_trx_type, vo_amt_applied,
  vo_amt_disc_taken, apinppdt.org_id
FROM  #apinppdt3450 apinppdt, #apvpay3450
WHERE apinppdt.vendor_code = #apvpay3450.vendor_code  
AND apinppdt.trx_ctrl_num != @settlement_ctrl_num  

  




  INSERT  #unposted_payments
  (
    vendor_code,      apply_to_num,
    apply_trx_type,     vo_amt_total,
    vo_amt_disc_taken
  )
  SELECT  apinppdt.vendor_code,   apinppdt.apply_to_num,
    apinppdt.apply_trx_type,  SUM(apinppdt.vo_amt_applied) 
            + SUM(apinppdt.vo_amt_disc_taken),
    SUM(apinppdt.vo_amt_disc_taken)
  FROM  #all_apinppdt apinppdt, #apvpay3450
  WHERE apinppdt.vendor_code = #apvpay3450.vendor_code  
  AND apinppdt.trx_ctrl_num != @settlement_ctrl_num  
  GROUP BY apinppdt.vendor_code, apinppdt.apply_to_num, apinppdt.apply_trx_type

DROP TABLE #all_apinppdt
  



  CREATE INDEX unposted_payments_ind_0 on #unposted_payments (vendor_code, apply_to_num,
    apply_trx_type)
  
  UPDATE  #unpaid_vouchers
  SET vo_unposted_disc = pay.vo_amt_disc_taken
  FROM  #unposted_payments pay
  WHERE pay.apply_to_num = #unpaid_vouchers.doc_ctrl_num
  AND pay.apply_trx_type = #unpaid_vouchers.trx_type



    CREATE TABLE  #aging_info
    (
      vendor_code varchar( 12 ),
      doc_ctrl_num  varchar( 16 ),
      trx_type  smallint,
      date_aging  int,
      date_due  int,
      apply_to_num  varchar( 16 ),     
      apply_trx_type  smallint,                    
      amount    float,
      amt_paid  float
    )
    
    



    INSERT  #aging_info
    (
      vendor_code,    doc_ctrl_num,
      trx_type,   date_aging,
      date_due,   apply_to_num,
      apply_trx_type,   amount,
      amt_paid
    )
    SELECT  age.vendor_code,  age.doc_ctrl_num,  
      age.trx_type,   age.date_aging,
      age.date_due,   age.apply_to_num,
      age.apply_trx_type, age.amount,
      age.amt_paid_to_date      
          FROM  aptrxage age, #unpaid_vouchers
    WHERE age.apply_to_num = #unpaid_vouchers.doc_ctrl_num 
    AND age.trx_type = #unpaid_vouchers.trx_type
    AND ref_id > 0
    AND age.trx_type <= 4091        

    
    

          
    



















    



      
    WHILE( 1 = 1 )
    BEGIN
      



      SET ROWCOUNT 1
            
                SELECT @min_date_due = MIN(#aging_info.date_due)
                FROM  #aging_info, #unposted_payments
      WHERE #aging_info.vendor_code = #unposted_payments.vendor_code
      AND #aging_info.apply_to_num   = #unposted_payments.apply_to_num 
      AND #aging_info.apply_trx_type = #unposted_payments.apply_trx_type 
      AND ((#unposted_payments.vo_amt_total) > (0.0) + 0.0000001)
      AND ((#aging_info.amount - #aging_info.amt_paid) > (0.0) + 0.0000001)
      
      IF( @@rowcount = 0 )
      BEGIN
        SET ROWCOUNT 0
        BREAK
      END

      
      SELECT  @vendor_code = age.vendor_code,
        @apply_to_num = age.doc_ctrl_num,
        @apply_trx_type = age.trx_type,
        @remain_bal = age.amount - age.amt_paid,
        @amount = age.amount, 
        @amt_paid = age.amt_paid,
        @date_aging = age.date_aging,
        @amt_pyt_unposted = pay.vo_amt_total
      FROM  #aging_info age, #unposted_payments pay
      WHERE age.vendor_code = pay.vendor_code
      AND age.apply_to_num   = pay.apply_to_num 
      AND age.apply_trx_type = pay.apply_trx_type 
      AND ((pay.vo_amt_total) > (0.0) + 0.0000001)
      AND ((age.amount - age.amt_paid) > (0.0) + 0.0000001)
      AND age.date_due = @min_date_due
            
              IF( @@rowcount = 0 )
      BEGIN
        SET ROWCOUNT 0
        BREAK
      END

      
      



      SELECT @payoff_vo_flag = SIGN(SIGN(@amt_pyt_unposted-@remain_bal)+1)


      IF @payoff_vo_flag = 1
      BEGIN
        


        UPDATE  #aging_info
        SET amt_paid = amount  
        WHERE vendor_code = @vendor_code
        AND doc_ctrl_num = @apply_to_num
        AND trx_type = @apply_trx_type
        AND date_aging = @date_aging

        
        UPDATE  #unposted_payments
        SET vo_amt_total = vo_amt_total - @remain_bal 
        WHERE vendor_code = @vendor_code
        AND apply_to_num = @apply_to_num
        AND apply_trx_type = @apply_trx_type


        UPDATE  #unpaid_vouchers
        SET amt_paid_to_date = amt_paid_to_date + @remain_bal
        WHERE vendor_code = @vendor_code
        AND doc_ctrl_num = @apply_to_num
        AND trx_type = @apply_trx_type

      END 
      ELSE
      BEGIN 

        


        UPDATE  #aging_info
        SET amt_paid = amt_paid + @amt_pyt_unposted
        WHERE vendor_code = @vendor_code
        AND doc_ctrl_num = @apply_to_num
        AND trx_type = @apply_trx_type
        AND date_aging = @date_aging


        UPDATE  #unposted_payments
        SET vo_amt_total = 0.0
        WHERE vendor_code = @vendor_code
        AND apply_to_num = @apply_to_num
        AND apply_trx_type = @apply_trx_type

        
        UPDATE  #unpaid_vouchers
        SET amt_paid_to_date = amt_paid_to_date + @amt_pyt_unposted
              WHERE vendor_code = @vendor_code
        AND doc_ctrl_num = @apply_to_num
        AND trx_type = @apply_trx_type

      END 
      
      
    END 


    



    DELETE  #unpaid_vouchers
    WHERE ((amt_tot_chg-amt_paid_to_date) <= (0.0) + 0.0000001)



    IF ( @auto_load = 1 )
    BEGIN
      



      
      INSERT  #rates
      (
        from_currency,  to_currency,
        rate_type,    date_applied,
        rate      
      )
      SELECT DISTINCT
        nat_cur_code,   @home_cur_code,
        rate_type_home, mc_date_applied,
        0.0
      FROM  #unpaid_vouchers
      UNION
      SELECT  DISTINCT
        @pymt_cur_code, @home_cur_code,
        @rate_type_home,  mc_date_applied,
        0.0
      FROM  #unpaid_vouchers

      
      EXEC @result = CVO_Control..mcrates_sp  
      
      IF (@result != 0)
        RETURN @result  

        
      


      UPDATE  #unpaid_vouchers
      SET cross_rate = ( SIGN(1 + SIGN(vo.rate))*(vo.rate) + (SIGN(ABS(SIGN(ROUND(vo.rate,6))))/(vo.rate + SIGN(1 - ABS(SIGN(ROUND(vo.rate,6)))))) * SIGN(SIGN(vo.rate) - 1) )/( SIGN(1 + SIGN(pyt.rate))*(pyt.rate) + (SIGN(ABS(SIGN(ROUND(pyt.rate,6))))/(pyt.rate + SIGN(1 - ABS(SIGN(ROUND(pyt.rate,6)))))) * SIGN(SIGN(pyt.rate) - 1) )
      FROM  #unpaid_vouchers ui, #rates vo, #rates pyt
      WHERE ui.nat_cur_code = vo.from_currency
      AND ui.mc_date_applied = vo.date_applied
      AND pyt.from_currency = @pymt_cur_code
      AND pyt.date_applied = vo.date_applied
      AND (ABS((pyt.rate)-(0.0)) > 0.0000001)

      
      TRUNCATE TABLE #rates

	END


    



    IF ( @pay_full = 1 )
    BEGIN
      














      
      INSERT  #rates
      (
        from_currency,  to_currency,
        rate_type,    date_applied,
        rate      
      )
      SELECT DISTINCT
        nat_cur_code,   @home_cur_code,
        rate_type_home, mc_date_applied,
        0.0
      FROM  #unpaid_vouchers
      UNION
      SELECT  DISTINCT
        @pymt_cur_code, @home_cur_code,
        @rate_type_home,  mc_date_applied,
        0.0
      FROM  #unpaid_vouchers

      
      EXEC @result = CVO_Control..mcrates_sp  
      
      IF (@result != 0)
        RETURN @result  

        
      


      UPDATE  #unpaid_vouchers
      SET cross_rate = ( SIGN(1 + SIGN(vo.rate))*(vo.rate) + (SIGN(ABS(SIGN(ROUND(vo.rate,6))))/(vo.rate + SIGN(1 - ABS(SIGN(ROUND(vo.rate,6)))))) * SIGN(SIGN(vo.rate) - 1) )/( SIGN(1 + SIGN(pyt.rate))*(pyt.rate) + (SIGN(ABS(SIGN(ROUND(pyt.rate,6))))/(pyt.rate + SIGN(1 - ABS(SIGN(ROUND(pyt.rate,6)))))) * SIGN(SIGN(pyt.rate) - 1) )
      FROM  #unpaid_vouchers ui, #rates vo, #rates pyt
      WHERE ui.nat_cur_code = vo.from_currency
      AND ui.mc_date_applied = vo.date_applied
      AND pyt.from_currency = @pymt_cur_code
      AND pyt.date_applied = vo.date_applied
      AND (ABS((pyt.rate)-(0.0)) > 0.0000001)

      
      TRUNCATE TABLE #rates		


      




      CREATE TABLE  #aging_info_pay_app
      (
        vendor_code varchar( 12 ),
        doc_ctrl_num  varchar( 16 ),
        trx_type  smallint,
        date_aging  int,
        date_due  int,
        apply_to_num  varchar( 16 ),     
        apply_trx_type  smallint,                    
        amount    float,
        amt_paid  float,
        cross_rate_flag smallint,
        seq_id    numeric identity
      )


      








      INSERT INTO #aging_info_pay_app
      (
        vendor_code,    doc_ctrl_num,   trx_type,
        date_aging,   date_due,   apply_to_num,
        apply_trx_type,   amount,     amt_paid,
        cross_rate_flag
      )
      SELECT  age.vendor_code,  age.doc_ctrl_num, age.trx_type,
        age.date_aging,   age.date_due,   age.apply_to_num,
        age.apply_trx_type, age.amount,   age.amt_paid,
        1
      FROM  #aging_info age, #unpaid_vouchers vo
      WHERE vo.vendor_code = age.vendor_code
      AND vo.doc_ctrl_num = age.apply_to_num
      AND vo.trx_type = age.trx_type
      AND ((amount - amt_paid) > (0.0) + 0.0000001)
      AND ((cross_rate) > (0.0) + 0.0000001)
      ORDER BY date_due

      



      SELECT @age_apply_num = @@rowcount

      



      SELECT  @cur_row = 1

      

  
      WHILE( @age_apply_num >= @cur_row AND ((@amt_payment) > (0.0) + 0.0000001) )
      BEGIN

        


        
        SELECT  @vendor_code  = age.vendor_code,
          @doc_ctrl_num   = age.doc_ctrl_num,
          @trx_type     = age.trx_type,
          @apply_to_num   = age.apply_to_num,
          @apply_trx_type = 4091,
          @amount     = age.amount,
          @amt_paid     = age.amt_paid,
          @date_aging     = age.date_aging,
          @remain_bal     = age.amount - age.amt_paid - vo.vo_amt_disc_taken,
          @cross_rate     = vo.cross_rate,
          @amt_payment_vo  = ROUND(@amt_payment/vo.cross_rate, 
                   vo.curr_precision),
          @discount_flag  = vo.discount_flag,
          @discount_amt   = ROUND(vo.amt_tot_chg*discount_prc/100, 
                   vo.curr_precision) 
                  - vo.vo_posted_disc
                  - vo.vo_unposted_disc,
          @vo_sequence_id  = vo.sequence_id,
          @vo_posted_disc  = vo.vo_posted_disc
        FROM  #unpaid_vouchers vo, #aging_info_pay_app age
        WHERE age.seq_id = @cur_row
        AND vo.vendor_code = age.vendor_code
        AND vo.doc_ctrl_num = age.apply_to_num
        AND vo.trx_type = age.trx_type
                
        



        SELECT @payoff_vo_flag = SIGN(SIGN(@amt_payment_vo-@remain_bal)+1)

        
        IF @payoff_vo_flag = 1
        BEGIN
          


          UPDATE  #aging_info_pay_app
          SET amt_paid = amount   
          WHERE seq_id = @cur_row

          
          SELECT  @amt_payment = @amt_payment 
            - ROUND(@remain_bal*@cross_rate,
              @pymt_curr_precision) 

                
          UPDATE  #unpaid_vouchers
          SET vo_amt_applied = vo_amt_applied + @remain_bal
          WHERE vendor_code = @vendor_code
          AND doc_ctrl_num = @apply_to_num
          AND trx_type = @apply_trx_type

        END 
        ELSE
        BEGIN 

          


          UPDATE  #aging_info_pay_app
          SET amt_paid = amt_paid + @amt_payment_vo
          WHERE seq_id = @cur_row


          SELECT  @amt_payment = 0.0

          
          UPDATE  #unpaid_vouchers
          SET vo_amt_applied = vo_amt_applied + @amt_payment_vo
          WHERE vendor_code = @vendor_code
          AND doc_ctrl_num = @apply_to_num
          AND trx_type = @apply_trx_type

        END 
        
        


        IF ( @discount_flag = 1 )
        BEGIN
        
          IF (((@discount_amt) < (0.0) - 0.0000001))
            SELECT @discount_amt = 0.0

          
          



          SELECT  @payoff_vo_flag = 
              SIGN(SIGN(amt_paid_to_date + vo_amt_applied 
              + @discount_amt - amt_tot_chg)+1),
            @disc_payoff_vo_flag =
              SIGN(SIGN(amt_paid_to_date + @discount_amt
              - amt_tot_chg)+1),
            @balance = amt_tot_chg - amt_paid_to_date
                FROM  #unpaid_vouchers
          WHERE vendor_code = @vendor_code
          AND doc_ctrl_num = @apply_to_num
          AND trx_type = @apply_trx_type

          
          IF ( @disc_payoff_vo_flag = 1 )
          BEGIN
            UPDATE  #aging_info_pay_app
            SET   amt_paid = amount
            WHERE seq_id = @cur_row             
	    AND apply_to_num = @apply_to_num

            
            UPDATE  #unpaid_vouchers
            SET vo_amt_applied = 0.0,
              vo_amt_disc_taken = @balance
            WHERE vendor_code = @vendor_code
            AND doc_ctrl_num = @apply_to_num
            AND trx_type = @apply_trx_type

            
            SELECT  @amt_payment = @amt_payment
                  + ROUND(@balance*@cross_rate,
                    @pymt_curr_precision)

          END 
          ELSE IF ( @payoff_vo_flag = 1 )
          BEGIN
            



            UPDATE  #aging_info_pay_app
            SET amt_paid = amount
            WHERE seq_id = @cur_row             AND apply_to_num = @apply_to_num

            
            SELECT @vo_amt_applied_temp = vo_amt_applied
            FROM  #unpaid_vouchers
            WHERE vendor_code = @vendor_code
            AND doc_ctrl_num = @apply_to_num
            AND trx_type = @apply_trx_type

            
            UPDATE  #unpaid_vouchers
            SET vo_amt_applied = @balance - @discount_amt,
              vo_amt_disc_taken = @discount_amt
            WHERE vendor_code = @vendor_code
            AND doc_ctrl_num = @apply_to_num
            AND trx_type = @apply_trx_type

          
            SELECT  @amt_payment = @amt_payment 
                  + ROUND((@vo_amt_applied_temp
                    -@balance + @discount_amt)
                    *@cross_rate, 
                    @pymt_curr_precision)

          END   

        END 


        SELECT @cur_row = @cur_row + 1

          END 


  
      UPDATE  #unpaid_vouchers
      SET amt_applied = ISNULL(ROUND(vo_amt_applied*cross_rate, 
              @pymt_curr_precision), 0.0),
        amt_disc_taken = ISNULL(ROUND(vo_amt_disc_taken*cross_rate, 
              @pymt_curr_precision), 0.0)
      FROM  glcurr_vw glh
      WHERE glh.currency_code = @home_cur_code
                        


 













      DROP TABLE #aging_info_pay_app

    END 


    


      INSERT  #apinppdt3450 
            ( 
		timestamp,
                trx_ctrl_num ,	trx_type, sequence_id, 
		apply_to_num, apply_trx_type, amt_applied,
                amt_disc_taken, line_desc, void_flag,
                payment_hold_flag, vendor_code, vo_amt_applied,
                vo_amt_disc_taken, gain_home, gain_oper,
                nat_cur_code, cross_rate, org_id
    )
    SELECT  NULL, @settlement_ctrl_num, 4111, convert(smallint, sequence_id),
      	   doc_ctrl_num  , 4091 , amt_applied,     
	   0.0, "", 0, 
	   0, vendor_code, vo_amt_applied, 
           vo_amt_disc_taken, gain_home, gain_oper,
	   nat_cur_code, cross_rate, org_id
    FROM  #unpaid_vouchers

    DROP TABLE  #aging_info

    
  

  DROP TABLE  #rates		
  DROP TABLE  #unpaid_vouchers
  DROP TABLE  #unposted_payments

DELETE #apinppdt3450
WHERE trx_ctrl_num = @settlement_ctrl_num
AND   amt_applied <= 0.0
AND   @pay_full = 1



SELECT SUM(amt_applied),SUM(amt_disc_taken) FROM #apinppdt3450 WHERE trx_ctrl_num = @settlement_ctrl_num
END 
GO
GRANT EXECUTE ON  [dbo].[apstladt_sp] TO [public]
GO
