SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                



















CREATE PROC [dbo].[ardunlgen_sp]
    @DunFlag	       int,
    @FromDunnCode      varchar(8),
    @ToDunnCode        varchar(8),
    @CustFlag	       int,
    @FromCustCode      varchar(8),
    @ToCustCode        varchar(8),
    @SalesFlag	       int,
    @FromSalesRepCode  varchar(8),
    @ToSalesRepCode    varchar(8),	
    @CustBal           float
	



AS


        DECLARE
    	    @last_nat_cur_code   varchar(8),	    @last_customer_code  varchar(8),
	    @invoice_num         varchar(16),  	    @nat_cur_code        varchar(8),
	    @customer_code       varchar(8),        @dunning_level       integer,
            @customer_name       varchar(40),       @amt_due             float,
            @amt_extra           float,             @control_id          integer,
            @group_code          varchar(8),        @separation_days     smallint,
            @last_dunning_date   integer,           @lower_sep_day       integer,
            @upper_sep_day       integer,           @temp_dunning_level  integer,
            @inv_amt_due         float,             @inv_amt_paid        float,
            @inv_amt_extra       float,             @inv_date_due        float,
            @max_dunning_level   integer,           @date_last_letter    integer,
            @amt_extra_projected float, 	    @date_generated 	 integer,
	    @salesperson_code	 varchar(8),	    @dunn_ctrl_num	 varchar(16),		
	    @dunning_ctrl_num 	 varchar(16),	    @num 		 int
    
    




    IF @DunFlag = 1
    Begin
       SELECT @FromDunnCode = MIN(group_id) FROM ardngphd
       SELECT @ToDunnCode = MAX(group_id) FROM ardngphd
    End

    IF @CustFlag = 1
    Begin
       SELECT @FromCustCode = MIN(customer_code) FROM ar_dunning_inv_vw
       SELECT @ToCustCode = MAX(customer_code) FROM ar_dunning_inv_vw
    End

    IF @SalesFlag = 1
    Begin
       SELECT @FromSalesRepCode = MIN(salesperson_code) FROM ar_dunning_inv_vw
       SELECT @ToSalesRepCode = MAX(salesperson_code) FROM ar_dunning_inv_vw
    End


    


    EXEC         appdate_sp @date_generated OUTPUT


    BEGIN TRAN ar_Dunning_gen

	

     
    SELECT DISTINCT
           ar_dunning_inv_vw.invoice_num,
           ar_dunning_inv_vw.nat_cur_code,
           ar_dunning_inv_vw.customer_code,
           ar_dunning_inv_vw.date_due,
           ar_dunning_inv_vw.amt_due,
           ar_dunning_inv_vw.amt_paid,
           ar_dunning_inv_vw.amt_extra,
	   ar_dunning_inv_vw.salesperson_code,
           amt_unpaid = (ar_dunning_inv_vw.amt_due + ar_dunning_inv_vw.amt_extra) - ar_dunning_inv_vw.amt_paid
    INTO   #ar_dunn_inv_temp
    FROM   ar_dunning_inv_vw
    WHERE  ( ar_dunning_inv_vw.customer_code 	>= @FromCustCode AND ar_dunning_inv_vw.customer_code <= @ToCustCode ) 
    AND    ar_dunning_inv_vw.salesperson_code 	>= @FromSalesRepCode   
    AND    ar_dunning_inv_vw.salesperson_code 	<= @ToSalesRepCode  
    AND    ar_dunning_inv_vw.date_due 		<= @date_generated
    OR     ar_dunning_inv_vw.salesperson_code  IS NULL

	

     
    SELECT DISTINCT
           customer_code, 
           SUM(amt_unpaid) as total_amt_unpaid, 
           SUM(amt_extra) as total_amt_extra,
           nat_cur_code
    INTO   #ar_dunn_amt_temp
    FROM   #ar_dunn_inv_temp
    GROUP BY customer_code,nat_cur_code



	


     
    SELECT DISTINCT
           #ar_dunn_amt_temp.customer_code, 
           #ar_dunn_amt_temp.total_amt_extra,
           #ar_dunn_amt_temp.total_amt_unpaid, 
           #ar_dunn_amt_temp.nat_cur_code,
		
	   arcust.dunning_group_id	
    INTO   #ar_dunn_cus_temp
    FROM   #ar_dunn_amt_temp,  arcust, artrxage 
    WHERE  #ar_dunn_amt_temp.total_amt_unpaid >= @CustBal   

    AND    ( arcust.dunning_group_id >= @FromDunnCode  AND arcust.dunning_group_id <= @ToDunnCode )
    AND     #ar_dunn_amt_temp.customer_code = arcust.customer_code
    AND     #ar_dunn_amt_temp.nat_cur_code = artrxage.nat_cur_code
    AND     arcust.customer_code = artrxage.customer_code 
 
	

     
    SELECT DISTINCT
           #ar_dunn_inv_temp.invoice_num,
           #ar_dunn_inv_temp.nat_cur_code,
           #ar_dunn_inv_temp.customer_code,
           #ar_dunn_inv_temp.date_due,


           #ar_dunn_inv_temp.amt_extra,
           #ar_dunn_inv_temp.amt_unpaid,
           #ar_dunn_cus_temp.dunning_group_id,
           #ar_dunn_inv_temp.salesperson_code	
    INTO   #ar_dunn_selected
    FROM   #ar_dunn_cus_temp,
           #ar_dunn_inv_temp
    WHERE  #ar_dunn_inv_temp.customer_code = #ar_dunn_cus_temp.customer_code
    AND    #ar_dunn_inv_temp.nat_cur_code = #ar_dunn_cus_temp.nat_cur_code



	


    DROP TABLE #ar_dunn_cus_temp    
    DROP TABLE #ar_dunn_amt_temp


