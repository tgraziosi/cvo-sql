SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_determine_abc_part_classification_sp]
    @upper_percentage DECIMAL(20, 8),
    @lower_percentage DECIMAL(20, 8),
    @location VARCHAR(12),
    @start_date VARCHAR(35),
    @end_date VARCHAR(35),
    @processing_option INT,
    @part_type CHAR(5),
    @part_group VARCHAR(10)

AS
BEGIN

    /*
EXEC dbo.tdc_determine_abc_part_classification_sp @upper_percentage = 80, -- decimal(20, 8)
                                                  @lower_percentage = 50, -- decimal(20, 8)
                                                  @location = '001',           -- varchar(12)
                                                  @start_date = '4/1/2017',         -- varchar(35)
                                                  @end_date = '03/30/2018',           -- varchar(35)
                                                  @processing_option = 2,   -- int
                                                  @part_type = '<ALL>',          -- char(5)
                                                  @part_group = '<ALL>'          -- varchar(10)
*/

    --VARIABLES
    DECLARE @sum_total DECIMAL(20, 8),
            @sum_total_cost DECIMAL(20, 8),
            @part_no VARCHAR(30),           --cursor variable
            @percentage DECIMAL(20, 8),     --cursor variable
            @class_rank CHAR(1),            --cursor variable
            @sum_percentage DECIMAL(20, 8), --summation variable to determine classification
            @total_rows INT,
            @a_count INT,
            @b_count INT,
            @start_date_val DATETIME,
            @end_date_val DATETIME,
            @TYPE_CODE VARCHAR(1000);

    --FOR DEBUGGING PURPOSES:
    -- --INPUTS
    -- DECLARE @upper_percentage	decimal(20,8),
    -- 	@lower_percentage	decimal(20,8),
    -- 	@location		varchar(12),
    -- 	@start_date		varchar(20),
    -- 	@end_date		varchar(20),
    -- 	@processing_option	int,
    -- 	@part_type		char(5),
    -- 	SELECT 	@upper_percentage = 80,
    -- 		@lower_percentage = 45,
    -- 		@location = 'Dallas',
    -- 		@start_date = getdate() -10000, 
    -- 		@end_date = getdate(),
    -- 		@processing_option = 0,
    -- 		@part_type = '<ALL>'

    IF (OBJECT_ID('tempdb.dbo.#INV_CLASS_PARTS')) IS NULL
        CREATE TABLE #INV_CLASS_PARTS
        (
            PART_NO VARCHAR(30),
            percentage NUMERIC,
            old_rank CHAR(1),
            new_rank CHAR(1),
            rowid INT IDENTITY(1, 1)
        );

    IF (OBJECT_ID('tempdb.dbo.#INV_CLASS_TEMP_PARTS')) IS NULL
        CREATE TABLE #INV_CLASS_temp_PARTS
        (
            PART_NO VARCHAR(30),
            percentage NUMERIC,
            old_rank CHAR(1),
            new_rank CHAR(1),
            rowid INT IDENTITY(1, 1),
            sel_flg INT NULL
        );

    TRUNCATE TABLE #INV_CLASS_PARTS;

    TRUNCATE TABLE #INV_CLASS_temp_PARTS;


    --@processing_option = 0
    --Quantity on Hand
    IF @processing_option = 0
    BEGIN
        SELECT @sum_total = SUM(b.qty)
        FROM inv_list a (NOLOCK),
             lot_bin_stock b (NOLOCK),
             inv_master c (NOLOCK)
        WHERE a.location = @location
              AND a.part_no = b.part_no
              AND a.location = b.location
              AND a.status = (CASE
                                  WHEN @part_type = '<ALL>' THEN
                                      a.status
                                  ELSE
                                      @part_type
                              END
                             )
              AND a.status IN ( 'H', 'M', 'P', 'Q' )
              AND a.part_no = c.part_no
              AND c.category = (CASE
                                    WHEN @part_group = '<ALL>' THEN
                                        c.category
                                    ELSE
                                        @part_group
                                END
                               )
              AND c.type_code IN ( 'FRAME', 'SUN', 'POP' );

        INSERT INTO #INV_CLASS_PARTS
        (
            PART_NO,
            percentage,
            old_rank,
            new_rank
        )
        SELECT a.part_no,
               CASE
                   WHEN @sum_total <> 0 THEN
               (SUM(b.qty) / @sum_total) * 100
                   ELSE
                       0
               END,
               a.rank_class old_rank_class,
               ''
        FROM inv_list a (NOLOCK),
             lot_bin_stock b (NOLOCK),
             inv_master c (NOLOCK)
        WHERE a.location = @location
              AND a.part_no = b.part_no
              AND a.location = b.location
              AND a.status = (CASE
                                  WHEN @part_type = '<ALL>' THEN
                                      a.status
                                  ELSE
                                      @part_type
                              END
                             )
              AND a.status IN ( 'H', 'M', 'P', 'Q' )
              AND a.part_no = c.part_no
              AND c.category = (CASE
                                    WHEN @part_group = '<ALL>' THEN
                                        c.category
                                    ELSE
                                        @part_group
                                END
                               )
              AND c.type_code IN ( 'FRAME', 'SUN', 'POP' )
        GROUP BY a.part_no,
                 a.rank_class
        ORDER BY 2 DESC;
    END;

    --@processing_option = 1
    --Quantity on Hand * Unit Cost
    IF @processing_option = 1
    BEGIN
        SELECT @sum_total = SUM(b.qty * a.std_cost)
        FROM inv_list a (NOLOCK),
             lot_bin_stock b (NOLOCK),
             inv_master c (NOLOCK)
        WHERE a.location = @location
              AND a.part_no = b.part_no
              AND a.location = b.location
              AND a.status = (CASE
                                  WHEN @part_type = '<ALL>' THEN
                                      a.status
                                  ELSE
                                      @part_type
                              END
                             )
              AND a.status IN ( 'H', 'M', 'P', 'Q' )
              AND a.part_no = c.part_no
              AND c.category = (CASE
                                    WHEN @part_group = '<ALL>' THEN
                                        c.category
                                    ELSE
                                        @part_group
                                END
                               )
              AND c.type_code IN ( 'FRAME', 'SUN', 'POP' );

        INSERT INTO #INV_CLASS_PARTS
        (
            PART_NO,
            percentage,
            old_rank,
            new_rank
        )
        SELECT a.part_no,
               CASE
                   WHEN @sum_total <> 0 THEN
               (SUM(a.qty * b.std_cost) / @sum_total) * 100
                   ELSE
                       0
               END,
               b.rank_class,
               ''
        FROM lot_bin_stock a (NOLOCK),
             inv_list b (NOLOCK),
             inv_master c (NOLOCK)
        WHERE a.location = @location
              AND a.part_no = b.part_no
              AND a.location = b.location
              AND b.status = (CASE
                                  WHEN @part_type = '<ALL>' THEN
                                      b.status
                                  ELSE
                                      @part_type
                              END
                             )
              AND b.status IN ( 'H', 'M', 'P', 'Q' )
              AND a.part_no = c.part_no
              AND c.category = (CASE
                                    WHEN @part_group = '<ALL>' THEN
                                        c.category
                                    ELSE
                                        @part_group
                                END
                               )
              AND c.type_code IN ( 'FRAME', 'SUN', 'POP' )
        GROUP BY a.part_no,
                 b.rank_class
        ORDER BY 2 DESC;
    END;

    --@processing_option = 2
    --Number of Picks - Qty Picked Percentage
    IF @processing_option = 2
    BEGIN
        SELECT @sum_total = SUM(c.qty)
        FROM inv_list a (NOLOCK)
            JOIN lot_bin_ship c (NOLOCK) ON c.part_no = a.part_no AND c.location = a.location
            JOIN inv_master d (NOLOCK)   ON d.part_no = a.part_no
        WHERE 1 = 1
              AND a.location = @location
              AND c.date_tran  BETWEEN @start_date AND @end_date
              AND a.status = (CASE
                                  WHEN @part_type = '<ALL>' THEN
                                      a.status
                                  ELSE
                                      @part_type
                              END
                             )
              AND a.status IN ( 'H', 'M', 'P', 'Q' )
              AND d.category = (CASE
                                    WHEN @part_group = '<ALL>' THEN
                                        d.category
                                    ELSE
                                        @part_group
                                END
                               )
              AND d.type_code IN ( 'FRAME', 'SUN', 'POP' );

        INSERT INTO #INV_CLASS_PARTS
        (
            PART_NO,
            percentage,
            old_rank,
            new_rank
        )
        SELECT a.part_no,
               CASE
                   WHEN @sum_total <> 0 THEN
               (SUM(c.qty) / @sum_total) * 100
                   ELSE
                       0
               END,
               a.rank_class,
               ''
        FROM inv_list a (NOLOCK)
            JOIN lot_bin_ship c (NOLOCK)
                ON c.part_no = a.part_no
                   AND c.location = a.location
            JOIN inv_master d (NOLOCK)
                ON d.part_no = a.part_no
        WHERE 1 = 1
              AND a.location = @location
              AND c.date_tran
              BETWEEN @start_date AND @end_date
              AND a.status = (CASE
                                  WHEN @part_type = '<ALL>' THEN
                                      a.status
                                  ELSE
                                      @part_type
                              END
                             )
              AND a.status IN ( 'H', 'M', 'P', 'Q' )
              AND d.category = (CASE
                                    WHEN @part_group = '<ALL>' THEN
                                        d.category
                                    ELSE
                                        @part_group
                                END
                               )
              AND d.type_code IN ( 'FRAME', 'SUN', 'POP' )
        GROUP BY a.part_no,
                 a.rank_class
        ORDER BY 2 DESC;
    END;

    --@processing_option = 3
    --Number of Picks - Number of transactions
    IF @processing_option = 3
    BEGIN
        SELECT @sum_total = COUNT(*) -- Number of transactions total based on the date ranges
        FROM inv_list a (NOLOCK)
            JOIN lot_bin_ship c (NOLOCK)
                ON c.part_no = a.part_no
                   AND c.location = a.location
            JOIN inv_master d (NOLOCK)
                ON d.part_no = a.part_no
        WHERE 1 = 1
              AND a.location = @location
              AND c.date_tran
              BETWEEN @start_date AND @end_date
              AND a.status = (CASE
                                  WHEN @part_type = '<ALL>' THEN
                                      a.status
                                  ELSE
                                      @part_type
                              END
                             )
              AND a.status IN ( 'H', 'M', 'P', 'Q' )
              AND d.category = (CASE
                                    WHEN @part_group = '<ALL>' THEN
                                        d.category
                                    ELSE
                                        @part_group
                                END
                               )
              AND d.type_code IN ( 'FRAME', 'SUN', 'POP' );


        INSERT INTO #INV_CLASS_PARTS
        (
            PART_NO,
            percentage,
            old_rank,
            new_rank
        )
        SELECT a.part_no,
               CASE
                   WHEN @sum_total <> 0 THEN
               (COUNT(c.part_no) / @sum_total) * 100
                   ELSE
                       0
               END,
               a.rank_class,
               ''
        FROM inv_list a (NOLOCK)
            JOIN lot_bin_ship c (NOLOCK)
                ON c.part_no = a.part_no
                   AND c.location = a.location
            JOIN inv_master d (NOLOCK)
                ON d.part_no = a.part_no
        WHERE 1 = 1
              AND a.location = @location
              AND c.date_tran
              BETWEEN @start_date AND @end_date
              AND a.status = (CASE
                                  WHEN @part_type = '<ALL>' THEN
                                      a.status
                                  ELSE
                                      @part_type
                              END
                             )
              AND a.status IN ( 'H', 'M', 'P', 'Q' )
              AND d.category = (CASE
                                    WHEN @part_group = '<ALL>' THEN
                                        d.category
                                    ELSE
                                        @part_group
                                END
                               )
              AND d.type_code IN ( 'FRAME', 'SUN', 'POP' )
        GROUP BY a.part_no,
                 a.rank_class
        ORDER BY 2 DESC;
    END;

    --@processing_option = 4
    --Order Demand
    IF @processing_option = 4
    BEGIN

        SELECT @start_date_val = CONVERT(DATETIME, @start_date);

        SELECT @end_date_val = CONVERT(DATETIME, @end_date);

        SELECT @sum_total = ISNULL(SUM(b.ordered), 0)
        FROM orders a (NOLOCK),
             ord_list b (NOLOCK),
             inv_master c (NOLOCK),
             inv_list d (NOLOCK)
        WHERE a.status < 'R'
              AND a.order_no = b.order_no
              AND a.ext = b.order_ext
              AND b.part_no = c.part_no
              AND b.location = @location
              AND b.part_type <> 'M'
              AND d.part_no = b.part_no
              AND d.location = b.location
              AND d.status = (CASE
                                  WHEN @part_type = '<ALL>' THEN
                                      d.status
                                  ELSE
                                      @part_type
                              END
                             )
              AND d.status IN ( 'H', 'M', 'P', 'Q' )
              AND CONVERT(VARCHAR(20), a.sch_ship_date, 101)
              BETWEEN CONVERT(VARCHAR(20), @start_date_val, 101) AND CONVERT(VARCHAR(20), @end_date_val, 101)
              AND c.category = (CASE
                                    WHEN @part_group = '<ALL>' THEN
                                        c.category
                                    ELSE
                                        @part_group
                                END
                               )
              AND c.type_code IN ( 'FRAME', 'SUN', 'POP' );

        -- sp_help orders
        -- sch_ship_date

        INSERT INTO #INV_CLASS_PARTS
        (
            PART_NO,
            percentage,
            old_rank,
            new_rank
        )
        SELECT b.part_no,
               CASE
                   WHEN @sum_total <> 0 THEN
               (SUM(b.ordered) / @sum_total) * 100
                   ELSE
                       0
               END,
               d.rank_class,
               ''
        FROM orders a (NOLOCK),
             ord_list b (NOLOCK),
             inv_master c (NOLOCK),
             inv_list d (NOLOCK)
        WHERE a.status < 'R'
              AND a.order_no = b.order_no
              AND a.ext = b.order_ext
              AND b.part_no = c.part_no
              AND b.location = @location
              AND b.part_type <> 'M'
              AND d.part_no = b.part_no
              AND d.location = b.location
              AND d.status = (CASE
                                  WHEN @part_type = '<ALL>' THEN
                                      d.status
                                  ELSE
                                      @part_type
                              END
                             )
              AND d.status IN ( 'H', 'M', 'P', 'Q' )
              AND CONVERT(VARCHAR(20), a.sch_ship_date, 101)
              BETWEEN CONVERT(VARCHAR(20), @start_date_val, 101) AND CONVERT(VARCHAR(20), @end_date_val, 101)
              AND c.category = (CASE
                                    WHEN @part_group = '<ALL>' THEN
                                        c.category
                                    ELSE
                                        @part_group
                                END
                               )
              AND c.type_code IN ( 'FRAME', 'SUN', 'POP' )
        GROUP BY b.part_no,
                 d.rank_class
        ORDER BY 2 DESC;
    END;

    SELECT @total_rows = MAX(rowid)
    FROM #INV_CLASS_PARTS;

    --We will ALWAYS have at least 1 "A" part
    --Assign A parts
    SELECT @a_count = @total_rows * ((100 - @upper_percentage) / 100);

    IF @a_count = 0
        SELECT @a_count = 1;

    INSERT INTO #INV_CLASS_temp_PARTS
    (
        PART_NO,
        old_rank,
        percentage,
        new_rank
    )
    SELECT PART_NO,
           old_rank,
           percentage,
           'A'
    FROM #INV_CLASS_PARTS
    WHERE rowid <= @a_count;

    DELETE FROM #INV_CLASS_PARTS
    WHERE rowid <= @a_count;

    --Assign B parts
    SELECT @b_count = @total_rows * ((@upper_percentage - @lower_percentage) / 100);

    IF @b_count = 0
    BEGIN --WE make sure that we assign a "B" part in this case, so we don't have an "A" part and "C" part with no "B" parts
        IF (@total_rows - @a_count) > 0
        BEGIN
            SELECT @b_count = 1;
        END;
    END;

    INSERT INTO #INV_CLASS_temp_PARTS
    (
        PART_NO,
        old_rank,
        percentage,
        new_rank
    )
    SELECT PART_NO,
           old_rank,
           percentage,
           'B'
    FROM #INV_CLASS_PARTS
    WHERE rowid <= @a_count + @b_count;

    DELETE FROM #INV_CLASS_PARTS
    WHERE rowid <= @a_count + @b_count;

    --Assign C parts
    INSERT INTO #INV_CLASS_temp_PARTS
    (
        PART_NO,
        old_rank,
        percentage,
        new_rank
    )
    SELECT PART_NO,
           old_rank,
           percentage,
           'C'
    FROM #INV_CLASS_PARTS;


END;

GO
GRANT EXECUTE ON  [dbo].[tdc_determine_abc_part_classification_sp] TO [public]
GO
