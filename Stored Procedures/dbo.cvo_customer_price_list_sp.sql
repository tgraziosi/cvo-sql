SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
 exec cvo_customer_price_list_sp '040045','','bcbg,ch,izod,izx,cvo','bcbg-retai','03/23/2017','%','FRAME,SUN'
*/

CREATE PROCEDURE [dbo].[cvo_customer_price_list_sp]
    (
      @customer_code VARCHAR(8) ,
      @ship_to_code VARCHAR(8) ,
      @collection VARCHAR(1000) ,
      @location VARCHAR(10) ,
      @asofdate DATETIME ,
      @part_no VARCHAR(30) ,
      @type_code VARCHAR(1000)
    )
AS
    BEGIN

        SET NOCOUNT ON;

        IF ( OBJECT_ID('tempdb.dbo.#t') IS NOT NULL )
            DROP TABLE #t;

        CREATE TABLE #T
            (
              ID INT IDENTITY ,
              customer_code VARCHAR(8) ,
              ship_to_code VARCHAR(8) ,
              address_name VARCHAR(40) ,
              collection VARCHAR(30) ,
              style VARCHAR(20) ,
              channel VARCHAR(20) ,
              part_no VARCHAR(30) ,
              price_a FLOAT ,
              comments VARCHAR(60) ,
              price FLOAT ,
              promo_rate FLOAT ,
              min_qty FLOAT ,
              customer_key VARCHAR(10) ,
              ship_to_no VARCHAR(10) ,
              ilevel INT ,
              item VARCHAR(30) ,
              startdate DATETIME ,
              end_date DATETIME ,
              type VARCHAR(3) ,
              qloop INT ,
              rate FLOAT ,
              curr_key VARCHAR(3) ,
              promo_dt DATETIME ,
              curr_ind INT ,
              in_part VARCHAR(30) ,
              in_loc VARCHAR(10) ,
              pom_date DATETIME ,
              release_date DATETIME ,
              type_code VARCHAR(10) ,
              gender VARCHAR(40)
            );


-- set up tables for multi-value parameters

        CREATE TABLE #TYPE_CODE ( TYPE_CODE VARCHAR(10) );

        INSERT  INTO #TYPE_CODE
                ( TYPE_CODE
                )
                SELECT  ListItem
                FROM    dbo.f_comma_list_to_table(@type_code);

        CREATE TABLE #collection
            (
              collection VARCHAR(30)
            );

        INSERT  INTO #collection
                ( collection
                )
                SELECT  ListItem
                FROM    dbo.f_comma_list_to_table(@collection);

--select * From #type_code

        INSERT  INTO #T
                ( customer_code ,
                  ship_to_code ,
                  address_name ,
                  collection ,
                  style ,
                  channel ,
                  part_no ,
                  price_a ,
                  pom_date ,
                  release_date ,
                  type_code ,
                  gender
                )
                SELECT  a.customer_code ,
                        a.ship_to_code ,
                        c.customer_name ,
                        i.category ,
                        i.style ,
                        i.channel ,
                        i.part_no ,
                        i.price_a ,
                        i.pom_date ,
                        i.release_date ,
                        i.type_code ,
                        i.gender
                FROM    armaster a
                        INNER JOIN arcust c ON c.customer_code = @customer_code
                        CROSS JOIN ( SELECT MIN(ii.part_no) part_no ,
                                            ii.category ,
                                            ia.field_2 style ,
                                            ii.type_code ,
                                            ia.field_28 pom_date ,
                                            ia.field_26 release_date ,
                                            p.price_a ,
                                            CASE WHEN ia.field_32 IN (
                                                      'retail', 'hvc' )
                                                 THEN ia.field_32
                                                 ELSE ''
                                            END AS channel ,
                                            ( SELECT TOP 1
                                                        description
                                              FROM      CVO_Gender
                                              WHERE     kys = ia.category_2
                                            ) gender
                                     FROM   inv_master ii
                                            INNER JOIN inv_master_add ia ON ii.part_no = ia.part_no
                                            INNER JOIN part_price p ON ii.part_no = p.part_no
                                            INNER JOIN #TYPE_CODE t ON t.TYPE_CODE = ii.type_code
                                            INNER JOIN #collection c ON c.collection = ii.category
                                     WHERE  1 = 1
                                            AND ii.void = 'N'
                                            AND @asofdate <= ISNULL(ia.field_28,
                                                              @asofdate)
    -- and ii.category like @collection
    -- and ii.type_code like @type_code
                                            AND ii.part_no LIKE @part_no
                                     GROUP BY ii.category ,
                                            ia.field_2 ,
                                            ii.type_code ,
                                            ia.field_28 ,
                                            ia.field_26 ,
                                            p.price_a ,
                                            ia.field_32 ,
                                            ia.category_2
                                   ) AS i
                WHERE   1 = 1
                        AND a.customer_code LIKE @customer_code
                        AND a.ship_to_code LIKE @ship_to_code;


