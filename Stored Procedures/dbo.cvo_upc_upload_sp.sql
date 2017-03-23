SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_upc_upload_sp]
    @loc VARCHAR(10) = NULL ,
    @bin VARCHAR(20) = NULL ,
    @direction INT = 1 ,
    @reason VARCHAR(10) = 'ADHOC' ,
    @debug INT = 0
AS

	SET NOCOUNT ON ;

    BEGIN

/*

TRUNCATE TABLE CVO_UPC_UPLOAD

INSERT dbo.cvo_upc_upload
        ( upc_code, qty )
SELECT part_no, SUM(qty) qty
 FROM dbo.lot_bin_stock AS lbs
WHERE location = '775-TATE'
GROUP BY lbs.part_no

EXEC CVO_UPC_UPLOAD_SP 'tine','tine', -2, 'WRITEOFF', 0

EXEC CVO_UPC_UPLOAD_SP '001','RR REFURB', 1, 'WRITEOFF', 0


SELECT * fROM CVO_UPC_UPLOAD

insert cvo_upc_upload
values ('026851012253',1)

select * From tdc_bin_master where location = '012-MIDO'

SELECT * fROM ISSUES (NOLOCK) WHERE ISSUE_NO >=4641583


*/
        DECLARE @row_id INT ,
            @last_row_id INT ,
            @location VARCHAR(10) ,
            @part_no VARCHAR(30) ,
            @bin_no VARCHAR(20) ,
            @qty_to_adj DECIMAL(20, 8) ,
            @reason_code VARCHAR(10) ,
            @code VARCHAR(10) ,
            @bin_qty DECIMAL(20, 8);

        SELECT  @reason_code = CASE WHEN @reason = 'WRITEOFF' THEN 'WRITE-OFF'
                                    ELSE 'ADJ-ADHOC'
                               END;
        SELECT  @code = CASE WHEN @reason = 'WRITEOFF' THEN @reason
                             ELSE 'ADHOC'
                        END;

	-- set up temp tables

        IF ( SELECT OBJECT_ID('tempdb..#adm_inv_adj')
           ) IS NOT NULL
            BEGIN   
                DROP TABLE #adm_inv_adj;  
            END;

        CREATE TABLE #adm_inv_adj
            (
              adj_no INT NULL ,
              loc VARCHAR(10) NOT NULL ,
              part_no VARCHAR(30) NOT NULL ,
              bin_no VARCHAR(12) NULL ,
              lot_ser VARCHAR(25) NULL ,
              date_exp DATETIME NULL ,
              qty DECIMAL(20, 8) NOT NULL ,
              direction INT NOT NULL ,
              who_entered VARCHAR(50) NOT NULL ,
              reason_code VARCHAR(10) NULL ,
              code VARCHAR(8) NOT NULL ,
              cost_flag CHAR(1) NULL ,
              avg_cost DECIMAL(20, 8) NULL ,
              direct_dolrs DECIMAL(20, 8) NULL ,
              ovhd_dolrs DECIMAL(20, 8) NULL ,
              util_dolrs DECIMAL(20, 8) NULL ,
              err_msg VARCHAR(255) NULL ,
              row_id INT IDENTITY
                         NOT NULL
            );

	
        IF ( SELECT OBJECT_ID('tempdb..#adm_inv_adj_log')
           ) IS NOT NULL
            BEGIN   
                DROP TABLE #adm_inv_adj_log;
            END;

        CREATE TABLE #adm_inv_adj_log
            (
              adj_no INT NULL ,
              loc VARCHAR(10) NOT NULL ,
              part_no VARCHAR(30) NOT NULL ,
              bin_no VARCHAR(12) NULL ,
              lot_ser VARCHAR(25) NULL ,
              date_exp DATETIME NULL ,
              qty DECIMAL(20, 8) NOT NULL ,
              direction INT NOT NULL ,
              who_entered VARCHAR(50) NOT NULL ,
              reason_code VARCHAR(10) NULL ,
              code VARCHAR(8) NOT NULL ,
              cost_flag CHAR(1) NULL ,
              avg_cost DECIMAL(20, 8) NULL ,
              direct_dolrs DECIMAL(20, 8) NULL ,
              ovhd_dolrs DECIMAL(20, 8) NULL ,
              util_dolrs DECIMAL(20, 8) NULL ,
              err_msg VARCHAR(255) NULL ,
              row_id INT NOT NULL
            );


        IF ( OBJECT_ID('tempdb..#temp_who') IS NULL )
            BEGIN  
                CREATE TABLE #temp_who
                    (
                      who VARCHAR(50) ,
                      login_id VARCHAR(50)
                    );  
            END;  

        IF ( SELECT OBJECT_ID('tempdb..#cvo_inv_adj')
           ) IS NOT NULL
            BEGIN   
                DROP TABLE #cvo_inv_adj;  
            END;

        CREATE TABLE #cvo_inv_adj
            (
              row_id INT IDENTITY(1, 1) ,
              location VARCHAR(10) ,
              upc_code VARCHAR(30) ,
              part_no VARCHAR(30) ,
              bin_no VARCHAR(20) ,
              qty DECIMAL(20, 8)
            );

        INSERT  #cvo_inv_adj
                ( location ,
                  upc_code ,
                  part_no ,
                  bin_no ,
                  qty
                )
	-- SELECT	location, upc_code, '', bin_no, reason_code, qty
                SELECT  @loc ,
                        upc_code ,
                        '' ,
                        @bin ,
                        SUM(ISNULL(qty, 1)) QTY
                FROM    dbo.cvo_upc_upload
                GROUP BY upc_code;
	--SELECT * FROM dbo.cvo_upc_upload
	-- validate data

        IF ( @@ROWCOUNT = 0 )
            BEGIN
			INSERT  INTO #adm_inv_adj_log
                        ( loc ,
                          part_no ,
                          qty ,
                          direction ,
                          who_entered ,
                          code ,
                          err_msg ,
                          row_id
                        )
                        VALUES(
                                @loc ,
                                '',
                                0 ,
                                @direction ,
                                'Error' ,
                                @code ,
                                'Nothing to process' ,
                                -1
								);
                -- RETURN;
            END;
	
        IF NOT EXISTS ( SELECT  1
                        FROM    tdc_bin_master
                        WHERE   location = @loc
                                AND bin_no = @bin )
            BEGIN 
						INSERT  INTO #adm_inv_adj_log
                        ( loc ,
						  bin_no,
                          part_no ,
                          qty ,
                          direction ,
                          who_entered ,
                          code ,
                          err_msg ,
                          row_id
                        )
                        VALUES(
                                @loc ,
								@bin,
                                '',
                                0 ,
                                @direction ,
                                'Error' ,
                                @code ,
                                'Invalid Location or Bin' ,
                                -1
								);
                --SELECT  'Invalid Location or Bin';
                --RETURN;
            END;

        IF @direction NOT IN ( 1, -1 )
            BEGIN
						INSERT  INTO #adm_inv_adj_log
                        ( loc ,
						  bin_no,
                          part_no ,
                          qty ,
                          direction ,
                          who_entered ,
                          code ,
                          err_msg ,
                          row_id
                        )
                        VALUES(
                                @loc ,
								@bin,
                                '',
                                0 ,
                                @direction ,
                                'Error' ,
                                @code ,
                                'Invalid Direction.  Must be 1 or -1' ,
                                -1
								);
                --SELECT  'Invalid Direction.  Must be 1 or -1';
                --RETURN;
            END;

        UPDATE  A
        SET     part_no = A.upc_code
        FROM    #cvo_inv_adj A
        WHERE   EXISTS ( SELECT 1
                         FROM   inv_master (NOLOCK)
                         WHERE  part_no = A.upc_code );

        UPDATE  a
        SET     part_no = b.part_no
        FROM    #cvo_inv_adj a
                JOIN uom_id_code b ON a.upc_code = b.UPC
        WHERE   ISNULL(a.part_no, '') = '';

        IF @debug = 1
            SELECT  *
            FROM    #cvo_inv_adj
            ORDER BY part_no;

        IF EXISTS ( SELECT  1
                    FROM    #cvo_inv_adj
                    WHERE   part_no = '' )
            BEGIN

                INSERT  INTO #adm_inv_adj_log
                        ( loc ,
                          part_no ,
                          qty ,
                          direction ,
                          who_entered ,
                          code ,
                          err_msg ,
                          row_id
                        )
                        SELECT 	DISTINCT
                                @loc ,
                                upc_code ,
                                0 ,
                                @direction ,
                                'Error' ,
                                @code ,
                                'Invalid part number or upc code' ,
                                -99
                        FROM    #cvo_inv_adj
                        WHERE   part_no = '';

                DELETE  FROM cvo_upc_upload
                WHERE   upc_code IN ( SELECT DISTINCT
                                                upc_code
                                      FROM      #cvo_inv_adj
                                      WHERE     part_no = '' );

                DELETE  FROM #cvo_inv_adj
                WHERE   part_no = '';
		-- RETURN
            END;

	-- Start processing transactions

        SET @last_row_id = 0; -- start at zero and avoid any errors already logged.

        SELECT TOP 1
                @row_id = row_id ,
                @location = location ,
                @part_no = part_no ,
                @bin_no = bin_no ,
                @qty_to_adj = qty
        FROM    #cvo_inv_adj
        WHERE   row_id > @last_row_id
        ORDER BY row_id ASC;

        WHILE ( @@ROWCOUNT <> 0 )
            BEGIN

                TRUNCATE TABLE #adm_inv_adj;

                IF @direction = -1
                    BEGIN
                        SELECT  @bin_qty = 0;
                        SELECT  @bin_qty = SUM(ISNULL(qty, 0))
                        FROM    lot_bin_stock
                        WHERE   location = @loc
                                AND bin_no = @bin
                                AND part_no = @part_no;
			
                        IF @qty_to_adj > ISNULL(@bin_qty, 0)
                            INSERT  INTO #adm_inv_adj_log
                                    ( adj_no ,
                                      loc ,
                                      part_no ,
                                      bin_no ,
                                      lot_ser ,
                                      date_exp ,
                                      qty ,
                                      direction ,
                                      who_entered ,
                                      reason_code ,
                                      code ,
                                      cost_flag ,
                                      avg_cost ,
                                      direct_dolrs ,
                                      ovhd_dolrs ,
                                      util_dolrs ,
                                      err_msg ,
                                      row_id
				                    )
                            VALUES  ( -1 , -- adj_no - int
                                      @location , -- loc - varchar(10)
                                      @part_no , -- part_no - varchar(30)
                                      @bin_no , -- bin_no - varchar(12)
                                      '1' , -- lot_ser - varchar(25)
                                      GETDATE() , -- date_exp - datetime
                                      @qty_to_adj , -- qty - decimal
                                      @direction , -- direction - int
                                      'Inv Adj' , -- who_entered - varchar(50)
                                      '' , -- reason_code - varchar(10)
                                      '' , -- code - varchar(8)
                                      '' , -- cost_flag - char(1)
                                      NULL , -- avg_cost - decimal
                                      NULL , -- direct_dolrs - decimal
                                      NULL , -- ovhd_dolrs - decimal
                                      NULL , -- util_dolrs - decimal
                                      'Not enough qty in bin. Only have '
                                      + CAST(ISNULL(@bin_qty, 0) AS VARCHAR(20)) , -- err_msg - varchar(255)
                                      0  -- row_id - int
				                    );
                        SELECT  @qty_to_adj = ISNULL(@bin_qty, 0);
                    END;

                IF @qty_to_adj > 0 AND @direction IN (1,-1)
                    BEGIN
                        INSERT  INTO #adm_inv_adj
                                ( loc ,
                                  part_no ,
                                  bin_no ,
                                  lot_ser ,
                                  date_exp ,
                                  qty ,
                                  direction ,
                                  who_entered ,
                                  reason_code ,
                                  code
                                )
                        VALUES  ( @location ,
                                  @part_no ,
                                  @bin_no ,
                                  '1' ,
                                  GETDATE() + 365 ,
                                  @qty_to_adj ,
                                  @direction ,
                                  'Inv Adj' ,
                                  @reason_code ,
                                  @code
                                );

			-- SELECT * FROM #adm_inv_adj

                        IF @debug = 0
                            EXEC dbo.tdc_adm_inv_adj; 

                        INSERT  INTO #adm_inv_adj_log
                                SELECT  *
                                FROM    #adm_inv_adj;
                    END;

                SET @last_row_id = @row_id;

                SELECT TOP 1
                        @row_id = row_id ,
                        @location = location ,
                        @part_no = part_no ,
                        @bin_no = bin_no ,
                        @qty_to_adj = qty
                FROM    #cvo_inv_adj
                WHERE   row_id > @last_row_id
                ORDER BY row_id ASC;

            END;

        SELECT  adj_no ,
                loc ,
                part_no ,
                bin_no ,
                lot_ser ,
                date_exp ,
                qty ,
                direction ,
                who_entered ,
                reason_code ,
                code ,
                cost_flag ,
                avg_cost ,
                direct_dolrs ,
                ovhd_dolrs ,
                util_dolrs ,
                err_msg ,
                row_id
        FROM    #adm_inv_adj_log;
	
        IF ( SELECT OBJECT_ID('tempdb..#adm_inv_adj')
           ) IS NOT NULL
            BEGIN   
                DROP TABLE #adm_inv_adj;  
            END;
	
        IF ( SELECT OBJECT_ID('tempdb..#adm_inv_adj_log')
           ) IS NOT NULL
            BEGIN   
                DROP TABLE #adm_inv_adj_log;
            END;	

	-- IF (SELECT COUNT(*) FROM cvo_upc_upload) > 0 AND @debug = 0 TRUNCATE TABLE CVO_UPC_UPLOAD

    END;






GO
GRANT EXECUTE ON  [dbo].[cvo_upc_upload_sp] TO [public]
GO