CREATE TABLE #ardncshd (dunn_ctrl_num varchar(16) NULL, 	customer_code varchar(8) NULL, 	nat_cur_code varchar(8) NULL,
				group_id  varchar(8) NULL,	dunning_level smallint NULL,  	date_generate int NULL,
				lower_sep_day int NULL,		upper_sep_day int NULL, 	amt_extra  float NULL,
				amt_due float NULL,		amt_paid float NULL,		amt_extra_projected float NULL,
				chk_hold smallint NULL,		void_fin_chg smallint NULL,	print_fin_only smallint NULL,
				printed_flag	int	)
CREATE TABLE #ardncsdt (dunn_ctrl_num varchar(16) NULL, 	customer_code varchar(8) NULL, 	nat_cur_code varchar(8) NULL,
				date_due int NULL,		invoice_num varchar(16) NULL,	salesperson_code varchar(8) NULL,
				lower_sep_day int NULL,		upper_sep_day int NULL,		amt_extra float NULL,
				amt_due	float NULL,		amt_paid float NULL,		amt_extra_projected float NULL,
				dunning_level int NULL,		group_id varchar(8) 		)

SELECT @invoice_num = ''

SELECT 	@invoice_num = MIN(invoice_num)
FROM 	#ar_dunn_selected
WHERE 	invoice_num > @invoice_num