--

        DECLARE @last_id INT ,
            @max_id INT;

        IF ( OBJECT_ID('tempdb.dbo.#tt') IS NOT NULL )
            DROP TABLE #tt;

        CREATE TABLE #tt
            (
              id INT IDENTITY ,
              comments VARCHAR(60) ,
              price FLOAT ,
              promo_rate FLOAT ,
              min_qty FLOAT ,
              customer_key VARCHAR(10) ,
              ship_to_no VARCHAR(10) ,
              ilevel INT ,
              item VARCHAR(30) ,
              startdate DATETIME ,
              end_date DATETIME ,
              type VARCHAR(3) ,
              qloop INT ,
              rate FLOAT ,
              curr_key VARCHAR(3) ,
              promo_dt DATETIME ,
              curr_ind INT ,
              in_part VARCHAR(30) ,
              in_loc VARCHAR(10) ,
              curr_mask VARCHAR(255)
            );
/*
 EXEC dbo.fs_show_price @cust = '011111',@shipto = '',@clevel = '1',@pn = 'BCGCOLINK5316',@loc = '001',@curr_key = 'USD',@curr_factor = 1,@svc_agr = 'N',@in_qty = 1,@conv_factor = 1,@mask = '''$ ''###,###,###,###.00;(''$ ''###,###,###,###.00)'  
*/ 

        SELECT  @last_id = MIN(ID)
        FROM    #T;

        SELECT  @customer_code = customer_code ,
                @ship_to_code = ship_to_code ,
                @part_no = part_no
        FROM    #T
        WHERE   ID = @last_id;
       

        WHILE @last_id IS NOT NULL
            BEGIN   
/*
 EXEC dbo.fs_show_price @cust = '011111',@shipto = '',@clevel = '1',@pn = 'BCGCOLINK5316',@loc = '001',@curr_key = 'USD',@curr_factor = 1,@svc_agr = 'N',@in_qty = 1,@conv_factor = 1,@mask = '''$ ''###,###,###,###.00;(''$ ''###,###,###,###.00)'  
*/
                INSERT  INTO #tt
                        ( comments ,
                          price ,
                          promo_rate ,
                          min_qty ,
                          customer_key ,
                          ship_to_no ,
                          ilevel ,
                          item ,
                          startdate ,
                          end_date ,
                          type ,
                          qloop ,
                          rate ,
                          curr_key ,
                          promo_dt ,
                          curr_ind ,
                          in_part ,
                          in_loc ,
                          curr_mask
                        )
                        EXEC dbo.fs_show_price @cust = @customer_code,
                            @shipto = @ship_to_code, @clevel = '1',
                            @pn = @part_no, @loc = @location,
                            @curr_key = 'USD', @curr_factor = 1,
                            @svc_agr = 'N', @in_qty = 1, @conv_factor = 1,
                            @mask = '''$ ''###,###,###,###.00;(''$ ''###,###,###,###.00)';  
    
    -- select * from #tt
                DELETE  FROM #tt
                WHERE   qloop = 99;
    
                SELECT  @max_id = MAX(id)
                FROM    #tt;
    
                UPDATE  #T
                SET     #T.comments = #tt.comments ,
                        #T.price = #tt.price ,
                        #T.promo_rate = #tt.promo_rate ,
                        #T.min_qty = #tt.min_qty ,
                        #T.customer_key = #tt.customer_key ,
                        #T.ship_to_no = #tt.ship_to_no ,
                        #T.ilevel = #tt.ilevel ,
                        #T.item = #tt.item ,
                        #T.startdate = #tt.startdate ,
                        #T.end_date = #tt.end_date ,
                        #T.type = #tt.type ,
                        #T.rate = #tt.rate ,
                        #T.curr_key = #tt.curr_key ,
                        #T.promo_dt = #tt.promo_dt ,
                        #T.curr_ind = #tt.curr_ind ,
                        #T.in_part = #tt.in_part ,
                        #T.in_loc = #tt.in_loc
                FROM    #tt
                        CROSS JOIN #T
                WHERE   #T.ID = @last_id
                        AND #tt.id = @max_id;
    
                TRUNCATE TABLE #tt;
    
                SELECT  @last_id = MIN(ID)
                FROM    #T
                WHERE   ID > @last_id;
       
                SELECT  @customer_code = customer_code ,
                        @ship_to_code = ship_to_code ,
                        @part_no = part_no
                FROM    #T
                WHERE   ID = @last_id;
    
            END;

        SELECT  ID ,
                customer_code ,
                ship_to_code ,
                address_name ,
                collection ,
                style ,
                channel ,
                part_no ,
                price_a ,
                comments ,
                price ,
                promo_rate ,
                min_qty ,
                customer_key ,
                ship_to_no ,
                ilevel ,
                item ,
                startdate ,
                end_date ,
                type ,
                qloop ,
                rate ,
                curr_key ,
                promo_dt ,
                curr_ind ,
                in_part ,
                in_loc ,
                pom_date ,
                release_date ,
                type_code ,
                gender ,
                c.timestamp ,
                c.kys ,
                c.description ,
                c.who_entered ,
                c.date_entered ,
                c.void ,
                c.void_who ,
                c.void_date ,
                c.cycle_type ,
                c.description brand_desc
        FROM    #T
                INNER JOIN category c ON c.kys = #T.collection;

    END;

GO
GRANT EXECUTE ON  [dbo].[cvo_customer_price_list_sp] TO [public]
GO
