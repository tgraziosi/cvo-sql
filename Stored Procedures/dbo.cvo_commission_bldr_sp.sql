SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- TAG - write to work table for commission statement Automation
-- exec   cvo_commission_bldr_sp '01/01/2016', '01/31/2016', '70785'
-- select * INTO COMMIS_WORK_BKUP_120116
-- From cvo_commission_bldr_work_tbl

-- UPDATE dbo.cvo_commission_bldr_work_tbl SET fiscal_period = '01/2016' WHERE fiscal_period = '1/2016'

CREATE PROCEDURE [dbo].[cvo_commission_bldr_sp]
    @df DATETIME ,
    @dt DATETIME ,
    @t VARCHAR(1024) = NULL
AS

    BEGIN

   /* for testing
 
        DECLARE @df DATETIME ,
            @dt DATETIME ,
            @t VARCHAR(1024);
        SELECT  @df = '10/1/2016' ,
                @dt = '10/31/2016' ,
                @t = NULL;

  --    EXEC cvo_commission_bldr_r3_sp @t, @df, @dt;
   */

        SET NOCOUNT ON;
   
        DECLARE @fp VARCHAR(10);

        SELECT  @fp = RIGHT('00' + CAST(MONTH(@df) AS VARCHAR(2)), 2) + '/'
                + CAST(YEAR(@df) AS VARCHAR(4));

        IF ( OBJECT_ID('tempdb.dbo.#Terr') IS NOT NULL )
            DROP TABLE #terr;

        CREATE TABLE #terr
            (
              territory VARCHAR(10)
            );

        IF @t IS NULL
            BEGIN
                INSERT  #terr
                        SELECT DISTINCT
                                territory_code
                        FROM    armaster
                        WHERE   territory_code IS NOT NULL;
            END;
        ELSE
            BEGIN
                INSERT  INTO #terr
                        ( territory
                        )
                        SELECT  ListItem
                        FROM    dbo.f_comma_list_to_table(@t);
            END;

        IF ( OBJECT_ID('tempdb.dbo.#r') IS NOT NULL )
            DROP TABLE #r;
        CREATE TABLE #r
            (
      Salesperson VARCHAR(8) ,
      Territory VARCHAR(8) ,
      Cust_code VARCHAR(8) ,
      Ship_to VARCHAR(8) ,
      Name VARCHAR(40) ,
      Order_no INT ,
      Ext INT ,
      Invoice_no VARCHAR(10) ,
      InvoiceDate DATETIME ,
      DateShipped DATETIME ,
      OrderType VARCHAR(10) ,
      Promo_id VARCHAR(20) ,
      Level VARCHAR(30) ,
      type VARCHAR(3) ,
      Net_Sales FLOAT(8) ,
      brand VARCHAR(10) ,
      Amount FLOAT(8) ,
      Comm_pct DECIMAL(5, 2) ,
      Comm_amt FLOAT(8) ,
      Loc VARCHAR(10) ,
      salesperson_name VARCHAR(40) ,
      HireDate VARCHAR(30) ,
      draw_amount DECIMAL(14, 2)
            ); 

        INSERT  #r
                EXEC cvo_commission_bldr_r3_sp @t, @df, @dt;

-- select * From #r
-- DROP TABLE dbo.cvo_commission_bldr_work_tbl

        IF ( OBJECT_ID('cvo.dbo.cvo_commission_bldr_work_tbl') IS NULL )
            BEGIN
                CREATE TABLE dbo.cvo_commission_bldr_work_tbl
                    (
                      Salesperson VARCHAR(10) NOT NULL ,
                      Territory VARCHAR(10) NOT NULL ,
                      Cust_code VARCHAR(8) NOT NULL ,
                      Ship_to VARCHAR(8) NOT NULL ,
                      Name VARCHAR(40) NULL ,
                      Order_no INT NULL ,
                      Ext INT NULL ,
                      Invoice_no VARCHAR(10) NULL ,
                      InvoiceDate INT NOT NULL ,
                      DateShipped INT NOT NULL ,
                      OrderType VARCHAR(10) NULL ,
                      Promo_id VARCHAR(20) NOT NULL ,
                      Level VARCHAR(30) NOT NULL ,
                      type VARCHAR(3) NOT NULL ,
                      Net_Sales FLOAT NULL ,
                      Brand VARCHAR(10) NOT NULL ,
                      Amount FLOAT NULL ,
                      Comm_pct DECIMAL(5, 2) NULL ,
                      Comm_amt FLOAT NULL ,
                      Loc VARCHAR(10) NOT NULL ,
                      salesperson_name VARCHAR(40) NULL ,
                      HireDate VARCHAR(30) NOT NULL ,
                      draw_amount DECIMAL(14, 2) NULL ,
                      invoicedate_dt DATETIME NOT NULL ,
                      dateshipped_dt DATETIME NOT NULL ,
                      fiscal_period VARCHAR(10) NOT NULL ,
                      added_date DATETIME NOT NULL ,
                      added_by NVARCHAR(128) NULL ,
                      id BIGINT NOT NULL
                                PRIMARY KEY
                    )
                ON  [PRIMARY];
            END;


        IF EXISTS ( SELECT  1
                    FROM    dbo.cvo_commission_bldr_work_tbl W
                            JOIN #terr AS t ON t.territory = W.Territory
                    WHERE   invoicedate_dt BETWEEN @df AND @dt )
            DELETE  FROM dbo.cvo_commission_bldr_work_tbl
            WHERE   invoicedate_dt BETWEEN @df AND @dt
                    AND Cust_code <> '999999' -- MANUAL ADJUSTMENTS
                    AND Territory IN ( SELECT DISTINCT
                                                territory
                                       FROM     #terr AS t );

        DECLARE @tbl_rows INT;
        SELECT  @tbl_rows = ISNULL(MAX(id), 0)
        FROM    cvo_commission_bldr_work_tbl;


        INSERT  INTO cvo_commission_bldr_work_tbl
                ( Salesperson ,
                  Territory ,
                  Cust_code ,
                  Ship_to ,
                  Name ,
                  Order_no ,
                  Ext ,
                  Invoice_no ,
                  InvoiceDate ,
                  DateShipped ,
                  OrderType ,
                  Promo_id ,
                  Level ,
                  type ,
                  Net_Sales ,
                  Brand ,
                  Amount ,
                  Comm_pct ,
                  Comm_amt ,
                  Loc ,
                  salesperson_name ,
                  HireDate ,
                  draw_amount ,
                  invoicedate_dt ,
                  dateshipped_dt ,
                  fiscal_period ,
                  added_date ,
                  added_by ,
                  id
                )
                SELECT  Salesperson ,
                        Territory ,
                        Cust_code ,
                        Ship_to ,
                        Name ,
                        Order_no ,
                        Ext ,
                        Invoice_no ,
                        dbo.adm_get_pltdate_f(InvoiceDate) InvoiceDate ,
                        dbo.adm_get_pltdate_f(DateShipped) DateShipped ,
                        OrderType ,
                        Promo_id ,
                        Level ,
                        type ,
                        c.Net_Sales ,
                        c.Brand ,
                        Amount ,
                        comm_pct ,
                        comm_amt ,
                        Loc ,
                        salesperson_name ,
                        HireDate ,
                        draw_amount ,
                        InvoiceDate InvoiceDate_dt,
                        DateShipped DateShipped_dt,
                        fiscal_period = @fp ,
                        added_date = GETDATE() ,
                        added_by = SYSTEM_USER ,
                        id = ROW_NUMBER() OVER ( ORDER BY Invoice_no )
                        + @tbl_rows
                FROM    #r c; 

    END;



GO