WHILE @invoice_num IS NOT NULL
BEGIN
        SELECT	@nat_cur_code 	= nat_cur_code,
	    	@customer_code 	= customer_code, 
            	@amt_extra 	= amt_extra,
	    	@amt_due 	= amt_unpaid,
            	@group_code 	= dunning_group_id,
            	@inv_date_due 	= date_due,
		@salesperson_code = salesperson_code
        FROM    #ar_dunn_selected 
        WHERE   invoice_num  = @invoice_num 
	
                     
        SELECT    @customer_name = address_name
        FROM      armaster
        WHERE     customer_code = @customer_code    

        SELECT @dunning_level = 0  







	SELECT 	@dunning_level 		= MAX(dunning_level),
		@dunn_ctrl_num		= MAX(dunn_ctrl_num)
	FROM 	ardncsdt
	WHERE	invoice_num		= @invoice_num

	SELECT @last_dunning_date 	= MAX(date_generate)
        FROM   ardncshd
        WHERE  dunn_ctrl_num		 = @dunn_ctrl_num 


        IF @dunning_level  IS NULL
        BEGIN
             SELECT @dunning_level = 0 
        END     

	IF @last_dunning_date IS NULL		
	BEGIN
		SELECT @last_dunning_date = @date_generated
	END
  
	SELECT @lower_sep_day  = 0
  


        IF EXISTS (	SELECT dunning_level 
			FROM ardngpdt 
			WHERE dunning_level > @dunning_level
			AND group_id = @group_code
		)
          BEGIN 

        




	     IF @date_last_letter  = @last_dunning_date
	             SELECT @dunning_level = @dunning_level + 1 

		SELECT @dunning_level = MIN(dunning_level) 
		from ardngpdt
		WHERE dunning_level > @dunning_level
			AND group_id = @group_code



              SELECT   @lower_sep_day = sum(separation_days )
              FROM     ardngpdt  
              WHERE    dunning_level < @dunning_level
              AND      group_id = @group_code
              GROUP BY  group_id 

              SELECT   @upper_sep_day = sum(separation_days )
              FROM    ardngpdt  
              WHERE   dunning_level <= @dunning_level
              AND     group_id = @group_code
              GROUP BY   group_id 

              SELECT @separation_days = separation_days
              FROM  ardngpdt  
              WHERE dunning_level = @dunning_level
              AND   group_id = @group_code

		IF (@dunning_level = 1) 
		BEGIN
                	IF (@date_generated - @inv_date_due < @separation_days)
                   	BEGIN  
                     		SELECT @dunning_level = 0
			END 
		END
		ELSE
		BEGIN

			IF ((@date_generated - @last_dunning_date < @separation_days) OR
	                     ( @date_last_letter < (SELECT group_sep_day FROM ardngphd WHERE group_id = @group_code  )))   
			BEGIN  
				SELECT @dunning_level = 0
			END 
		END


          END 
        ELSE
          BEGIN
             SELECT @dunning_level = 0

          END  

        SELECT  @inv_amt_due = amt_due,
                @inv_amt_paid = amt_paid,
                @inv_amt_extra = amt_extra
        FROM    ar_dunning_inv_vw 
        WHERE   invoice_num = @invoice_num 

        SELECT @amt_extra_projected = 0

        SELECT  @amt_extra_projected = artrx.amt_net * (arfinchg.fin_chg_prc/100) + arfinchg.late_chg_amt
        FROM    arfinchg  CROSS JOIN  artrx
        WHERE   arfinchg.fin_chg_code = ( SELECT fin_chg_code 
                                    FROM         ardngpdt 
                                    WHERE        dunning_level = @dunning_level
                                    AND          group_id = @group_code    )   
        AND    artrx.doc_ctrl_num = @invoice_num 
        AND    (artrx.amt_net * (arfinchg.fin_chg_prc/100)) >= arfinchg.min_fin_chg
	 
	  


          
 

      SELECT      @amt_extra_projected = arfinchg.min_fin_chg + arfinchg.late_chg_amt
      FROM        arfinchg CROSS JOIN artrx
      WHERE       arfinchg.fin_chg_code = ( SELECT 	fin_chg_code 
		                                  FROM 	ardngpdt 
		                                  WHERE dunning_level = @dunning_level
		                                  AND	group_id = @group_code   )  
      AND        artrx.doc_ctrl_num = @invoice_num 
      AND        (artrx.amt_net * (arfinchg.fin_chg_prc/100)) < arfinchg.min_fin_chg
   

      IF @amt_extra_projected IS NULL 
	SELECT @amt_extra_projected = 0

       INSERT	#ardncsdt ( customer_code, 	nat_cur_code, 	date_due, 	invoice_num, 
			salesperson_code, 	lower_sep_day,  upper_sep_day, 	amt_extra, 	amt_due,
			amt_paid, 		amt_extra_projected ,	dunning_level, group_id )
       VALUES (		@customer_code,		@nat_cur_code,	@inv_date_due,	@invoice_num,
			@salesperson_code, 	@lower_sep_day, @upper_sep_day, @inv_amt_extra, @inv_amt_due,
			@inv_amt_paid,		@amt_extra_projected, 	@dunning_level, @group_code )
   


	SELECT 	@invoice_num = MIN(invoice_num)
	FROM 	#ar_dunn_selected
	WHERE 	invoice_num > @invoice_num

    END 










