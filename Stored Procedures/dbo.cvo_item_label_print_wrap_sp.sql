SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_item_label_print_wrap_sp]

    @part_no_1 VARCHAR(30) = NULL ,
    @upc_code_1 VARCHAR(30) = NULL ,
    @part_no_2 VARCHAR(30) = NULL ,
    @upc_code_2 VARCHAR(30) = NULL ,
    @part_no_3 VARCHAR(30) = NULL ,
    @upc_code_3 VARCHAR(30) = NULL ,
    @printer_id_param INT = NULL

AS 

-- EXEC dbo.cvo_item_label_print_wrap_sp 'ASACCLBLA5717',null,'ASACCLGRE5717',null,'ASACCLSMO5717',null,23

    BEGIN

        SET NOCOUNT ON;

        IF @part_no_1 IS NOT NULL
            OR @upc_code_1 IS NOT NULL
            BEGIN
                SELECT  @part_no_1 = part_no ,
                        @upc_code_1 = upc_code
                FROM    inv_master
                WHERE   part_no = @part_no_1
                        OR upc_code = @upc_code_1;
            END;

        IF @part_no_2 IS NOT NULL
            OR @upc_code_2 IS NOT NULL
            BEGIN
                SELECT  @part_no_2 = part_no ,
                        @upc_code_2 = upc_code
                FROM    inv_master
                WHERE   part_no = @part_no_2
                        OR upc_code = @upc_code_2;
            END;
        
        IF @part_no_3 IS NOT NULL
            OR @upc_code_3 IS NOT NULL
            BEGIN
                SELECT  @part_no_3 = part_no ,
                        @upc_code_3 = upc_code
                FROM    inv_master
                WHERE   part_no = @part_no_3
                        OR upc_code = @upc_code_3;
            END;


        IF ( OBJECT_ID('tempdb..#PrintDataDetail') IS NOT NULL )
            DROP TABLE #PrintDataDetail;

		-- WORKING TABLES
        CREATE TABLE #PrintDataDetail
            (
              part_no VARCHAR(30) ,
              part_desc VARCHAR(255) ,
              upc_code VARCHAR(20) ,
              cvo VARCHAR(30) ,
              print_model VARCHAR(100) ,
              print_color VARCHAR(100) ,
              print_size VARCHAR(255)
            );

        INSERT  #PrintDataDetail
                EXECUTE cvo_item_label_print_sp @part_no_1, @upc_code_1, 1,
                    @part_no_2, @upc_code_2, 1, @part_no_3, @upc_code_3, 1;

        ALTER TABLE #PrintDataDetail ADD row_id INT IDENTITY(1,1);

        -- SELECT  * FROM    #PrintDataDetail AS pdd;


        DECLARE @no_rows INT ,
            @detail_lines INT ,
            @i INT ,
            @totPage INT ,
            @sql VARCHAR(200) ,
            @printer_id INT ,
            @number_of_copies INT ,
            @format_id VARCHAR(60);

        DECLARE @FORMAT VARCHAR(60) ,
            @PRINTERNUMBER VARCHAR(40) ,
            @QUANTITY VARCHAR(40) ,
            @DUPLICATES VARCHAR(40) ,
            @PRINTLABEL VARCHAR(40);

        DECLARE @row_id INT ,
            @data_field VARCHAR(300) ,
            @data_value VARCHAR(300);


        IF ( OBJECT_ID('tempdb..#PrintData') IS NOT NULL )
            DROP TABLE #PrintData;     
        
        CREATE TABLE #PrintData
            (
              row_id INT IDENTITY(1, 1) ,
              data_field VARCHAR(300) NOT NULL ,
              data_value VARCHAR(300) NULL
            );
  
        DELETE  FROM CVO_tdc_print_ticket
        WHERE   process_id = @@spid; -- v1.1
		
        SELECT  @format_id = ISNULL(format_id, '')
        FROM    tdc_label_format_control (NOLOCK)
        WHERE   module = 'ADH'
                AND trans = 'ITEMLBLPNT'
                AND trans_source = 'VB';

        SELECT  @printer_id = CASE WHEN @printer_id_param IS NOT NULL
                                   THEN @printer_id_param
                                   ELSE ISNULL(printer, 0)
                              END ,
                @number_of_copies = ISNULL(quantity, 0)
        FROM    tdc_tx_print_routing (NOLOCK)
        WHERE   module = 'ADH'
                AND trans = 'ITEMLBLPNT'
                AND trans_source = 'VB'
                AND format_id = @format_id;

		-- populate printdata

        SELECT  @row_id = MIN(row_id)
        FROM    #PrintDataDetail;	

        WHILE @row_id IS NOT NULL
            BEGIN
                INSERT  INTO #PrintData
                        ( data_field ,
                          data_value
                        )
                        SELECT  'LP_ITEM_1' ,
                                part_no
                        FROM    #PrintDataDetail
                        WHERE   row_id = @row_id;
                INSERT  INTO #PrintData
                        ( data_field ,
                          data_value
                        )
                        SELECT  'LP_DESC_1' ,
                                part_desc
                        FROM    #PrintDataDetail
                        WHERE   row_id = @row_id;
                INSERT  INTO #PrintData
                        ( data_field ,
                          data_value
                        )
                        SELECT  'LP_UPC_1' ,
                                upc_code
                        FROM    #PrintDataDetail
                        WHERE   row_id = @row_id;
                INSERT  INTO #PrintData
                        ( data_field ,
                          data_value
                        )
                        SELECT  'LP_CLEARVISION_1' ,
                                cvo
                        FROM    #PrintDataDetail
                        WHERE   row_id = @row_id;
                INSERT  INTO #PrintData
                        ( data_field ,
                          data_value
                        )
                        SELECT  'LP_FRAME_MODEL_1' ,
                                print_model
                        FROM    #PrintDataDetail
                        WHERE   row_id = @row_id;
                INSERT  INTO #PrintData
                        ( data_field ,
                          data_value
                        )
                        SELECT  'LP_FRAME_COLOR_1' ,
                                print_color
                        FROM    #PrintDataDetail
                        WHERE   row_id = @row_id;
                INSERT  INTO #PrintData
                        ( data_field ,
                          data_value
                        )
                        SELECT  'LP_FRAME_SIZE_1' ,
                                print_size
                        FROM    #PrintDataDetail
                        WHERE   row_id = @row_id;

                INSERT  INTO #PrintData
                        ( data_field ,
                          data_value
                        )
                        SELECT  'LP_ITEM_2' ,
                                part_no
                        FROM    #PrintDataDetail
                        WHERE   row_id = @row_id + 1;
                INSERT  INTO #PrintData
                        ( data_field ,
                          data_value
                        )
                        SELECT  'LP_DESC_2' ,
                                part_desc
                        FROM    #PrintDataDetail
                        WHERE   row_id = @row_id + 1;
                INSERT  INTO #PrintData
                        ( data_field ,
                          data_value
                        )
                        SELECT  'LP_UPC_2' ,
                                upc_code
                        FROM    #PrintDataDetail
                        WHERE   row_id = @row_id + 1;
                INSERT  INTO #PrintData
                        ( data_field ,
                          data_value
                        )
                        SELECT  'LP_CLEARVISION_2' ,
                                cvo
                        FROM    #PrintDataDetail
                        WHERE   row_id = @row_id + 1;
                INSERT  INTO #PrintData
                        ( data_field ,
                          data_value
                        )
                        SELECT  'LP_FRAME_MODEL_2' ,
                                print_model
                        FROM    #PrintDataDetail
                        WHERE   row_id = @row_id + 1;
                INSERT  INTO #PrintData
                        ( data_field ,
                          data_value
                        )
                        SELECT  'LP_FRAME_COLOR_2' ,
                                print_color
                        FROM    #PrintDataDetail
                        WHERE   row_id = @row_id + 1;
                INSERT  INTO #PrintData
                        ( data_field ,
                          data_value
                        )
                        SELECT  'LP_FRAME_SIZE_2' ,
                                print_size
                        FROM    #PrintDataDetail
                        WHERE   row_id = @row_id + 1;

                INSERT  INTO #PrintData
                        ( data_field ,
                          data_value
                        )
                        SELECT  'LP_ITEM_3' ,
                                part_no
                        FROM    #PrintDataDetail
                        WHERE   row_id = @row_id + 2;
                INSERT  INTO #PrintData
                        ( data_field ,
                          data_value
                        )
                        SELECT  'LP_DESC_3' ,
                                part_desc
                        FROM    #PrintDataDetail
                        WHERE   row_id = @row_id + 2;
                INSERT  INTO #PrintData
                        ( data_field ,
                          data_value
                        )
                        SELECT  'LP_UPC_3' ,
                                upc_code
                        FROM    #PrintDataDetail
                        WHERE   row_id = @row_id + 2;
                INSERT  INTO #PrintData
                        ( data_field ,
                          data_value
                        )
                        SELECT  'LP_CLEARVISION_3' ,
                                cvo
                        FROM    #PrintDataDetail
                        WHERE   row_id = @row_id + 2;
                INSERT  INTO #PrintData
                        ( data_field ,
                          data_value
                        )
                        SELECT  'LP_FRAME_MODEL_3' ,
                                print_model
                        FROM    #PrintDataDetail
                        WHERE   row_id = @row_id + 2;
                INSERT  INTO #PrintData
                        ( data_field ,
                          data_value
                        )
                        SELECT  'LP_FRAME_COLOR_3' ,
                                print_color
                        FROM    #PrintDataDetail
                        WHERE   row_id = @row_id + 2;
                INSERT  INTO #PrintData
                        ( data_field ,
                          data_value
                        )
                        SELECT  'LP_FRAME_SIZE_3' ,
                                print_size
                        FROM    #PrintDataDetail
                        WHERE   row_id = @row_id + 2;
	
                SELECT  @row_id = MIN(row_id)
                FROM    #PrintDataDetail
                WHERE   row_id > @row_id + 2;
            END;
    
	-- SELECT * FROM #PrintData AS pd
		--get total lines to print
        SELECT  @no_rows = COUNT(*)
        FROM    #PrintData; 
	-- SELECT @no_rows


        IF @no_rows > 0
            BEGIN 
                SET @detail_lines = 21; -- 7 lines per item
                SET @FORMAT = '*FORMAT,' + @format_id;
	
                IF ( @no_rows % @detail_lines ) > 0
                    SET @totPage = ( @no_rows / @detail_lines ) + 1;
                ELSE
                    SET @totPage = @no_rows / @detail_lines;    

		-- SELECT @totPage

                SELECT  @PRINTERNUMBER = '*PRINTERNUMBER,'
                        + CAST(@printer_id AS CHAR(2)) ,
                        @QUANTITY = '*QUANTITY,1' ,
                        @DUPLICATES = '*DUPLICATES,'
                        + CAST(ABS(@number_of_copies) AS CHAR(2)) ,
                        @PRINTLABEL = '*PRINTLABEL';
	
                SET @i = 1;
                WHILE ( @i <= @totPage )
                    AND EXISTS ( SELECT *
                                 FROM   #PrintData )
                    BEGIN

			/******************************************************************** HEADER ********************************************************************/
                        INSERT  INTO CVO_tdc_print_ticket
                                ( print_value, process_id )
                        VALUES  ( @FORMAT, @@SPID ); -- v1.1
			
			/********************************************************************  BODY ********************************************************************/

                        INSERT  INTO dbo.CVO_tdc_print_ticket
                                ( print_value ,
                                  process_id
                                )
                                SELECT TOP ( @detail_lines )
                                        ISNULL(data_field, '') + ','
                                        + ISNULL(data_value, '') ,
                                        @@spid
                                FROM    #PrintData;

                        DELETE  #PrintData
                        FROM    ( SELECT TOP ( @detail_lines )
                                            *
                                  FROM      #PrintData
                                ) AS t1
                        WHERE   #PrintData.row_id = t1.row_id;

				        --SET @sql = 'INSERT INTO CVO_tdc_print_ticket (print_value, process_id) SELECT TOP '
            --                + CAST(@detail_lines AS VARCHAR(2))
            --                + ' ISNULL(data_field,''NULL'') + '','' + ISNULL(data_value,''NULL''), '
            --                + CAST(@@SPID AS VARCHAR(10))
            --                + '  FROM #PrintData '; -- v1.1
            --            EXEC (@sql);	

                        --SET @sql = 'DELETE #PrintData FROM (SELECT TOP '
                        --    + CAST(@detail_lines AS VARCHAR(2))
                        --    + ' * FROM  #PrintData) AS t1  WHERE #PrintData.row_id = t1.row_id ';
                        --EXEC (@sql);				
			
			/******************************************************************** FOOTER ********************************************************************/
                        INSERT  INTO CVO_tdc_print_ticket
                                ( print_value ,
                                  process_id
                                )
                        VALUES  ( 'LP_PAGE_NO, ' + CAST(@i AS VARCHAR(2))
                                  + ' of ' + CAST(@totPage AS VARCHAR(2)) ,
                                  @@SPID
                                ); -- v1.1
                        INSERT  INTO CVO_tdc_print_ticket
                                ( print_value, process_id )
                        VALUES  ( @PRINTERNUMBER, @@SPID ); -- v1.1
                        INSERT  INTO CVO_tdc_print_ticket
                                ( print_value, process_id )
                        VALUES  ( @QUANTITY, @@SPID ); -- v1.1
                        INSERT  INTO CVO_tdc_print_ticket
                                ( print_value, process_id )
                        VALUES  ( @DUPLICATES, @@SPID ); -- v1.1
                        INSERT  INTO CVO_tdc_print_ticket
                                ( print_value, process_id )
                        VALUES  ( @PRINTLABEL, @@SPID ); -- v1.1
			    
                        DECLARE @xp_cmdshell VARCHAR(1000);
                        DECLARE @lwlPath VARCHAR(100);
                        SELECT  @lwlPath = ISNULL(value_str, 'C:\')
                        FROM    dbo.tdc_config
                        WHERE   [function] = 'WDDrop_Directory';

			--Without column name
                        SET @xp_cmdshell = 'SQLCMD -S ' + @@servername
                            + ' -E -Q "SET NOCOUNT ON SELECT print_value FROM '
                            + DB_NAME()
                            + '.dbo.CVO_tdc_print_ticket (NOLOCK) WHERE process_id = '
                            + CAST(@@SPID AS VARCHAR(10))
                            + ' ORDER BY row_id ASC" -s"," -h -1 -W -b -o  "'
                            + @lwlPath + '\SO-' + CAST(NEWID() AS VARCHAR(60))
                            + '.pas"';  -- v1.1 
			
			-- SELECT @xp_cmdshell

                        EXEC master..xp_cmdshell @xp_cmdshell, no_output;
			
                        DELETE  FROM CVO_tdc_print_ticket
                        WHERE   process_id = @@SPID;

                        SET @i = @i + 1;
                    END; -- end while 
            END;   	 					

    END;



	GRANT EXECUTE ON cvo_item_label_print_wrap_sp TO PUBLIC;    
GO
