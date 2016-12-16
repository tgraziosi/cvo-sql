SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[cvo_promotions_tracker_tyly_flex_sp]
    @sdatety DATETIME ,
    @edatety DATETIME ,
	@sdately DATETIME ,
    @edately DATETIME ,
    @Terr VARCHAR(1000) ,
    @Promo VARCHAR(5000) ,
    @PromoLevel VARCHAR(5000)
AS
    BEGIN

-- exec cvo_promotions_tracker_tyly_flex_sp '11/1/2016','12/14/2016', '11/1/2015','10/13/2015',  '40454', 'sunps', 'op'

        SET NOCOUNT ON;
        SET ANSI_WARNINGS OFF;


    --    DECLARE @sdately DATETIME ,
				--@edately DATETIME;

		SET  @edatety   = DATEADD(ms,-3, DATEADD(DAY,1,@edatety))
  --      set  @sdately = DATEADD(YEAR, -1, @sdate)
		--SET  @edately = DATEADD(ms, -1, @sdate)

		-- SELECT @sdatety, @edatety, @sdately, @edately


        CREATE TABLE #temptable
            (
              order_no VARCHAR(10) ,
              ext VARCHAR(3) ,
              cust_code VARCHAR(10) ,
              ship_to VARCHAR(10) ,
              ship_to_name VARCHAR(40) ,
              location VARCHAR(10) ,
              cust_po VARCHAR(20) ,
              routing VARCHAR(20) ,
              fob VARCHAR(10) ,
              attention VARCHAR(40) ,
              tax_id VARCHAR(10) ,
              terms VARCHAR(10) ,
              curr_key VARCHAR(10) ,
              salesperson VARCHAR(8) ,
              Territory VARCHAR(8) ,
              region VARCHAR(3) ,
              total_amt_order DECIMAL(20, 8) ,
              total_discount DECIMAL(20, 8) ,
              total_tax DECIMAL(20, 8) ,
              freight DECIMAL(20, 8) ,
              qty_ordered DECIMAL(38, 8) ,
              qty_shipped DECIMAL(38, 8) ,
              total_invoice DECIMAL(23, 8) ,
              invoice_no VARCHAR(10) ,
              doc_ctrl_num VARCHAR(16) ,
              date_invoice DATETIME ,
              date_entered DATETIME ,
              date_sch_ship DATETIME ,
              date_shipped DATETIME ,
              status VARCHAR(1) ,
              status_desc VARCHAR(13) ,
              who_entered VARCHAR(20) ,
              shipped_flag VARCHAR(3) ,
              hold_reason VARCHAR(10) ,
              orig_no INT ,
              orig_ext INT ,
              promo_id VARCHAR(255) ,
              promo_level VARCHAR(255) ,
              order_type VARCHAR(10) ,
              FramesOrdered DECIMAL(38, 8) ,
              FramesShipped DECIMAL(38, 8) ,
              back_ord_flag CHAR(1) ,
              Cust_type VARCHAR(40) ,
              return_date DATETIME ,
              reason VARCHAR(40) ,
              return_amt DECIMAL(20, 8) ,
              return_qty INT ,
              source VARCHAR(1) ,
              Qual_order INT ,
              override_reason VARCHAR(2000) ,
              UC INT ,
              wk_Begindate VARCHAR(30) ,
              wk_EndDate VARCHAR(30),
			  yy CHAR(2) null
            );

        INSERT  INTO #temptable	(order_no,ext,cust_code,ship_to,ship_to_name,location,cust_po,routing,fob,attention,tax_id,terms,curr_key,salesperson,Territory,
		region,total_amt_order,total_discount,total_tax,freight,qty_ordered,qty_shipped,total_invoice,invoice_no,
		doc_ctrl_num,date_invoice,date_entered,date_sch_ship,date_shipped,status,status_desc,who_entered,shipped_flag,hold_reason,orig_no,orig_ext,
		promo_id,promo_level,order_type,FramesOrdered,FramesShipped,back_ord_flag,Cust_type,return_date,reason,return_amt,return_qty,source,Qual_order,
		override_reason,UC,wk_Begindate,wk_EndDate)
                EXEC cvo_promotions_tracker_terr_sp @sdatety, @edatety, @Terr,
                    @Promo, @PromoLevel;

--                 EXEC cvo_promotions_tracker_terr_sp '1/1/2016','8/22/2016', '50505','aspire','1,3,launch,new,vew'
--				   EXEC cvo_promotions_tracker_tyly_sp '1/1/2016','8/22/2016', '50505','aspire','1,3,launch,new,vew'

		--SELECT * FROM #temptable AS t

		UPDATE #temptable SET yy = 'TY' -- DATEPART(YEAR, @sdate)

		
        INSERT  INTO #temptable (order_no,ext,cust_code,ship_to,ship_to_name,location,cust_po,routing,fob,attention,tax_id,terms,curr_key,salesperson,Territory,
		region,total_amt_order,total_discount,total_tax,freight,qty_ordered,qty_shipped,total_invoice,invoice_no,
		doc_ctrl_num,date_invoice,date_entered,date_sch_ship,date_shipped,status,status_desc,who_entered,shipped_flag,hold_reason,orig_no,orig_ext,
		promo_id,promo_level,order_type,FramesOrdered,FramesShipped,back_ord_flag,Cust_type,return_date,reason,return_amt,return_qty,source,Qual_order,
		override_reason,UC,wk_Begindate,wk_EndDate)
                    EXEC cvo_promotions_tracker_terr_sp @sdately, @edately, @Terr,
                    @Promo, @PromoLevel;

		UPDATE #temptable SET yy = 'LY' WHERE yy IS NULL -- DATEPART(YEAR, @sdately) WHERE yy IS NULL	

        SELECT  t.salesperson ,
                t.Territory ,
                t.region ,
                t.promo_id ,
                t.promo_level ,
                SUM(t.FramesOrdered*t.Qual_order) FramesOrdered ,
                SUM(t.FramesShipped*t.Qual_order) FramesShipped ,
                SUM(t.Qual_order) Qual_order ,
                sum(t.order_count) Tot_order ,
                SUM(t.UC) UC ,
                t.yy
        FROM    ( SELECT    slp.salesperson_code salesperson ,
                            Territory ,
                            region ,
                            promo_id ,
                            promo_level ,
                            FramesOrdered ,
                            FramesShipped ,
                            Qual_order ,
                            CASE WHEN source = 'E' THEN 1 ELSE 0 END AS order_count ,
                            UC ,
                            yy
                  FROM      #temptable
				  JOIN arsalesp slp ON slp.salesperson_code = #temptable.salesperson
                ) AS t
        GROUP BY t.salesperson ,
                t.Territory ,
                t.region ,
                t.promo_id ,
                t.promo_level ,
                t.yy;

		-- SELECT * FROM #temptable AS t WHERE t.Territory IN ('40454','70780','30338')
	   
    END;









GO