DELETE #ardncsdt 
WHERE dunning_level = 0





DELETE #ardncsdt 
FROM	ardncsdt a, #ardncsdt b
WHERE 	a.customer_code	= b.customer_code
AND	a.invoice_num 	= b.invoice_num
AND	a.dunning_level = b.dunning_level


SELECT @customer_code =  ''

SELECT @customer_code = MIN(customer_code)
FROM #ardncsdt
WHERE customer_code > @customer_code
	
WHILE @customer_code IS NOT NULL
BEGIN

	SELECT 	@nat_cur_code = ''
	SELECT 	@nat_cur_code = MIN(nat_cur_code)
	FROM	#ardncsdt
	WHERE	customer_code = @customer_code
	AND	nat_cur_code > @nat_cur_code

	WHILE @nat_cur_code IS NOT NULL
	BEGIN

		


		EXEC ARGetNextControl_SP 2120, @dunning_ctrl_num OUTPUT, @num OUTPUT

		



		UPDATE #ardncsdt
		SET	dunn_ctrl_num 	= @dunning_ctrl_num
		WHERE 	customer_code 	= @customer_code
		AND	nat_cur_code	= @nat_cur_code

		
		SELECT 	@nat_cur_code = MIN(nat_cur_code)
		FROM	#ardncsdt
		WHERE	customer_code = @customer_code
		AND	nat_cur_code > @nat_cur_code


	END	

SELECT @customer_code = MIN(customer_code)
FROM #ardncsdt
WHERE customer_code > @customer_code


END 






	
INSERT #ardncshd (	dunn_ctrl_num,		customer_code,	 	nat_cur_code,	 	group_id, 
			date_generate, 		lower_sep_day,		upper_sep_day,	 	amt_extra,	 
			amt_due,	 	amt_paid,	 	amt_extra_projected,	chk_hold,	
			void_fin_chg,	 	print_fin_only ,	printed_flag	)
SELECT 			dunn_ctrl_num, 		MAX(customer_code), 	MAX(nat_cur_code),	MAX(group_id),
			@date_generated,	MAX(lower_sep_day),	MAX(upper_sep_day),	SUM(amt_extra),
			SUM(amt_due),		SUM(amt_paid),		SUM(amt_extra_projected), 0,
			0,			1,			0
FROM #ardncsdt
GROUP BY dunn_ctrl_num









  





































INSERT ardncsdt	(	dunn_ctrl_num,customer_code, 		nat_cur_code, 		date_due, 		invoice_num, 
			salesperson_code, 	lower_sep_day,  	upper_sep_day, 		amt_extra, 	
			amt_due,		amt_paid, 		amt_extra_projected ,	dunning_level)
SELECT 			dunn_ctrl_num,customer_code, 		nat_cur_code, 		date_due, 		invoice_num, 
			salesperson_code, 	lower_sep_day,  	upper_sep_day, 		amt_extra, 	
			amt_due,		amt_paid, 		amt_extra_projected ,	dunning_level
FROM #ardncsdt


INSERT ardncshd (	dunn_ctrl_num,		customer_code,	 	nat_cur_code,	 	group_id, 
			date_generate, 		lower_sep_day,		upper_sep_day,	 	amt_extra,	 
			amt_due,	 	amt_paid,	 	amt_extra_projected,	chk_hold,	
			void_fin_chg,	 	print_fin_only,		printed_flag)
SELECT 			dunn_ctrl_num,		customer_code,	 	nat_cur_code,	 	group_id, 
			date_generate, 		lower_sep_day,		upper_sep_day,	 	amt_extra,	 
			amt_due,	 	amt_paid,	 	amt_extra_projected,	chk_hold,	
			void_fin_chg,	 	print_fin_only,		printed_flag 
FROM #ardncshd





DROP TABLE #ardncshd
DROP TABLE #ardncsdt





COMMIT TRAN

SELECT 0

GO
GRANT EXECUTE ON  [dbo].[ardunlgen_sp] TO [public]
GO
